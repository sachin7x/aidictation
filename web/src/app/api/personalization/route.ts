import { NextResponse } from "next/server";
import { createSupabaseServerClient } from "@/lib/supabase/server";

const configs = {
  dictionary: { table: "user_dictionary_entries", fields: ["trigger","replacement","pronunciation_hint","category","is_enabled"] },
  snippet: { table: "user_snippets", fields: ["trigger","expansion","category","variables","is_enabled"] },
  style: { table: "user_styles", fields: ["name","description","capitalization","punctuation","verbosity","tone","custom_instructions"] },
} as const;

type EntityType = keyof typeof configs;

function configFor(value: unknown) {
  return configs[String(value) as EntityType] ?? null;
}

function cleanPayload(input: Record<string, unknown>, fields: readonly string[]) {
  return Object.fromEntries(fields.filter((key) => key in input).map((key) => [key, input[key]]));
}

async function auth() {
  const s = await createSupabaseServerClient();
  const { data: { user } } = await s.auth.getUser();
  return user ? { s, user } : null;
}

export async function POST(request: Request) {
  const context = await auth();
  if (!context) return NextResponse.json({ error: "UNAUTHENTICATED" }, { status: 401 });
  const body = await request.json();
  const config = configFor(body.entityType);
  if (!config) return NextResponse.json({ error: "UNSUPPORTED_ENTITY" }, { status: 400 });

  const payload = cleanPayload(body.payload ?? {}, config.fields);
  if (Object.keys(payload).length === 0) return NextResponse.json({ error: "PAYLOAD_REQUIRED" }, { status: 400 });

  const { data, error } = await context.s.from(config.table).insert({ ...payload, user_id: context.user.id }).select().single();
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });

  const revision = await context.s.from("sync_revisions").insert({
    user_id: context.user.id,
    device_id: String(body.deviceId || "web"),
    entity_type: body.entityType,
    entity_id: data.id,
    entity_version: data.version ?? 1,
    operation: "upsert",
    payload: data,
  }).select("id").single();

  if (revision.error) return NextResponse.json({ error: "REVISION_WRITE_FAILED" }, { status: 500 });
  return NextResponse.json({ data, cursor: revision.data.id }, { status: 201 });
}

export async function PATCH(request: Request) {
  const context = await auth();
  if (!context) return NextResponse.json({ error: "UNAUTHENTICATED" }, { status: 401 });
  const body = await request.json();
  const config = configFor(body.entityType);
  if (!config || !body.id) return NextResponse.json({ error: "ENTITY_ID_REQUIRED" }, { status: 400 });

  const payload = cleanPayload(body.payload ?? {}, config.fields);
  const { data: current, error: readError } = await context.s.from(config.table).select("version").eq("id", body.id).eq("user_id", context.user.id).maybeSingle();
  if (readError) return NextResponse.json({ error: readError.message }, { status: 400 });
  if (!current) return NextResponse.json({ error: "NOT_FOUND" }, { status: 404 });

  const incomingVersion = Number(body.version ?? Number(current.version) + 1);
  if (incomingVersion <= Number(current.version)) return NextResponse.json({ error: "STALE_WRITE", currentVersion: current.version, incomingVersion }, { status: 409 });

  const { data, error } = await context.s.from(config.table)
    .update({ ...payload, version: incomingVersion, updated_at: new Date().toISOString() })
    .eq("id", body.id).eq("user_id", context.user.id).select().single();

  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  const revision = await context.s.from("sync_revisions").insert({
    user_id: context.user.id, device_id: String(body.deviceId || "web"), entity_type: body.entityType,
    entity_id: data.id, entity_version: data.version, operation: "upsert", payload: data,
  }).select("id").single();
  if (revision.error) return NextResponse.json({ error: "REVISION_WRITE_FAILED" }, { status: 500 });
  return NextResponse.json({ data, cursor: revision.data.id });
}

export async function DELETE(request: Request) {
  const context = await auth();
  if (!context) return NextResponse.json({ error: "UNAUTHENTICATED" }, { status: 401 });
  const url = new URL(request.url);
  const entityType = url.searchParams.get("entityType");
  const id = url.searchParams.get("id");
  const config = configFor(entityType);
  if (!config || !id) return NextResponse.json({ error: "ENTITY_ID_REQUIRED" }, { status: 400 });

  const { data: current } = await context.s.from(config.table).select("version").eq("id", id).eq("user_id", context.user.id).maybeSingle();
  if (!current) return NextResponse.json({ error: "NOT_FOUND" }, { status: 404 });
  const { error } = await context.s.from(config.table).delete().eq("id", id).eq("user_id", context.user.id);
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });

  const revision = await context.s.from("sync_revisions").insert({
    user_id: context.user.id, device_id: "web", entity_type: entityType, entity_id: id,
    entity_version: Number(current.version) + 1, operation: "delete", payload: null,
  }).select("id").single();
  if (revision.error) return NextResponse.json({ error: "REVISION_WRITE_FAILED" }, { status: 500 });
  return NextResponse.json({ deleted: id, cursor: revision.data.id });
}
