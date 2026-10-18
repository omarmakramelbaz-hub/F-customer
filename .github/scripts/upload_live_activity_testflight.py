"""Deliver the already-reviewed signed IPA; never rebuild or publish a store version."""
import base64
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile

import jwt

REPO = 'omarmakramelbaz-hub/F-customer'
SOURCE_RUN = 39154681945
SOURCE_SHA = '1c47f491c0e9353676a54a962ce1cb9692e6a5ac'
ARTIFACT_ID = 12146309417
ARTIFACT_NAME = f'Fasakhansta-iOS-2.0.7-59.1-signed-{SOURCE_SHA}'
ARTIFACT_SHA256 = 'a15976e11fdc197971ab974cd572be2cf22b688853712e4e66cda096543a3685'
BUNDLE = 'com.faskhaninja.clients'
EXTENSION = BUNDLE + '.extension-example'
VERSION, BUILD = '2.0.7', '59.1'
RESULT_PATH = Path(os.environ['RUNNER_TEMP']) / 'live-activity-testflight-result.json'
result = {'version': VERSION, 'build': BUILD, 'source_sha': SOURCE_SHA,
          'artifact_id': ARTIFACT_ID, 'artifact_sha256': ARTIFACT_SHA256,
          'upload_accepted': False, 'status': 'preflight'}


def record(**values):
    result.update(values)
    RESULT_PATH.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(values, sort_keys=True), flush=True)


def get_json(url, token):
    request = urllib.request.Request(url, headers={
        'Authorization': 'Bearer ' + token, 'Accept': 'application/json',
        'User-Agent': 'Fasakhansta-TestFlight-Delivery'})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code not in (429, 500, 502, 503, 504) or attempt == 3:
                raise RuntimeError(f'API request failed with HTTP {error.code}: {url.split("?")[0]}') from None
            time.sleep(10 * (attempt + 1))


def verify_ipa(ipa):
    with zipfile.ZipFile(ipa) as archive:
        infos = {}
        for name in archive.namelist():
            parts = PurePosixPath(name).parts
            is_main = len(parts) == 3 and parts[0] == 'Payload' and parts[1].endswith('.app') and parts[-1] == 'Info.plist'
            is_extension = len(parts) == 5 and parts[0] == 'Payload' and parts[1].endswith('.app') and parts[2] == 'PlugIns' and parts[3].endswith('.appex') and parts[-1] == 'Info.plist'
            if is_main or is_extension:
                info = plistlib.loads(archive.read(name))
                identifier = info['CFBundleIdentifier']
                if identifier in infos:
                    raise RuntimeError('Duplicate bundle metadata in IPA')
                infos[identifier] = (info['CFBundleShortVersionString'], info['CFBundleVersion'])
        if infos != {BUNDLE: (VERSION, BUILD), EXTENSION: (VERSION, BUILD)}:
            raise RuntimeError(f'Unexpected signed IPA bundle metadata: {infos!r}')
    record(ipa_sha256=hashlib.sha256(ipa.read_bytes()).hexdigest(), bundles_verified=True)


