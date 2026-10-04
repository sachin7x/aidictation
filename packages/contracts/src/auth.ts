export interface Session { userId:string; accessToken:string; expiresAt:string; deviceId?:string; }
export interface AuthenticatedRequest { session:Session; requestId:string; }
export type AuthMethod = "password"|"magic_link"|"oauth";
