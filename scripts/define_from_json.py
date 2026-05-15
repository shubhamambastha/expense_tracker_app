#!/usr/bin/env python3
"""
Usage: python3 scripts/define_from_json.py config.dev.json run
or:    python3 scripts/define_from_json.py config.dev.json build ios --release

This reads the JSON file and runs `flutter` with `--dart-define=KEY=VALUE` for each entry.
Do NOT store real secrets in committed JSON files; use local copies ignored by git.
"""
import json
import subprocess
import sys
from pathlib import Path

if len(sys.argv) < 3:
    print("Usage: define_from_json.py <config.json> <flutter-subcommand> [flutter-args...]")
    sys.exit(2)

config_path = Path(sys.argv[1])
if not config_path.exists():
    print(f"Config file not found: {config_path}")
    sys.exit(2)

with config_path.open() as f:
    data = json.load(f)

defines = []
for k, v in data.items():
    # Escape quotes in values
    val = str(v).replace('"', '\\"')
    defines.append(f"--dart-define={k}={val}")

flutter_cmd = ["flutter", sys.argv[2]] + sys.argv[3:] + defines
print('Running:', ' '.join(flutter_cmd))

# Execute the flutter command
try:
    subprocess.check_call(flutter_cmd)
except subprocess.CalledProcessError as e:
    print('Command failed with exit code', e.returncode)
    sys.exit(e.returncode)
