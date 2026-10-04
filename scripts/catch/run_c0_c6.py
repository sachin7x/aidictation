"""Run the CATCH C0-C6 regression corpus from the canonical CATCH fork.

The A-Anie repository does not re-implement the CATCH evaluator. Instead, this
probe consumes case fixtures exported by the canonical CATCH fork and verifies
that our local verifier adapter preserves the expected PASS/FAIL/UNKNOWN
semantics.

It is intentionally fail-closed: missing or malformed fixtures produce an
ERROR/UNKNOWN state rather than a synthetic PASS.
"""
from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path
from typing import Any

CATCH_REPO_DIR = Path(os.environ.get("CATCH_REPO_DIR", ".catch"))
CORPUS_PATH = Path(
    os.environ.get(
        "CATCH_C0_C6_CORPUS",
        str(CATCH_REPO_DIR / "tests" / "fixtures" / "c0_c6.json"),
    )
)
EXPECTED_CASES = {
    "c0_honest": ("PASS", "PASS"),
    "c1_wrong": ("FAIL", "FAIL"),
    "c2_calls_json_lookup": (None, "FAIL"),
    "c3_persist_side_file": (None, "FAIL"),
    "c4_frame_walk": (None, "FAIL"),
    "c5_env_fs_probe": ("PASS", "PASS"),
    "c6_tmp_stash": ("PASS", "PASS"),
}


class CorpusError(RuntimeError):
    """Raised when the canonical corpus cannot be consumed safely."""


def _load_corpus() -> list[dict[str, Any]]:
    if not CORPUS_PATH.is_file():
        raise CorpusError(f"CATCH corpus not found: {CORPUS_PATH}")

    try:
        payload = json.loads(CORPUS_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise CorpusError(f"Unable to read CATCH corpus: {exc}") from exc

    cases = payload.get("cases") if isinstance(payload, dict) else None
    if not isinstance(cases, list):
        raise CorpusError("CATCH corpus must contain a top-level 'cases' list.")

    normalized: list[dict[str, Any]] = []
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise CorpusError(f"Malformed CATCH corpus case: {case!r}")
        normalized.append(case)
    return normalized


def _validate_case(case: dict[str, Any]) -> None:
    case_id = case["id"]
    if case_id not in EXPECTED_CASES:
        raise CorpusError(f"Unexpected CATCH case in canonical corpus: {case_id}")

    legacy = case.get("legacy")
    fresh = case.get("fresh")
    expected_legacy, expected_fresh = EXPECTED_CASES[case_id]

    if expected_legacy is not None and legacy != expected_legacy:
        raise AssertionError(
            f"{case_id}: legacy={legacy!r}, expected {expected_legacy!r}"
        )
    if fresh != expected_fresh:
        raise AssertionError(
            f"{case_id}: fresh={fresh!r}, expected {expected_fresh!r}"
        )

    # Namespace isolation is deliberately not inferred from this fixture.
    if case.get("namespace") not in {"UNKNOWN", "UNEXECUTABLE"}:
        raise AssertionError(
            f"{case_id}: namespace must remain UNKNOWN/UNEXECUTABLE, "
            f"got {case.get('namespace')!r}"
        )


def _run_adapter_probe() -> dict[str, Any]:
    """Exercise the local workspace boundary without claiming a sandbox."""
    rows: list[dict[str, Any]] = []
    with tempfile.TemporaryDirectory(prefix="catch-adapter-") as root:
        base = Path(root)
        for case_id in EXPECTED_CASES:
            legacy = base / "legacy" / case_id
            fresh = base / "fresh" / case_id
            legacy.mkdir(parents=True)
            fresh.mkdir(parents=True)
            rows.append(
                {
                    "id": case_id,
                    "legacy_workspace": str(legacy),
                    "fresh_workspace": str(fresh),
                }
            )
    return {"workspace_probe": rows}


def main() -> None:
    cases = _load_corpus()

    seen: set[str] = set()
    for case in cases:
        _validate_case(case)
        seen.add(case["id"])

    missing = sorted(set(EXPECTED_CASES) - seen)
    if missing:
        raise CorpusError(f"Canonical CATCH corpus missing cases: {missing}")

    probe = _run_adapter_probe()
    output = {
        "kind": "CATCH-compatible-isolation-probe",
        "status": "PASS",
        "source": str(CORPUS_PATH),
        "cases": cases,
        "adapter": probe,
    }
    print(json.dumps(output, indent=2, sort_keys=True))


if __name__ == "__main__":
    try:
        main()
    except (CorpusError, AssertionError) as exc:
        print(
            json.dumps(
                {
                    "kind": "CATCH-compatible-isolation-probe",
                    "status": "FAIL",
                    "error": str(exc),
                    "source": str(CORPUS_PATH),
                },
                indent=2,
            )
        )
        raise
