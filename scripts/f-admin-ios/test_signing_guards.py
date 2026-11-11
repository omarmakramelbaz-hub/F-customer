import base64
from copy import deepcopy
import datetime as dt
import hashlib
import json
import os
from unittest import TestCase
from unittest.mock import patch

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import encode_dss_signature
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives.serialization.pkcs12 import load_key_and_certificates

import apple_signing as signing
from verify_export import validate_info


class SigningIdentityGuards(TestCase):
    def setUp(self):
        self.cert = b"synthetic-public-certificate-for-tests"
        self.fingerprint = hashlib.sha256(self.cert).digest()
        self.profile = {
            "Name": "Dashboard Store Test", "UUID": "00000000-0000-0000-0000-000000000001",
            "TeamIdentifier": [signing.TEAM], "DeveloperCertificates": [self.cert],
            "ExpirationDate": dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=30),
            "Entitlements": {"application-identifier": signing.TEAM + "." + signing.BUNDLE,
                             "com.apple.developer.team-identifier": signing.TEAM,
                             "get-task-allow": False},
        }

    def test_store_profile_for_existing_app_is_accepted(self):
        signing.validated_profile(self.profile, self.fingerprint)

    def test_other_app_and_other_team_are_rejected(self):
        for path, value in [("team", ["OTHERTEAM"]), ("bundle", "other.application")]:
            profile = deepcopy(self.profile)
            if path == "team":
                profile["TeamIdentifier"] = value
            else:
                profile["Entitlements"]["application-identifier"] = value
            with self.assertRaises(RuntimeError):
                signing.validated_profile(profile, self.fingerprint)

    def test_development_enterprise_wrong_certificate_and_expiration_are_rejected(self):
        mutations = [
            lambda p: p["Entitlements"].update({"get-task-allow": True}),
            lambda p: p.update({"ProvisionedDevices": ["device"]}),
            lambda p: p.update({"ProvisionsAllDevices": True}),
            lambda p: p.update({"DeveloperCertificates": [b"wrong-public-certificate"]}),
            lambda p: p.update({"ExpirationDate": dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=1)}),
            lambda p: p.update({"Name": "profile\nOTHER_ENV=value"}),
        ]
        for mutate in mutations:
            profile = deepcopy(self.profile)
            mutate(profile)
            with self.assertRaises(RuntimeError):
                signing.validated_profile(profile, self.fingerprint)

    def test_real_es256_signature_and_existing_key_guard(self):
        key = ec.generate_private_key(ec.SECP256R1())
        pem = key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption())
        env = {"APP_STORE_CONNECT_KEY_ID": signing.KEY_ID, "APP_STORE_CONNECT_ISSUER_ID": signing.ISSUER,
               "APP_STORE_CONNECT_API_KEY_BASE64": base64.encodebytes(pem).decode()}
        with patch.dict(os.environ, env):
            header, payload, signature = signing.make_token().split(".")
            raw = base64.urlsafe_b64decode(signature + "==")
            self.assertEqual(len(raw), 64)
            key.public_key().verify(encode_dss_signature(int.from_bytes(raw[:32], "big"), int.from_bytes(raw[32:], "big")),
                                    (header + "." + payload).encode(), ec.ECDSA(hashes.SHA256()))
            self.assertEqual(json.loads(base64.urlsafe_b64decode(payload + "=="))["iss"], signing.ISSUER)
            os.environ["APP_STORE_CONNECT_KEY_ID"] = "WRONG"
            with self.assertRaises(RuntimeError):
                signing.make_token()

    def test_other_apple_resource_cannot_be_mutated(self):
        with self.assertRaises(RuntimeError):
            signing.request("synthetic-token", "/v1/certificates", {"data": {}})

    def test_keychain_compatible_package_preserves_the_exact_key_and_certificate(self):
        key = ec.generate_private_key(ec.SECP256R1())
        name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Synthetic test certificate")])
        now = dt.datetime.now(dt.timezone.utc)
        cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name)
                .public_key(key.public_key()).serial_number(1).not_valid_before(now)
                .not_valid_after(now + dt.timedelta(days=1)).sign(key, hashes.SHA256()))
        password = b"synthetic-random-ascii-import-password"
        content = signing.keychain_package(key, cert, None, password)
        restored_key, restored_cert, _ = load_key_and_certificates(content, password)
        self.assertEqual(restored_cert.fingerprint(hashes.SHA256()), cert.fingerprint(hashes.SHA256()))
        self.assertEqual(restored_key.public_key().public_numbers(), key.public_key().public_numbers())
        with self.assertRaises(ValueError):
            load_key_and_certificates(content, b"wrong-password")

    def test_export_rejects_other_application_version_and_sdk(self):
        info = {"CFBundleIdentifier": signing.BUNDLE, "CFBundleShortVersionString": "1.0.13",
                "CFBundleVersion": "15", "UIStatusBarHidden": True,
                "UIViewControllerBasedStatusBarAppearance": True, "DTSDKName": "iphoneos26.1"}
        validate_info(info)
        for key, value in [("CFBundleIdentifier", "other.app"), ("CFBundleVersion", "5"),
                           ("DTSDKName", "iphoneos18.0"), ("UIStatusBarHidden", False)]:
            bad = dict(info, **{key: value})
            with self.assertRaises(RuntimeError):
                validate_info(bad)
