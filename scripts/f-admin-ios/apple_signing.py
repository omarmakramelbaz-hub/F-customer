"""Use the existing publisher credentials without logging or exporting secrets."""

import argparse
import base64
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import plistlib
import time
import urllib.error
import urllib.parse
import urllib.request

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
from cryptography.hazmat.primitives.serialization.pkcs12 import load_key_and_certificates
from cryptography.x509.oid import NameOID


TEAM = "4769DGYGT3"
BUNDLE = "com.smartvision.fasakhninga.dashboard"
APP_ID = "6741510478"
ISSUER = "101ba01e-cd36-41de-994a-12da94a7cfff"
KEY_ID = "SA28WVY65G"
API = "https://api.appstoreconnect.apple.com"


def required(name):
    value = os.environ.get(name, "")
    if not value:
        raise RuntimeError(f"Existing release secret is unavailable: {name}")
    return value


def b64url(value):
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def decoded_secret(name):
    return base64.b64decode("".join(required(name).split()), validate=True)


def make_token():
    if required("APP_STORE_CONNECT_KEY_ID") != KEY_ID:
        raise RuntimeError("Publisher key does not match the verified existing Apple key")
    if required("APP_STORE_CONNECT_ISSUER_ID") != ISSUER:
        raise RuntimeError("Publisher issuer does not match the verified Apple team")
    private_key = serialization.load_pem_private_key(
        decoded_secret("APP_STORE_CONNECT_API_KEY_BASE64"),
        password=None,
    )
    if not isinstance(private_key, ec.EllipticCurvePrivateKey) or not isinstance(
        private_key.curve, ec.SECP256R1
    ):
        raise RuntimeError("Apple API key must be an ES256 key")
    now = int(time.time())
    header = b64url(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode())
    payload = b64url(
        json.dumps({"iss": ISSUER, "iat": now - 30, "exp": now + 600,
                    "aud": "appstoreconnect-v1"}).encode()
    )
    signing_input = f"{header}.{payload}".encode("ascii")
    signature = private_key.sign(signing_input, ec.ECDSA(hashes.SHA256()))
    r, s = decode_dss_signature(signature)
    return f"{header}.{payload}.{b64url(r.to_bytes(32, 'big') + s.to_bytes(32, 'big'))}"


def request(token, path, payload=None):
    if not path.startswith("/v1/"):
        raise RuntimeError("Unexpected Apple API resource")
    if payload is not None and path != "/v1/profiles":
        raise RuntimeError("Only a dashboard provisioning profile may be created")
    headers = {"Authorization": "Bearer " + token}
    data = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(payload).encode()
    req = urllib.request.Request(API + path, headers=headers, data=data)
    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, *args, **kwargs):
            return None

    try:
        with urllib.request.build_opener(NoRedirect()).open(req, timeout=60) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        # Never print request headers, credentials, or a raw HTTP response.
        raise RuntimeError(f"Apple denied the {path.split('?')[0]} check: HTTP {error.code}") from None


def validated_profile(content, certificate_fingerprint):
    """Validate decoded profile identity before it can reach the signing tools."""
    if content.get("TeamIdentifier") != [TEAM]:
        raise RuntimeError("Provisioning profile belongs to a different Apple team")
    entitlements = content.get("Entitlements", {})
    if entitlements.get("application-identifier") != TEAM + "." + BUNDLE:
        raise RuntimeError("Provisioning profile belongs to a different application")
    if entitlements.get("com.apple.developer.team-identifier") != TEAM:
        raise RuntimeError("Provisioning profile has an unexpected signing team entitlement")
    if entitlements.get("get-task-allow", False) or content.get("ProvisionedDevices") or content.get("ProvisionsAllDevices"):
        raise RuntimeError("An App Store distribution profile is required")
    expiration = content.get("ExpirationDate")
    if expiration is None or expiration.replace(tzinfo=dt.timezone.utc) <= dt.datetime.now(dt.timezone.utc):
        raise RuntimeError("Provisioning profile has expired")
    if certificate_fingerprint not in [hashlib.sha256(cert).digest() for cert in content.get("DeveloperCertificates", [])]:
        raise RuntimeError("Provisioning profile does not include the existing signing certificate")
    for field in ("Name", "UUID"):
        if not content.get(field) or any(char in content[field] for char in "\r\n"):
            raise RuntimeError("Provisioning profile metadata is invalid")


def private_file(path, content):
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as output:
        output.write(content)


