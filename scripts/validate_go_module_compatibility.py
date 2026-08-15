#!/usr/bin/env python3
"""Validate consumers against the exact selected opsnexus-common revision.

The validation copies each consumer to a temporary directory, resolves the
selected common commit there, and never changes a checked-out repository.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

MODULE = "github.com/OpsNexusHQ/opsnexus-common"


def fail(message: str) -> None:
    print(f"ci/compatibility-modules: ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def run(command: list[str], cwd: Path, env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    print(f"ci/compatibility-modules: {' '.join(command)}")
    result = subprocess.run(command, cwd=cwd, env=env, text=True, capture_output=True)
    if result.stdout:
        print(result.stdout, end="")
    if result.returncode != 0:
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
        fail(f"command failed with status {result.returncode}: {' '.join(command)}")
    return result


def origin_hash(module_json: str, context: str) -> str:
    try:
        data = json.loads(module_json)
    except json.JSONDecodeError as exc:
        fail(f"{context} returned invalid module JSON: {exc}")
    value = data.get("Origin", {}).get("Hash")
    if not isinstance(value, str) or len(value) != 40:
        fail(f"{context} did not expose a 40-character VCS Origin.Hash")
    return value.lower()


def validate_consumer(source: Path, common_sha: str, env: dict[str, str]) -> None:
    if not (source / "go.mod").is_file():
        fail(f"consumer {source} has no go.mod")
    go_mod = (source / "go.mod").read_text(encoding="utf-8")
    if "replace github.com/OpsNexusHQ/opsnexus-common" in go_mod or "=> ../opsnexus-common" in go_mod:
        fail(f"consumer {source} contains a sibling filesystem replacement")

    with tempfile.TemporaryDirectory(prefix="opsnexus-ci4-module-") as temp:
        work = Path(temp) / source.name
        shutil.copytree(source, work, ignore=shutil.ignore_patterns(".git", "node_modules", "dist"))
        download = run(["go", "mod", "download", "-json", f"{MODULE}@{common_sha}"], work, env)
        downloaded_hash = origin_hash(download.stdout, "go mod download")
        if downloaded_hash != common_sha.lower():
            fail(f"{source.name} downloaded common {downloaded_hash}, expected {common_sha}")

        run(["go", "get", f"{MODULE}@{common_sha}"], work, env)
        resolved = run(["go", "list", "-m", "-json", MODULE], work, env)
        resolved_hash = origin_hash(resolved.stdout, "go list -m")
        if resolved_hash != common_sha.lower():
            fail(f"{source.name} resolved common {resolved_hash}, expected {common_sha}")
        print(f"ci/compatibility-modules: {source.name} consumes {MODULE} commit {resolved_hash}")
        run(["go", "mod", "verify"], work, env)
        run(["go", "test", "./..."], work, env)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--common-sha", required=True)
    parser.add_argument("--consumer", action="append", required=True)
    args = parser.parse_args()
    if len(args.common_sha) != 40 or any(c not in "0123456789abcdefABCDEF" for c in args.common_sha):
        fail("common SHA must be exactly 40 hexadecimal characters")
    env = os.environ.copy()
    env["GOPROXY"] = "direct"
    env["GOSUMDB"] = "sum.golang.org"
    for consumer in args.consumer:
        validate_consumer(Path(consumer).resolve(), args.common_sha, env)


if __name__ == "__main__":
    main()
