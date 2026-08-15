#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / 'daegil_app'
errors = []
manual = []

required_files = [
    APP / 'pubspec.yaml',
    APP / 'lib' / 'main.dart',
    APP / 'test' / 'widget_test.dart',
    APP / 'assets' / 'videos' / 'fortune_cat.mp4',
]
for path in required_files:
    if not path.exists():
        errors.append(f'missing release file: {path.relative_to(ROOT)}')

asset = APP / 'assets' / 'videos' / 'fortune_cat.mp4'
if asset.exists() and asset.stat().st_size == 0:
    errors.append('cat video asset is empty')

pubspec = (APP / 'pubspec.yaml').read_text(encoding='utf-8', errors='ignore')
for dependency in ('flutter_riverpod', 'go_router', 'video_player'):
    if dependency not in pubspec:
        errors.append(f'missing dependency: {dependency}')
if 'assets/videos/fortune_cat.mp4' not in pubspec:
    errors.append('cat video is not declared in pubspec assets')

android = (APP / 'android' / 'app' / 'build.gradle.kts').read_text(
    encoding='utf-8', errors='ignore'
)
ios_project = (APP / 'ios' / 'Runner.xcodeproj' / 'project.pbxproj').read_text(
    encoding='utf-8', errors='ignore'
)
if 'com.example' in android or 'com.example' in ios_project:
    manual.append('final Android applicationId and iOS bundle ID')
manual.extend([
    'production Supabase/OAuth/AdMob/Firebase/AI credentials and console setup',
    'physical Android/iOS install, provider login, SSV, notification, and 03:55/04:00 QA',
    'store signing, privacy labels, Data Safety, legal approval, and asset license approval',
])

if errors:
    for error in errors:
        print(f'ERROR: {error}')
    print(f'FAIL: {len(errors)} automated release errors')
    sys.exit(1)

print('PASS: automated release artifact/config checks')
print('MANUAL_ACTION_REQUIRED:')
for item in manual:
    print(f'- {item}')
