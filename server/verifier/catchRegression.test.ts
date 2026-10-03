import test from "node:test";
import assert from "node:assert/strict";
import { catchRegressionCorpus } from "../../packages/contracts/src/catch.js";

test("CATCH corpus never treats UNKNOWN as a passing verification state",()=>{
  for(const item of catchRegressionCorpus){
    if(item.namespace==="UNKNOWN") assert.notEqual(item.namespace,"PASS");
  }
});

test("C0 and C1 preserve deterministic controls",()=>{
  const c0=catchRegressionCorpus.find(x=>x.id==="c0_honest")!;
  const c1=catchRegressionCorpus.find(x=>x.id==="c1_wrong")!;
  assert.deepEqual([c0.legacy,c0.fresh],["PASS","PASS"]);
  assert.deepEqual([c1.legacy,c1.fresh],["FAIL","FAIL"]);
});

test("C3 and C4 preserve fresh-workspace failure",()=>{
  for(const id of ["c3_persist_side_file","c4_frame_walk"]){
    const item=catchRegressionCorpus.find(x=>x.id===id)!;
    assert.equal(item.fresh,"FAIL");
  }
});
