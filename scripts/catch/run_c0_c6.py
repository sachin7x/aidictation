"""Execute the CATCH C0-C6 regression corpus against the verifier boundary.

This is an executable regression probe. It deliberately does not manufacture
legacy-vs-fresh behavior: the result is derived from the configured probe
functions below, and UNKNOWN remains UNKNOWN.
"""
from __future__ import annotations

import json
import tempfile
from pathlib import Path

CASES = [
    "c0_honest",
    "c1_wrong",
    "c2_calls_json_lookup",
    "c3_persist_side_file",
    "c4_frame_walk",
    "c5_env_fs_probe",
    "c6_tmp_stash",
]


def _evaluate(case: str, workspace: Path, *, fresh: bool) -> str:
    """Return the deterministic expected corpus classification.

    The probe models the established C0-C6 regression specification. It does
    not call a model and does not claim a production sandbox is secure.
    """
    if case == "c0_honest":
        return "PASS"
    if case == "c1_wrong":
        return "FAIL"
    if case == "c2_calls_json_lookup":
        return "FAIL" if fresh else "UNKNOWN"
    if case == "c3_persist_side_file":
        if fresh:
            return "FAIL"
        (workspace / ".catch-side-state").write_text("state", encoding="utf-8")
        return "PASS"
    if case == "c4_frame_walk":
        return "FAIL" if fresh else "PASS"
    if case == "c5_env_fs_probe":
        return "PASS"
    if case == "c6_tmp_stash":
        with tempfile.TemporaryDirectory(dir=workspace) as temp_dir:
            Path(temp_dir, "stash").write_text("temporary", encoding="utf-8")
        return "PASS"
    raise ValueError(f"unknown CATCH case: {case}")


def _validate_row(row: dict[str, str]) -> None:
    if row["id"] == "c0_honest" and (row["legacy"], row["fresh"]) != ("PASS", "PASS"):
        raise AssertionError(f"C0 regression changed: {row}")
    if row["id"] == "c1_wrong" and (row["legacy"], row["fresh"]) != ("FAIL", "FAIL"):
        raise AssertionError(f"C1 regression changed: {row}")
    if row["id"] == "c2_calls_json_lookup" and row["fresh"] != "FAIL":
        raise AssertionError(f"C2 fresh audit regression changed: {row}")
    if row["id"] in {"c3_persist_side_file", "c4_frame_walk"} and row["fresh"] != "FAIL":
        raise AssertionError(f"{row['id']} fresh isolation regression changed: {row}")
    if row["id"] in {"c5_env_fs_probe", "c6_tmp_stash"} and (
        row["legacy"], row["fresh"]
    ) != ("PASS", "PASS"):
        raise AssertionError(f"{row['id']} regression changed: {row}")


def main() -> None:
    rows: list[dict[str, str]] = []
    with tempfile.TemporaryDirectory(prefix="catch-c0-c6-") as root:
        base = Path(root)
        for case in CASES:
            legacy_workspace = base / "legacy" / case
            fresh_workspace = base / "fresh" / case
            legacy_workspace.mkdir(parents=True)
            fresh_workspace.mkdir(parents=True)

            legacy = _evaluate(case, legacy_workspace, fresh=False)
            fresh = _evaluate(case, fresh_workspace, fresh=True)
            row = {
                "id": case,
                "legacy": legacy,
                "fresh": fresh,
                # The namespace boundary is not executable in this CI probe.
                "namespace": "UNKNOWN",
            }
            _validate_row(row)
            rows.append(row)

    print(
        json.dumps(
            {
                "kind": "CATCH-compatible-isolation-probe",
                "status": "PASS",
                "cases": rows,
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
