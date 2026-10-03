import test from "node:test";
import assert from "node:assert/strict";
import {decideWrite} from "./revisions.js";

test("new entity is accepted",()=>assert.equal(decideWrite({id:"1",version:1,updatedAt:"2026-01-01T00:00:00Z",deviceId:"a"}).kind,"accept"));
test("older version is rejected",()=>assert.equal(decideWrite({id:"1",version:1,updatedAt:"2026-01-01T00:00:00Z",deviceId:"a"},{id:"1",version:2,updatedAt:"2026-01-02T00:00:00Z",deviceId:"b"}).kind,"conflict"));
test("newer version is accepted",()=>assert.equal(decideWrite({id:"1",version:3,updatedAt:"2026-01-03T00:00:00Z",deviceId:"a"},{id:"1",version:2,updatedAt:"2026-01-02T00:00:00Z",deviceId:"b"}).kind,"accept"));