def main():
    github_token = os.environ['GH_TOKEN']
    key_id = os.environ['APP_STORE_CONNECT_KEY_ID']
    issuer = os.environ['APP_STORE_CONNECT_ISSUER_ID']
    key = base64.b64decode(''.join(os.environ['APP_STORE_CONNECT_API_KEY_BASE64'].split()), validate=True)
    if not key_id or not issuer or b'PRIVATE KEY' not in key:
        raise RuntimeError('Missing App Store Connect signing credentials')

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
    if len(apps) != 1 or apps[0]['attributes']['bundleId'] != BUNDLE:
        raise RuntimeError('App Store Connect bundle lookup did not return exactly one app')
    app_id = apps[0]['id']
    record(app_id=app_id)

    def find_build():
        response = asc('builds', {'filter[app]': app_id, 'filter[version]': BUILD,
                                  'include': 'preReleaseVersion,buildBetaDetail', 'limit': '200'})
        included = {(entry['type'], entry['id']): entry for entry in response.get('included', [])}
        matches = []
        for build in response['data']:
            relation = build['relationships']['preReleaseVersion']['data']
            prerelease = included[(relation['type'], relation['id'])]['attributes']
            if prerelease['version'] == VERSION and prerelease['platform'] == 'IOS':
                matches.append(build)
        if len(matches) > 1:
            raise RuntimeError('Ambiguous App Store Connect build lookup')
        return matches[0] if matches else None

    api = f'https://api.github.com/repos/{REPO}'
    source = get_json(f'{api}/actions/runs/{SOURCE_RUN}', github_token)
    artifact = get_json(f'{api}/actions/artifacts/{ARTIFACT_ID}', github_token)
    if source['head_sha'] != SOURCE_SHA or source['conclusion'] != 'success':
        raise RuntimeError('Signed artifact source run did not match the reviewed successful build')
    if artifact['name'] != ARTIFACT_NAME or artifact['expired'] or artifact['workflow_run']['id'] != SOURCE_RUN:
        raise RuntimeError('Signed artifact provenance mismatch')
    if artifact.get('digest') != 'sha256:' + ARTIFACT_SHA256:
        raise RuntimeError('Signed artifact digest metadata mismatch')

    with tempfile.TemporaryDirectory(prefix='live-activity-upload-', dir=os.environ['RUNNER_TEMP']) as temporary:
        work = Path(temporary)
        bundle_zip = work / 'artifact.zip'
        subprocess.run(['curl', '--fail', '--silent', '--show-error', '--location',
                        '--header', 'Authorization: Bearer ' + github_token,
                        '--header', 'Accept: application/vnd.github+json',
                        '--output', str(bundle_zip), f'{api}/actions/artifacts/{ARTIFACT_ID}/zip'], check=True)
        if hashlib.sha256(bundle_zip.read_bytes()).hexdigest() != ARTIFACT_SHA256:
            raise RuntimeError('Downloaded artifact checksum mismatch')
        ipa = work / 'Fasakhansta-2.0.7-59.1.ipa'
        with zipfile.ZipFile(bundle_zip) as archive:
            files = [name for name in archive.namelist() if name.lower().endswith('.ipa') and not name.endswith('/')]
            if len(files) != 1:
                raise RuntimeError('Expected exactly one signed IPA')
            with archive.open(files[0]) as source_file, ipa.open('wb') as target:
                while chunk := source_file.read(1024 * 1024):
                    target.write(chunk)
        verify_ipa(ipa)
        existing = find_build()
        if existing:
            record(status='existing_build_requires_provenance_verification', build_id=existing['id'])
            return
        else:
            key_directory = Path.home() / '.private_keys'
            key_directory.mkdir(mode=0o700, exist_ok=True)
            key_path = key_directory / f'AuthKey_{key_id}.p8'
            try:
                with key_path.open('xb') as key_file:
                    os.chmod(key_path, 0o600)
                    key_file.write(key)
            except FileExistsError:
                raise RuntimeError('Refusing to overwrite an existing API key file') from None
            try:
                completed = subprocess.run([
                    'xcrun', 'altool', '--upload-app', '--type', 'ios', '--file', str(ipa),
                    '--apiKey', key_id, '--apiIssuer', issuer],
                    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=1200)
                print(completed.stdout, flush=True)
                if completed.returncode:
                    raise RuntimeError(f'Apple upload failed with exit code {completed.returncode}')
                record(upload_accepted=True, status='uploaded_processing')
            finally:
                key_path.unlink(missing_ok=True)

    deadline = time.monotonic() + 1800
    while time.monotonic() < deadline:
        build = find_build()
        if build:
            attributes = build['attributes']
            state = attributes['processingState']
            detail = (asc(f'builds/{build["id"]}/buildBetaDetail')['data']['attributes']
                      if state == 'VALID' else {})
            internal = detail.get('internalBuildState')
            record(build_id=build['id'], processing_state=state,
                   internal_build_state=internal,
                   external_build_state=detail.get('externalBuildState'),
                   uses_non_exempt_encryption=attributes.get('usesNonExemptEncryption'),
                   expired=attributes.get('expired'))
            if state in ('FAILED', 'INVALID') or internal == 'PROCESSING_EXCEPTION' or attributes.get('expired'):
                raise RuntimeError('Apple rejected or expired this build')
            if state == 'VALID' and internal in ('READY_FOR_BETA_TESTING', 'IN_BETA_TESTING'):
                record(status='testflight_ready')
                return
            if state == 'VALID' and internal == 'MISSING_EXPORT_COMPLIANCE':
                record(status='uploaded_requires_export_compliance')
                return
        time.sleep(30)
    record(status='uploaded_processing_timeout')


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        # Subprocess exceptions can contain command arguments, including credentials.
        # Persist only a safe error category; our own RuntimeErrors contain fixed diagnostics.
        diagnostic = str(error) if type(error) is RuntimeError else type(error).__name__
        record(status='failed', error=diagnostic)
        raise SystemExit(1) from None
