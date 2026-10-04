export type Platform = "macos" | "windows" | "ios" | "android" | "web";
export interface Revision { version:number; updatedAt:string; deviceId:string; }
export interface DictionaryEntry extends Revision { id:string; trigger:string; replacement?:string; pronunciationHint?:string; category?:string; isEnabled:boolean; }
export interface Snippet extends Revision { id:string; trigger:string; expansion:string; category?:string; variables:string[]; isEnabled:boolean; }
export interface Style extends Revision { id:string; name:string; description:string; capitalization:string; punctuation:string; verbosity:string; tone:string; customInstructions:string; }
export interface SyncCursor { revision:number; }
export interface SyncChange { revision:number; entityType:"dictionary"|"snippet"|"style"|"device"; entityId:string; operation:"upsert"|"delete"; version:number; payload?:unknown; }
export interface Entitlement { key:string; value:unknown; source:"subscription"|"admin"|"promo"|"appsumo"; validUntil?:string; }
export interface VerificationResult { passed:boolean; evidence:string[]; violations:string[]; metadata:Record<string,unknown>; }
export interface VerifierContract<A,E,S> { verify(action:A,expectedOutcome:E,observedState:S):Promise<VerificationResult>|VerificationResult; }
