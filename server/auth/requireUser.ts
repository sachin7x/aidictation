import { createAuthClient } from "./supabase.js";

export interface AuthenticatedUser { id:string; email?:string; }

export async function requireUser(authorization:string|undefined):Promise<AuthenticatedUser> {
  if (!authorization?.startsWith("Bearer ")) throw new Error("UNAUTHENTICATED");
  const token=authorization.slice("Bearer ".length).trim();
  if(!token) throw new Error("UNAUTHENTICATED");
  const {data,error}=await createAuthClient().auth.getUser(token);
  if(error || !data.user) throw new Error("UNAUTHENTICATED");
  return {id:data.user.id,email:data.user.email};
}
