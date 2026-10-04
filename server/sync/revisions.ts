export interface RevisionedEntity { id:string; version:number; updatedAt:string; deviceId:string; }

export type SyncDecision<T> =
  | {kind:"accept";entity:T}
  | {kind:"conflict";authoritative:T};

export function decideWrite<T extends RevisionedEntity>(incoming:T,current:T|undefined):SyncDecision<T> {
  if(!current) return {kind:"accept",entity:incoming};
  if(incoming.version<current.version) return {kind:"conflict",authoritative:current};
  if(incoming.version===current.version && incoming.updatedAt<=current.updatedAt) return {kind:"conflict",authoritative:current};
  return {kind:"accept",entity:incoming};
}
