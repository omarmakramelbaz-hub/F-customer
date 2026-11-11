"""Reject an IPA for any app, team, or version other than this approved release."""

import hashlib
from pathlib import Path, PurePosixPath
import plistlib
import subprocess
import zipfile

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.serialization.pkcs12 import load_key_and_certificates

from apple_signing import BUNDLE, TEAM, required, validated_profile


def validate_info(info):
    expected = {"CFBundleIdentifier": BUNDLE, "CFBundleShortVersionString": "1.0.13", "CFBundleVersion": "15"}
    if any(info.get(key) != value for key, value in expected.items()):
        raise RuntimeError("Exported IPA identity or version does not match the dashboard release")
    if not info.get("UIStatusBarHidden") or not info.get("UIViewControllerBasedStatusBarAppearance"):
        raise RuntimeError("Exported IPA is missing the approved full-screen status UI settings")
    sdk = info.get("DTSDKName", "")
    if not sdk.startswith("iphoneos") or int(sdk[8:].split(".")[0]) < 26:
        raise RuntimeError("Exported IPA must use the iOS 26 SDK or later")


def verify():
    paths = list(Path("dashboard/build/ios/ipa").glob("*.ipa"))
    if len(paths) != 1:
        raise RuntimeError("Expected exactly one dashboard IPA")
    ipa = paths[0].resolve()
    with zipfile.ZipFile(ipa) as archive:
        names = archive.namelist()
        if any(PurePosixPath(name).is_absolute() or ".." in PurePosixPath(name).parts for name in names):
            raise RuntimeError("Unsafe IPA archive path")
        info_paths = [name for name in names if name.startswith("Payload/") and name.endswith(".app/Info.plist") and len(PurePosixPath(name).parts) == 3]
        if len(info_paths) != 1 or any(".appex/" in name for name in names):
            raise RuntimeError("Unexpected application or extension inside the dashboard IPA")
        validate_info(plistlib.loads(archive.read(info_paths[0])))
        app_name = PurePosixPath(info_paths[0]).parts[1]
    verification_dir = Path(required("RUNNER_TEMP")) / "f-admin-verified-export"
    verification_dir.mkdir(mode=0o700)
    subprocess.run(["ditto", "-x", "-k", str(ipa), str(verification_dir)], check=True)
    app = verification_dir / "Payload" / app_name
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True, capture_output=True)
    details = subprocess.run(["codesign", "-d", "--verbose=4", str(app)], check=True, capture_output=True).stderr.decode()
    if "TeamIdentifier=" + TEAM not in details or "Authority=Apple Distribution:" not in details:
        raise RuntimeError("Exported IPA does not carry the existing team's distribution signature")
    entitlements = subprocess.run(["codesign", "-d", "--entitlements", ":-", str(app)], check=True, capture_output=True).stdout
    signed_entitlements = plistlib.loads(entitlements)
    if signed_entitlements.get("application-identifier") != TEAM + "." + BUNDLE or signed_entitlements.get("get-task-allow", False):
        raise RuntimeError("Exported IPA has incorrect distribution entitlements")
    profile = subprocess.run(["security", "cms", "-D", "-i", str(app / "embedded.mobileprovision")], check=True, capture_output=True).stdout
    signing_profile = plistlib.loads((Path(required("RUNNER_TEMP")) / "f-admin-signing" / "ExportOptions.plist").read_bytes())
    if signing_profile.get("teamID") != TEAM:
        raise RuntimeError("Unexpected export team")
    # The source distribution certificate remains in the runner; never copy it into an artifact.
    p12_path = Path(required("RUNNER_TEMP")) / "f-admin-signing" / "distribution.p12"
    import_password = (p12_path.parent / "import-password").read_bytes().strip()
    _, certificate, _ = load_key_and_certificates(p12_path.read_bytes(), import_password)
    validated_profile(plistlib.loads(profile), certificate.fingerprint(hashes.SHA256()))
    with open(required("GITHUB_ENV"), "a", encoding="utf-8") as output:
        output.write("IPA_PATH=" + str(ipa) + "\n")
    print("Verified signed dashboard IPA: " + BUNDLE + "; version 1.0.13 (15); existing Apple team; SDK 26+.")
    print("IPA SHA-256: " + hashlib.sha256(ipa.read_bytes()).hexdigest())


if __name__ == "__main__":
    try:
        verify()
    except Exception as exc:
        if isinstance(exc, RuntimeError):
            raise SystemExit(str(exc)) from None
        raise SystemExit("IPA validation failed; no credential values were logged.") from None
