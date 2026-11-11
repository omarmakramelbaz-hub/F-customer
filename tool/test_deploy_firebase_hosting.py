"""Offline regression checks for the fixed-site Hosting REST deployer.

Run with: python3 -m unittest discover -s tool -p 'test_deploy_firebase_hosting.py'
"""

import contextlib
import gzip
import hashlib
import io
from pathlib import Path
import tempfile
import unittest

from deploy_firebase_hosting import (
    Asset,
    DeploymentError,
    build_manifest,
    convert_hosting_config,
    deploy,
)


SITE = "fasakhaninjatest"
VERSION = f"sites/{SITE}/versions/v1"
API = "https://firebasehosting.googleapis.com/v1beta1"
UPLOAD = f"https://upload-firebasehosting.googleapis.com/upload/{VERSION}/files"


class Response:
    def __init__(self, status=200, body=None):
        self.status_code = status
        self._body = {} if body is None else body

    def json(self):
        return self._body


class Session:
    """A request recorder that never makes network calls."""

    def __init__(self, responses, fallback=None):
        self.responses = list(responses)
        self.fallback = fallback
        self.calls = []

    def request(self, method, url, **kwargs):
        self.calls.append((method, url, kwargs))
        if self.responses:
            return self.responses.pop(0)
        if self.fallback is not None:
            return self.fallback
        raise AssertionError(f"Unexpected request: {method} {url}")


def asset(path="/index.html", content=b"<h1>Fasakhansta</h1>"):
    compressed = gzip.compress(content, mtime=0)
    return Asset(path, hashlib.sha256(compressed).hexdigest(), compressed)


def hosting_config():
    return {
        "public": "build/web",
        "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
        "headers": [
            {
                "source": "**",
                "headers": [
                    {
                        "key": "Cache-Control",
                        "value": "no-store, no-cache, must-revalidate, max-age=0",
                    }
                ],
            }
        ],
        "rewrites": [{"source": "**", "destination": "/index.html"}],
    }


