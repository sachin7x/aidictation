import { createClient } from "@supabase/supabase-js";
import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const XAI_CLIENT_SECRETS_URL = "https://api.x.ai/v1/realtime/client_secrets";
const EPHEMERAL_TOKEN_LIFETIME_SECONDS = 300;

function jsonError(error: string, status: number, retryAfter?: string) {
  const headers: Record<string, string> = {
    "Cache-Control": "no-store, max-age=0",
  };
  if (retryAfter) headers["Retry-After"] = retryAfter;
  return NextResponse.json({ error }, { status, headers });
}

export async function POST(request: Request) {
  const authorization = request.headers.get("authorization") ?? "";
  const accessToken = authorization.startsWith("Bearer ")
    ? authorization.slice("Bearer ".length).trim()
    : "";

  if (!accessToken) return jsonError("UNAUTHENTICATED", 401);

  const supabaseURL = process.env.SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_ANON_KEY ?? process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!supabaseURL || !supabaseKey) {
    return jsonError("AUTH_PROVIDER_NOT_CONFIGURED", 503);
  }

  const supabase = createClient(supabaseURL, supabaseKey, {
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: { user }, error: authError } = await supabase.auth.getUser(accessToken);
  if (authError || !user) return jsonError("UNAUTHENTICATED", 401);

  const xaiAPIKey = process.env.XAI_API_KEY;
  if (!xaiAPIKey) return jsonError("XAI_VOICE_NOT_CONFIGURED", 503);

  // Reserve a per-user issuance slot in Postgres before calling xAI. This keeps
  // token minting bounded across serverless instances, not just within one process.
  const { error: rateLimitError } = await supabase.rpc("reserve_xai_voice_session_issuance");
  if (rateLimitError) {
    if (rateLimitError.message.includes("RATE_LIMITED")) {
      return jsonError("RATE_LIMITED", 429, "60");
    }
    return jsonError("VOICE_SESSION_GUARD_UNAVAILABLE", 503);
  }

  let upstream: Response;
  try {
    upstream = await fetch(XAI_CLIENT_SECRETS_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${xaiAPIKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        expires_after: { seconds: EPHEMERAL_TOKEN_LIFETIME_SECONDS },
      }),
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    return jsonError("XAI_VOICE_UNAVAILABLE", 502);
  }

  if (!upstream.ok) return jsonError("XAI_VOICE_UPSTREAM_REJECTED", 502);

  let payload: unknown;
  try {
    payload = await upstream.json();
  } catch {
    return jsonError("XAI_VOICE_INVALID_RESPONSE", 502);
  }

  const secret = (payload as { client_secret?: { value?: unknown } } | null)?.client_secret?.value;
  if (typeof secret !== "string" || secret.length < 16) {
    return jsonError("XAI_VOICE_INVALID_RESPONSE", 502);
  }

  // The short-lived secret is intentionally returned only to the authenticated
  // caller. Never log it, persist it, or cache this response.
  return NextResponse.json(payload, {
    headers: {
      "Cache-Control": "no-store, max-age=0",
      Pragma: "no-cache",
    },
  });
}
