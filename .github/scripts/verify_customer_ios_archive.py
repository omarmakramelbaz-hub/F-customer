"""Verify the signed customer archive without depending on codesign's display format."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import plistlib
import subprocess

BUNDLE = 'com.faskhaninja.clients'
EXTENSION = BUNDLE + '.extension-example'
TEAM = '4769DGYGT3'
GROUP = 'group.faskhaninja.liveactivities'


class VerificationError(RuntimeError):
    pass


def require(condition, message):
    if not condition:
        raise VerificationError(message)


def decode_plist(output):
    """Accept a real binary/XML plist; never parse codesign's human-readable DER view."""
    data = output.lstrip(b'\xef\xbb\xbf \r\n\t')
    if data.startswith(b'bplist00'):
        value = plistlib.loads(data)
    else:
        start = data.find(b'<?xml')
        if start < 0:
            start = data.find(b'<plist')
        end = data.find(b'</plist>', max(start, 0))
        require(start >= 0 and end >= 0, 'Entitlements output is not an XML or binary plist')
        candidate = data[start:end + len(b'</plist>')]
        require(candidate.count(b'<plist') == 1, 'Ambiguous entitlement plist output')
        value = plistlib.loads(candidate)
    require(isinstance(value, dict), 'Expected a plist dictionary')
    return value


def run_checked(command, record, phase):
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
    record(phase=phase, command_returncode=result.returncode)
    require(result.returncode == 0, phase + ' command failed')
    return result.stdout


def verify_entitlements(entitlements, identifier):
    require(not entitlements.get('get-task-allow', False), 'Development signing is not allowed')
    require(entitlements.get('application-identifier') == TEAM + '.' + identifier,
            'Archived app signing identity mismatch')
    require(entitlements.get('com.apple.developer.team-identifier') == TEAM,
            'Archived app signing team mismatch')
    require(GROUP in entitlements.get('com.apple.security.application-groups', []),
            'Archived app group is missing')
    if identifier == BUNDLE:
        require(entitlements.get('aps-environment') == 'production',
                'Archived app must use production push')


def verify_profile(profile, identifier):
    require('ProvisionedDevices' not in profile and not profile.get('ProvisionsAllDevices'),
            'Expected an App Store distribution profile')
    expiration = profile.get('ExpirationDate')
    require(isinstance(expiration, datetime.datetime), 'Profile expiration date is missing')
    if expiration.tzinfo is None:
        expiration = expiration.replace(tzinfo=datetime.timezone.utc)
    require(expiration > datetime.datetime.now(datetime.timezone.utc),
            'Embedded provisioning profile has expired')
    entitlements = profile.get('Entitlements', {})
    verify_entitlements(entitlements, identifier)


def verify(archive, version, build, record):
    applications = sorted((archive / 'Products/Applications').glob('*.app'))
    record(phase='locate_archive', application_count=len(applications))
    require(len(applications) == 1, 'Expected exactly one archived application')
    app = applications[0]
    extensions = sorted((app / 'PlugIns').glob('*.appex'))
    record(application_name=app.name, extension_count=len(extensions))
    require(len(extensions) == 1, 'Expected exactly one archived Live Activity extension')

    for bundle, expected_identifier in [(app, BUNDLE), (extensions[0], EXTENSION)]:
        with (bundle / 'Info.plist').open('rb') as source:
            info = plistlib.load(source)
        identifier = info.get('CFBundleIdentifier')
        actual = (info.get('CFBundleShortVersionString'), info.get('CFBundleVersion'))
        record(phase='bundle_metadata', bundle_name=bundle.name, bundle_id=identifier,
               actual_version=actual[0], actual_build=actual[1])
        require(identifier == expected_identifier, 'Archived bundle identity mismatch')
        require(actual == (version, build), 'Archived bundle version mismatch')
        if identifier == BUNDLE:
            require(info.get('NSSupportsLiveActivities') is True, 'Live Activity capability is missing')

        run_checked(['codesign', '--verify', '--deep', '--strict', str(bundle)],
                    record, 'verify_signature')
        # Apple TN3125: current codesign defaults to a human-readable DER representation.
        # --xml is required before plistlib can decode the extracted entitlements.
        output = run_checked(
            ['codesign', '--display', '--entitlements', '-', '--xml', str(bundle)],
            record, 'extract_entitlements',
        )
        record(entitlements_output_bytes=len(output),
               entitlements_output_sha256=hashlib.sha256(output).hexdigest())
        entitlements = decode_plist(output)
        record(phase='check_entitlements',
               entitlement_app_id=entitlements.get('application-identifier'),
               entitlement_team=entitlements.get('com.apple.developer.team-identifier'),
               development_signing=bool(entitlements.get('get-task-allow', False)),
               production_push=entitlements.get('aps-environment') == 'production',
               live_activity_group=GROUP in entitlements.get('com.apple.security.application-groups', []))
        verify_entitlements(entitlements, identifier)

        output = run_checked(
            ['security', 'cms', '-D', '-i', str(bundle / 'embedded.mobileprovision')],
            record, 'extract_embedded_profile',
        )
        profile = decode_plist(output)
        record(phase='check_embedded_profile')
        verify_profile(profile, identifier)
        record(phase='bundle_verified', bundle_id=identifier)
    record(status='verified', phase='complete', bundles_verified=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--archive', type=Path, required=True)
    parser.add_argument('--version', required=True)
    parser.add_argument('--build', required=True)
    args = parser.parse_args()
    result = Path(os.environ['RUNNER_TEMP']) / 'customer-ios-archive-verification.json'
    receipt = {
        'status': 'verifying', 'bundles_verified': False,
        'version': args.version, 'build': args.build,
        'source_sha': os.environ.get('GITHUB_SHA', ''),
    }

    def record(**values):
        receipt.update(values)
        result.write_text(json.dumps(receipt, indent=2) + '\n')
        print(json.dumps(values, sort_keys=True), flush=True)

    record(phase='start')
    try:
        verify(args.archive, args.version, args.build, record)
    except Exception as error:
        detail = str(error) if type(error) is VerificationError else type(error).__name__
        record(status='failed', error=detail)
        raise SystemExit(1) from None


if __name__ == '__main__':
    main()