def preflight(prepare=False):
    certificate_bytes = decoded_secret("IOS_P12_BASE64")
    password = required("IOS_P12_PASSWORD").encode()
    private_key, certificate, _ = load_key_and_certificates(certificate_bytes, password)
    if certificate is None or private_key is None:
        raise RuntimeError("The existing signing package has no public certificate")
    org_units = certificate.subject.get_attributes_for_oid(NameOID.ORGANIZATIONAL_UNIT_NAME)
    if not any(unit.value == TEAM for unit in org_units):
        raise RuntimeError("The existing signing certificate belongs to a different team")
    if certificate.not_valid_after_utc <= dt.datetime.now(dt.timezone.utc):
        raise RuntimeError("The existing Apple signing certificate has expired")
    fingerprint = certificate.fingerprint(hashes.SHA256())
    token = make_token()
    app = request(token, "/v1/apps/" + APP_ID)["data"]
    if app["attributes"]["bundleId"] != BUNDLE:
        raise RuntimeError("App Store record does not match the existing dashboard bundle")
    query = urllib.parse.urlencode({"filter[identifier]": BUNDLE, "limit": 2})
    bundles = request(token, "/v1/bundleIds?" + query)["data"]
    if len(bundles) != 1 or bundles[0]["attributes"]["identifier"] != BUNDLE:
        raise RuntimeError("The exact dashboard bundle registration is unavailable")
    certificates = request(token, "/v1/certificates?limit=200")["data"]
    matching = [item for item in certificates if hashlib.sha256(base64.b64decode(
        item["attributes"]["certificateContent"])).digest() == fingerprint]
    if len(matching) != 1:
        raise RuntimeError("Cannot match the existing signing certificate to the Apple team")
    if matching[0]["attributes"]["certificateType"] not in ("DISTRIBUTION", "IOS_DISTRIBUTION"):
        raise RuntimeError("The existing certificate is not an iOS distribution certificate")
    profiles = request(token, "/v1/profiles?" + urllib.parse.urlencode({
        "filter[profileType]": "IOS_APP_STORE", "include": "bundleId,certificates", "limit": 200
    }))["data"]
    compatible = [profile for profile in profiles
                  if profile["attributes"].get("profileState") == "ACTIVE"
                  and profile["relationships"]["bundleId"]["data"]["id"] == bundles[0]["id"]
                  and matching[0]["id"] in [item["id"] for item in
                      profile["relationships"]["certificates"]["data"]]]
    print("Verified existing publisher key, signing certificate, team and dashboard App Store record.")
    print("Dashboard App Store provisioning profile: " + ("available" if compatible else "required"))
    if not prepare:
        print("Read-only signing preflight finished; no Apple records were changed.")
        return
    if compatible:
        profile = compatible[0]
    else:
        profile = request(token, "/v1/profiles", {"data": {
            "type": "profiles",
            "attributes": {"name": "Fasakhansta Dashboard AppStore 2026", "profileType": "IOS_APP_STORE"},
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundles[0]["id"]}},
                "certificates": {"data": [{"type": "certificates", "id": matching[0]["id"]}]},
            },
        }})["data"]
        print("Created the App Store profile for the existing dashboard bundle and existing certificate.")
    if profile["attributes"].get("profileState") != "ACTIVE":
        raise RuntimeError("The dashboard provisioning profile is not active")
    profile_bytes = base64.b64decode(profile["attributes"]["profileContent"], validate=True)
    import subprocess
    decoded = subprocess.run(["security", "cms", "-D"], input=profile_bytes,
                             capture_output=True, check=True).stdout
    profile_content = plistlib.loads(decoded)
    validated_profile(profile_content, fingerprint)
    signing_dir = Path(required("RUNNER_TEMP")) / "f-admin-signing"
    signing_dir.mkdir(mode=0o700)
    private_file(signing_dir / "distribution.p12", certificate_bytes)
    private_file(signing_dir / "dashboard.mobileprovision", profile_bytes)
    export_options = {
        "destination": "export", "method": "app-store-connect", "signingStyle": "manual",
        "signingCertificate": "Apple Distribution", "teamID": TEAM,
        "manageAppVersionAndBuildNumber": False, "stripSwiftSymbols": True,
        "uploadSymbols": True, "provisioningProfiles": {BUNDLE: profile_content["Name"]},
    }
    private_file(signing_dir / "ExportOptions.plist", plistlib.dumps(export_options))
    with open(required("GITHUB_ENV"), "a", encoding="utf-8") as output:
        output.write("DASHBOARD_PROFILE_NAME=" + profile_content["Name"] + "\n")
        output.write("DASHBOARD_PROFILE_UUID=" + profile_content["UUID"] + "\n")
    print("Prepared signing files in the temporary runner; no private material is included in artifacts.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--prepare", action="store_true")
    args = parser.parse_args()
    try:
        preflight(args.prepare)
    except Exception as exc:
        # Deliberately avoid traceback/local variables containing credentials.
        if isinstance(exc, RuntimeError):
            raise SystemExit(str(exc)) from None
        raise SystemExit("Apple signing preflight failed; no credential values were logged.") from None
