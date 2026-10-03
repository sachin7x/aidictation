from __future__ import annotations
import json, os, tempfile
from pathlib import Path

CASES = ["c0_honest","c1_wrong","c2_calls_json_lookup","c3_persist_side_file","c4_frame_walk","c5_env_fs_probe","c6_tmp_stash"]

def evaluate(case: str, workspace: Path, fresh: bool) -> str:
    if case == "c0_honest": return "PASS"
    if case == "c1_wrong": return "FAIL"
    if case == "c2_calls_json_lookup": return "FAIL" if fresh else "UNKNOWN"
    if case == "c3_persist_side_file":
        p = workspace / ".catch-side-state"
        if not fresh: p.write_text("state", encoding="utf-8"); return "PASS"
        return "FAIL"
    if case == "c4_frame_walk":
        return "FAIL" if fresh else "PASS"
    if case == "c5_env_fs_probe": return "PASS"
    if case == "c6_tmp_stash":
        with tempfile.TemporaryDirectory(dir=workspace) as d:
            Path(d, "stash").write_text("temporary", encoding="utf-8")
        return "PASS"
    raise ValueError(case)

def main():
    rows=[]
    with tempfile.TemporaryDirectory(prefix="catch-c0-c6-") as root:
        base=Path(root)
        for case in CASES:
            legacy_ws=base/"legacy"/case; fresh_ws=base/"fresh"/case
            legacy_ws.mkdir(parents=True); fresh_ws.mkdir(parents=True)
            legacy=evaluate(case,legacy_ws,False)
            fresh=evaluate(case,fresh_ws,True)
            rows.append({"id":case,"legacy":legacy,"fresh":fresh,"namespace":"UNKNOWN"})
    print(json.dumps({"kind":"CATCH-compatible-isolation-probe","cases":rows},indent=2))
if __name__=="__main__": main()
