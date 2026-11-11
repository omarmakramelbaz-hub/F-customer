#!/usr/bin/env python3
"""Deploy static Hosting content through the official Firebase Hosting REST API.

Reference: https://firebase.google.com/docs/hosting/api-deploy
Every Hosting operation is authorized by the API using the existing service
account. This script neither enables APIs nor changes IAM permissions.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
import time

SITE = "fasakhaninjatest"
API = "https://firebasehosting.googleapis.com/v1beta1"
SCOPE = "https://www.googleapis.com/auth/firebase.hosting"
IGNORE = {"firebase.json", "**/.*", "**/node_modules/**"}


class DeploymentError(RuntimeError):
    """A sanitized validation, transport, or Hosting API failure."""


@dataclass(frozen=True)
class Asset:
    path: str
    digest: str
    compressed: bytes


def build_manifest(public_dir: Path) -> dict[str, Asset]:
    root = Path(public_dir).absolute()
    if any(p.is_symlink() for p in (root, *root.parents)) or not root.is_dir():
        raise DeploymentError("Public directory must exist without symlinks")
    manifest: dict[str, Asset] = {}
    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            raise DeploymentError("Symlinks are not allowed in Hosting content")
        if path.is_dir():
            continue
        relative = path.relative_to(root)
        if any(p.startswith(".") or p == "node_modules" for p in relative.parts):
            continue
        if path.name == "firebase.json":
            continue
        try:
            with path.open("rb") as source:
                info = os.fstat(source.fileno())
                if not stat.S_ISREG(info.st_mode) or info.st_size >= 2 * 1024**3:
                    raise DeploymentError("Hosting content must be regular files under 2 GiB")
                compressed = gzip.compress(source.read(), mtime=0)
        except OSError:
            raise DeploymentError("Could not read Hosting content") from None
        name = "/" + relative.as_posix()
        manifest[name] = Asset(name, hashlib.sha256(compressed).hexdigest(), compressed)
    if not manifest or "/index.html" not in manifest:
        raise DeploymentError("Public build must contain index.html")
    return manifest


def convert_hosting_config(hosting: dict) -> dict:
    if not isinstance(hosting, dict) or set(hosting) - {"public", "ignore", "headers", "rewrites"}:
        raise DeploymentError("Unsupported Hosting configuration fields")
    if hosting.get("public") != "build/web":
        raise DeploymentError("Only the build/web public directory is supported")
    ignored = hosting.get("ignore", [])
    if not isinstance(ignored, list) or any(not isinstance(p, str) or p not in IGNORE for p in ignored):
        raise DeploymentError("Unsupported Hosting ignore patterns")
    config = {}
    for kind in ("headers", "rewrites"):
        rules = hosting.get(kind, [])
        if not isinstance(rules, list):
            raise DeploymentError("Hosting rules must be arrays")
        converted = []
        for rule in rules:
            keys = {"source", "headers" if kind == "headers" else "destination"}
            if not isinstance(rule, dict) or set(rule) != keys:
                raise DeploymentError("Unsupported Hosting rule fields")
            source = rule.get("source")
            if not isinstance(source, str) or not source or any(c in source for c in "\r\n\0"):
                raise DeploymentError("Invalid Hosting source pattern")
            result = {"glob": source}
            if kind == "rewrites":
                destination = rule["destination"]
                if not isinstance(destination, str) or not destination.startswith("/") or any(c in destination for c in "\r\n\0"):
                    raise DeploymentError("Only static path rewrites are supported")
                result["path"] = destination
            else:
                entries, headers, names = rule["headers"], {}, set()
                if not isinstance(entries, list) or not entries:
                    raise DeploymentError("Header rules need a nonempty header array")
                for entry in entries:
                    if not isinstance(entry, dict) or set(entry) != {"key", "value"}:
                        raise DeploymentError("Unsupported header fields")
                    key, value = entry["key"], entry["value"]
                    if not isinstance(key, str) or not re.fullmatch(r"[!#$%&'*+.^_`|~0-9A-Za-z-]+", key) or key.lower() in names:
                        raise DeploymentError("Invalid or duplicate header name")
                    if not isinstance(value, str) or any(c in value for c in "\r\n\0"):
                        raise DeploymentError("Invalid header value")
                    headers[key], names = value, names | {key.lower()}
                result["headers"] = headers
            converted.append(result)
        if converted:
            config[kind] = converted
    return config


def _request(session, method: str, url: str, operation: str, **kwargs):
    try:
        response = session.request(method, url, timeout=(15, 60), allow_redirects=False, **kwargs)
    except Exception as error:
        raise DeploymentError(f"{operation} transport failed ({type(error).__name__})") from None
    if not 200 <= response.status_code < 300:
        raise DeploymentError(f"{operation} failed (HTTP {response.status_code})")
    return response


def _json(session, method: str, url: str, operation: str, **kwargs) -> dict:
    response = _request(session, method, url, operation, **kwargs)
    try:
        result = response.json()
    except Exception:
        raise DeploymentError(f"{operation} returned invalid JSON") from None
    if not isinstance(result, dict):
        raise DeploymentError(f"{operation} returned an invalid response")
    return result


def _upload_url(value: str, version: str) -> str:
    expected = f"https://upload-firebasehosting.googleapis.com/upload/{version}/files"
    if value != expected:
        raise DeploymentError("Hosting returned an unexpected upload URL")
    return value


def _upload(session, url: str, content: bytes) -> None:
    for attempt in range(3):
        try:
            response = session.request("POST", url, data=content,
                                       headers={"Content-Type": "application/octet-stream"},
                                       timeout=(15, 60), allow_redirects=False)
        except Exception as error:
            if attempt == 2:
                raise DeploymentError(f"Asset upload transport failed ({type(error).__name__})") from None
        else:
            if 200 <= response.status_code < 300:
                return
            if response.status_code not in {429, 500, 502, 503, 504} or attempt == 2:
                raise DeploymentError(f"Asset upload failed (HTTP {response.status_code})")
        time.sleep(2**attempt)


def deploy(session, site: str, manifest: dict[str, Asset], config: dict) -> str:
    if site != SITE:
        raise DeploymentError("This deployment is restricted to the configured Hosting site")
    if not manifest:
        raise DeploymentError("Cannot deploy an empty build")
    contents = {}
    for name, asset in manifest.items():
        if not isinstance(name, str) or not name.startswith("/") or any(p in {"", ".", ".."} for p in name[1:].split("/")) or name != asset.path:
            raise DeploymentError("Invalid asset path")
        if not re.fullmatch(r"[0-9a-f]{64}", asset.digest) or hashlib.sha256(asset.compressed).hexdigest() != asset.digest:
            raise DeploymentError("Asset content hash does not match")
        contents[asset.digest] = asset.compressed
    created = _json(session, "POST", f"{API}/sites/{site}/versions", "Version creation", json={"config": config})
    version = created.get("name")
    if not isinstance(version, str) or not re.fullmatch(rf"sites/{site}/versions/[A-Za-z0-9_-]+", version):
        raise DeploymentError("Hosting returned an unexpected version name")
    uploaded = set()
    names = sorted(manifest)
    for offset in range(0, len(names), 1000):
        files = {name: manifest[name].digest for name in names[offset:offset + 1000]}
        response = _json(session, "POST", f"{API}/{version}:populateFiles", "File registration", json={"files": files})
        required = response.get("uploadRequiredHashes", [])
        if not isinstance(required, list) or any(not isinstance(h, str) or h not in contents for h in required):
            raise DeploymentError("Hosting requested unknown content hashes")
        upload = _upload_url(response.get("uploadUrl"), version)
        for digest in required:
            if digest not in uploaded:
                _upload(session, f"{upload}/{digest}", contents[digest])
                uploaded.add(digest)
    finalized = _json(session, "PATCH", f"{API}/{version}", "Version finalization",
                      params={"updateMask": "status"}, json={"status": "FINALIZED"})
    if finalized.get("status") != "FINALIZED":
        raise DeploymentError("Hosting did not confirm FINALIZED status")
    release = _json(session, "POST", f"{API}/sites/{site}/releases", "Release creation", params={"versionName": version}, json={})
    name = release.get("name")
    if not isinstance(name, str) or not name.startswith(f"sites/{site}/releases/"):
        raise DeploymentError("Hosting did not confirm a release name")
    return name


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--site", choices=[SITE], default=SITE)
    parser.add_argument("--config", type=Path, default=Path("firebase.json"))
    parser.add_argument("--dry-run", action="store_true", help="Validate local build without credentials or network")
    args = parser.parse_args(argv)
    try:
        config_path = args.config.absolute()
        document = json.loads(config_path.read_text(encoding="utf-8"))
        config = convert_hosting_config(document.get("hosting"))
        manifest = build_manifest(config_path.parent / "build" / "web")
        print(f"Prepared {len(manifest)} static files for {args.site}")
        if args.dry_run:
            print("Dry run complete; no credentials read or network requests made")
            return 0
        # Explicit credentials avoid metadata/ambient-credential discovery.
        from google.oauth2 import service_account
        from google.auth.transport.requests import AuthorizedSession
        info = json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT_JSON"])
        if info.get("type") != "service_account" or info.get("project_id") != SITE:
            raise DeploymentError("Service account must belong to the configured Firebase project")
        credentials = service_account.Credentials.from_service_account_info(info, scopes=[SCOPE])
        with AuthorizedSession(credentials) as session:
            release = deploy(session, args.site, manifest, config)
        print(f"Deployed Hosting release: {release}")
        return 0
    except DeploymentError as error:
        print(f"Hosting deployment stopped: {error}", file=sys.stderr)
    except Exception as error:
        print(f"Hosting deployment stopped ({type(error).__name__})", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