class ManifestTests(unittest.TestCase):
    def test_manifest_is_sorted_deterministic_and_hashes_uploaded_gzip_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "assets").mkdir()
            (root / "index.html").write_bytes(b"home")
            (root / "assets" / "a.bin").write_bytes(bytes(range(256)))

            first = build_manifest(root)
            second = build_manifest(root)

            self.assertEqual(list(first), ["/assets/a.bin", "/index.html"])
            self.assertEqual(first, second)
            for url, item in first.items():
                self.assertEqual(item.path, url)
                self.assertEqual(item.digest, hashlib.sha256(item.compressed).hexdigest())
                self.assertEqual(item.compressed[4:8], b"\x00\x00\x00\x00")
                self.assertEqual(gzip.decompress(item.compressed), (root / url[1:]).read_bytes())

    def test_excluded_config_hidden_segments_and_node_modules_are_not_uploaded(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in (
                "index.html",
                "firebase.json",
                "nested/firebase.json",
                ".env",
                "nested/.secret",
                ".git/config",
                "node_modules/library.js",
                "nested/node_modules/library.js",
            ):
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b"content")

            self.assertEqual(list(build_manifest(root)), ["/index.html"])

    def test_symlink_is_rejected_even_when_its_path_would_be_ignored(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            root = base / "public"
            root.mkdir()
            (root / "index.html").write_bytes(b"home")
            secret = base / "outside.txt"
            secret.write_bytes(b"outside build directory")
            for name in ("linked.txt", ".ignored-link"):
                link = root / name
                link.symlink_to(secret)
                with self.subTest(name=name), self.assertRaises(DeploymentError):
                    build_manifest(root)
                link.unlink()

    def test_symlink_directory_cannot_hide_an_external_tree(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            root = base / "public"
            root.mkdir()
            (root / "index.html").write_bytes(b"home")
            outside = base / "outside"
            outside.mkdir()
            (outside / "private.txt").write_bytes(b"private")
            (root / "node_modules").symlink_to(outside, target_is_directory=True)
            with self.assertRaises(DeploymentError):
                build_manifest(root)

    def test_public_root_must_be_a_real_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            regular_file = base / "file.txt"
            regular_file.write_bytes(b"not a directory")
            linked_root = base / "linked"
            linked_root.symlink_to(base, target_is_directory=True)
            for root in (base / "missing", regular_file, linked_root):
                with self.subTest(root=root.name), self.assertRaises(DeploymentError):
                    build_manifest(root)


class ConfigTests(unittest.TestCase):
    def test_current_cache_headers_and_spa_rewrite_are_preserved(self):
        self.assertEqual(
            convert_hosting_config(hosting_config()),
            {
                "headers": [
                    {
                        "glob": "**",
                        "headers": {
                            "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0"
                        },
                    }
                ],
                "rewrites": [{"glob": "**", "path": "/index.html"}],
            },
        )

    def test_unknown_hosting_or_rule_fields_fail_instead_of_disappearing(self):
        cases = []
        config = hosting_config()
        config["cleanUrls"] = True
        cases.append(config)
        config = hosting_config()
        config["rewrites"][0]["function"] = "unexpected-function"
        cases.append(config)
        config = hosting_config()
        config["headers"][0]["regex"] = ".*"
        cases.append(config)
        for config in cases:
            with self.subTest(config=config), self.assertRaises(DeploymentError):
                convert_hosting_config(config)

    def test_duplicate_header_keys_are_not_silently_overwritten(self):
        config = hosting_config()
        config["headers"][0]["headers"].append({"key": "cache-control", "value": "public"})
        with self.assertRaises(DeploymentError):
            convert_hosting_config(config)

    def test_unknown_ignore_pattern_and_malformed_header_fail_closed(self):
        config = hosting_config()
        config["ignore"].append("**/*.map")
        with self.assertRaises(DeploymentError):
            convert_hosting_config(config)
        config = hosting_config()
        config["headers"][0]["headers"] = {"Cache-Control": "public"}
        with self.assertRaises(DeploymentError):
            convert_hosting_config(config)


class DeploymentTests(unittest.TestCase):
    def test_populate_batches_respect_limit_and_include_every_file(self):
        template = asset()
        manifest = {
            f"/asset-{number:04}.txt": Asset(
                f"/asset-{number:04}.txt", template.digest, template.compressed
            )
            for number in range(1001)
        }
        session = Session(
            [
                Response(body={"name": VERSION, "status": "CREATED"}),
                Response(body={"uploadRequiredHashes": [], "uploadUrl": UPLOAD}),
                Response(body={"uploadRequiredHashes": [], "uploadUrl": UPLOAD}),
                Response(body={"name": VERSION, "status": "FINALIZED"}),
                Response(body={"name": f"sites/{SITE}/releases/r1"}),
            ]
        )
        deploy(session, SITE, manifest, {})
        batches = [
            kwargs["json"]["files"]
            for _, url, kwargs in session.calls
            if url.endswith(":populateFiles")
        ]
        self.assertEqual([len(batch) for batch in batches], [1000, 1])
        self.assertEqual({path for batch in batches for path in batch}, set(manifest))

    def test_release_occurs_only_after_upload_and_verified_finalization(self):
        item = asset()
        session = Session(
            [
                Response(body={"name": VERSION, "status": "CREATED"}),
                Response(body={"uploadRequiredHashes": [item.digest], "uploadUrl": UPLOAD}),
                Response(),
                Response(body={"name": VERSION, "status": "FINALIZED"}),
                Response(body={"name": f"sites/{SITE}/releases/r1"}),
            ]
        )
        result = deploy(session, SITE, {item.path: item}, {"rewrites": [{"glob": "**", "path": "/index.html"}]})
        self.assertEqual(result, f"sites/{SITE}/releases/r1")
        self.assertEqual([call[0] for call in session.calls], ["POST", "POST", "POST", "PATCH", "POST"])
        self.assertEqual(session.calls[0][1], f"{API}/sites/{SITE}/versions")
        self.assertEqual(session.calls[1][1], f"{API}/{VERSION}:populateFiles")
        self.assertEqual(session.calls[1][2]["json"], {"files": {item.path: item.digest}})
        self.assertEqual(session.calls[2][1], f"{UPLOAD}/{item.digest}")
        self.assertEqual(session.calls[2][2]["data"], item.compressed)
        self.assertEqual(session.calls[3][2]["json"], {"status": "FINALIZED"})
        self.assertIn(f"/sites/{SITE}/releases", session.calls[4][1])

    def test_upload_failure_never_finalizes_or_publishes_and_does_not_echo_error_body(self):
        item = asset()
        private_marker = "never-print-credentials-or-response-body"
        session = Session(
            [
                Response(body={"name": VERSION, "status": "CREATED"}),
                Response(body={"uploadRequiredHashes": [item.digest], "uploadUrl": UPLOAD}),
            ],
            fallback=Response(403, {"error": {"message": private_marker}}),
        )
        stdout, stderr = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            with self.assertRaises(DeploymentError) as caught:
                deploy(session, SITE, {item.path: item}, {})
        self.assertTrue(all(method != "PATCH" and "/releases" not in url for method, url, _ in session.calls))
        self.assertNotIn(private_marker, str(caught.exception) + stdout.getvalue() + stderr.getvalue())

    def test_unknown_required_hash_stops_before_upload(self):
        item = asset()
        session = Session(
            [
                Response(body={"name": VERSION, "status": "CREATED"}),
                Response(body={"uploadRequiredHashes": ["0" * 64], "uploadUrl": UPLOAD}),
            ]
        )
        with self.assertRaises(DeploymentError):
            deploy(session, SITE, {item.path: item}, {})
        self.assertEqual(len(session.calls), 2)

    def test_upload_url_must_match_exact_authorized_https_site_version_prefix(self):
        item = asset()
        unsafe_urls = (
            UPLOAD.replace("https://", "http://"),
            UPLOAD.replace("upload-firebasehosting.googleapis.com", "attacker.example"),
            UPLOAD.replace("upload-firebasehosting.googleapis.com", "upload-firebasehosting.googleapis.com.attacker.example"),
            UPLOAD.replace("fasakhaninjatest", "another-site"),
            UPLOAD.replace("versions/v1", "versions/another-version"),
            UPLOAD + "?redirect=https://attacker.example",
        )
        for url in unsafe_urls:
            session = Session(
                [
                    Response(body={"name": VERSION, "status": "CREATED"}),
                    Response(body={"uploadRequiredHashes": [item.digest], "uploadUrl": url}),
                ]
            )
            with self.subTest(url=url), self.assertRaises(DeploymentError):
                deploy(session, SITE, {item.path: item}, {})
            self.assertEqual(len(session.calls), 2)

    def test_site_mismatch_is_rejected_without_network_requests(self):
        item = asset()
        session = Session([])
        with self.assertRaises(DeploymentError):
            deploy(session, "unapproved-site", {item.path: item}, {})
        self.assertEqual(session.calls, [])

    def test_unverified_finalization_never_publishes(self):
        item = asset()
        session = Session(
            [
                Response(body={"name": VERSION, "status": "CREATED"}),
                Response(body={"uploadRequiredHashes": [], "uploadUrl": UPLOAD}),
                Response(body={"name": VERSION, "status": "CREATED"}),
            ]
        )
        with self.assertRaises(DeploymentError):
            deploy(session, SITE, {item.path: item}, {})
        self.assertEqual(len(session.calls), 3)
        self.assertTrue(all("/releases" not in url for _, url, _ in session.calls))


if __name__ == "__main__":
    unittest.main()
