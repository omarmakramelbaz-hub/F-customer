"""Verify this job's exact signed customer IPA and upload it to TestFlight only."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import re
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile

import jwt

BUNDLE = 'com.faskhaninja.clients'
EXTENSION = BUNDLE + '.extension-example'
APP_ID = '6741027064'


def verify_ipa(path, version, build):
    found = {}
    with zipfile.ZipFile(path) as archive:
        for name in archive.namelist():
            parts = PurePosixPath(name).parts
            main = (len(parts) == 3 and parts[0] == 'Payload'
                    and parts[1].endswith('.app') and parts[-1] == 'Info.plist')
            extension = (len(parts) == 5 and parts[0] == 'Payload'
                         and parts[1].endswith('.app') and parts[2] == 'PlugIns'
                         and parts[3].endswith('.appex') and parts[-1] == 'Info.plist')
            if not (main or extension):
                continue
            info = plistlib.loads(archive.read(name))
            identifier = info.get('CFBundleIdentifier')
            if identifier in found:
                raise RuntimeError('Duplicate bundle metadata in IPA')
            if main and (identifier != BUNDLE or info.get('NSSupportsLiveActivities') is not True):
                raise RuntimeError('Customer app identity or Live Activity capability mismatch')
            found[identifier] = (info.get('CFBundleShortVersionString'), info.get('CFBundleVersion'))
    if found != {BUNDLE: (version, build), EXTENSION: (version, build)}:
        raise RuntimeError('IPA app and extension identity/version mismatch')
    with path.open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()


def get_json(url, token):
    request = urllib.request.Request(url, headers={
        'Authorization': 'Bearer ' + token,
        'Accept': 'application/json',
        'User-Agent': 'Fasakhansta-Customer-Live-Activity-Release',
    })
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code not in (429, 500, 502, 503, 504) or attempt == 3:
                raise RuntimeError('App Store Connect read failed: HTTP ' + str(error.code)) from None
            time.sleep(5 * (attempt + 1))


def matching_build(response, version):
    included = {(item['type'], item['id']): item for item in response.get('included', [])}
    matches = []
    for build in response['data']:
        relationship = build['relationships']['preReleaseVersion']['data']
        prerelease = included[(relationship['type'], relationship['id'])]['attributes']
        if prerelease['version'] == version and prerelease['platform'] == 'IOS':
            matches.append(build)
    if len(matches) > 1:
        raise RuntimeError('Ambiguous App Store Connect build lookup')
    return matches[0] if matches else None


def release(args, record):
    source_sha = os.environ.get('SOURCE_SHA', '')
    if not re.fullmatch(r'[a-f0-9]{40}', source_sha):
        raise RuntimeError('Expected immutable customer source SHA')
    ipa_hash = verify_ipa(args.ipa, args.version, args.build)
    record(version=args.version, build=args.build, source_sha=source_sha,
           ipa_sha256=ipa_hash, bundles_verified=True, app_id=APP_ID,
           upload_accepted=False, status='verified_signed_artifact')

    key_id = os.environ['APP_STORE_CONNECT_KEY_ID']
    issuer = os.environ['APP_STORE_CONNECT_ISSUER_ID']
    key = base64.b64decode(''.join(os.environ['APP_STORE_CONNECT_API_KEY_BASE64'].split()), validate=True)
    if not re.fullmatch(r'[A-Za-z0-9]+', key_id) or not issuer or b'PRIVATE KEY' not in key:
        raise RuntimeError('Missing or invalid App Store Connect credentials')

    def asc(path, params=None):
        now = int(time.time())
        token = jwt.encode({'iss': issuer, 'iat': now - 10, 'exp': now + 600,
                            'aud': 'appstoreconnect-v1'}, key, algorithm='ES256',
                           headers={'kid': key_id, 'typ': 'JWT'})
        url = 'https://api.appstoreconnect.apple.com/v1/' + path
        if params:
            url += '?' + urllib.parse.urlencode(params)
        return get_json(url, token)

    apps = asc('apps', {'filter[bundleId]': BUNDLE})['data']
    if len(apps) != 1 or apps[0]['id'] != APP_ID or apps[0]['attributes']['bundleId'] != BUNDLE:
        raise RuntimeError('Unexpected App Store Connect customer app')

    def find_build():
        return matching_build(asc('builds', {
            'filter[app]': APP_ID, 'filter[version]': args.build,
            'include': 'preReleaseVersion', 'limit': '200',
        }), args.version)

    if find_build() is not None:
        raise RuntimeError('Build number already exists; refusing ambiguous upload')

    key_directory = Path.home() / '.private_keys'
    key_directory.mkdir(mode=0o700, exist_ok=True)
    key_path = key_directory / ('AuthKey_' + key_id + '.p8')
    try:
        with key_path.open('xb') as target:
            os.chmod(key_path, 0o600)
            target.write(key)
    except FileExistsError:
        raise RuntimeError('Refusing to replace an existing App Store Connect key file') from None
    try:
        completed = subprocess.run([
            'xcrun', 'altool', '--upload-app', '--type', 'ios', '--file', str(args.ipa),
            '--apiKey', key_id, '--apiIssuer', issuer, '--output-format', 'json',
        ], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=1200)
        if completed.returncode:
            codes = sorted(set(re.findall(r'"code"\s*:\s*"?(-?\d+)', completed.stdout)))
            record(apple_error_codes=codes, upload_exit_code=completed.returncode)
            raise RuntimeError('Apple rejected the IPA upload')
        record(upload_accepted=True, status='uploaded_processing')
    finally:
        key_path.unlink(missing_ok=True)

    deadline = time.monotonic() + 1200
    while time.monotonic() < deadline:
        build = find_build()
        if build:
            attributes = build['attributes']
            state = attributes['processingState']
            detail = (asc('builds/' + build['id'] + '/buildBetaDetail')['data']['attributes']
                      if state == 'VALID' else {})
            internal = detail.get('internalBuildState')
            record(build_id=build['id'], processing_state=state,
                   internal_build_state=internal,
                   external_build_state=detail.get('externalBuildState'),
                   uses_non_exempt_encryption=attributes.get('usesNonExemptEncryption'),
                   expired=attributes.get('expired'))
            if state in ('FAILED', 'INVALID') or internal == 'PROCESSING_EXCEPTION' or attributes.get('expired'):
                raise RuntimeError('Apple rejected or expired this uploaded build')
            if state == 'VALID' and internal in ('READY_FOR_BETA_TESTING', 'IN_BETA_TESTING'):
                record(status='testflight_ready')
                return
            if state == 'VALID' and internal == 'MISSING_EXPORT_COMPLIANCE':
                record(status='uploaded_requires_export_compliance')
                return
        time.sleep(30)
    record(status='uploaded_processing_timeout')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ipa', type=Path, required=True)
    parser.add_argument('--version', required=True)
    parser.add_argument('--build', required=True)
    args = parser.parse_args()
    if not re.fullmatch(r'\d+\.\d+\.\d+', args.version) or not re.fullmatch(r'\d{1,4}(?:\.\d{1,2}){0,2}', args.build):
        raise SystemExit('Invalid release version or build')
    result_path = Path(os.environ['RUNNER_TEMP']) / 'live-activity-testflight-result.json'
    receipt = {'status': 'preflight', 'upload_accepted': False}

    def record(**values):
        receipt.update(values)
        result_path.write_text(json.dumps(receipt, indent=2) + '\n')
        print(json.dumps(values, sort_keys=True), flush=True)

    try:
        release(args, record)
    except Exception as error:
        # Subprocess exceptions can embed arguments; retain only fixed diagnostics.
        detail = str(error) if type(error) is RuntimeError else type(error).__name__
        record(status='failed', error=detail)
        raise SystemExit(1) from None


if __name__ == '__main__':
    main()
