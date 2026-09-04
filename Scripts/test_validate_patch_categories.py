#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "Scripts" / "validate_patch_categories.py"

with tempfile.TemporaryDirectory() as temp_dir:
    fixture_root = Path(temp_dir) / "repo"
    shutil.copytree(ROOT / "ThreeOneOSFive", fixture_root / "ThreeOneOSFive")
    manifest_path = fixture_root / "ThreeOneOSFive" / "FreeFirePatches" / "manifest.json"
    entries = json.loads(manifest_path.read_text(encoding="utf-8"))
    target = next(entry for entry in entries if entry["category"] == "Cache")
    target["category"] = "Avatar"
    manifest_path.write_text(json.dumps(entries, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    result = subprocess.run(
        ["python3", str(VALIDATOR), "--root", str(fixture_root)],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        raise SystemExit("negative category test unexpectedly passed")

print("negative category regression test passed")
