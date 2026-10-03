export interface EntitlementSource { key:string; value:unknown; source:string; validUntil?:string|null; }

export function hasEntitlement(entitlements:EntitlementSource[],key:string,now=new Date()):boolean {
  const item=entitlements.find(x=>x.key===key);
  if(!item) return false;
  if(item.validUntil && new Date(item.validUntil)<=now) return false;
  return item.value===true || item.value==="true" || item.value===1;
}

export function requireEntitlement(entitlements:EntitlementSource[],key:string):void {
  if(!hasEntitlement(entitlements,key)) throw new Error("ENTITLEMENT_REQUIRED:"+key);
}
