import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

type Style = { id?: string; name: string; description: string; is_enabled?: boolean };

const defaults: Style[] = [
  { name: "Formal", description: "Clear capitalization and standard punctuation." },
  { name: "Casual", description: "Relaxed capitalization with lighter punctuation." },
  { name: "Very casual", description: "Personal, conversational writing with minimal punctuation." },
  { name: "Excited!", description: "More energetic punctuation for work and email." },
];

export default async function Styles() {
  const s = await createSupabaseServerClient();
  const { data: { user } } = await s.auth.getUser();
  if (!user) redirect("/login");
  const { data: rows } = await s.from("user_styles").select("id,name,description,is_enabled").order("updated_at", { ascending: false });
  const styles: Style[] = rows?.length ? rows : defaults;
  return <main className="dashboard"><header className="dashNav"><a href="/dashboard" className="brand">AI Dictation</a><a href="/dashboard" className="textLink">← Workspace</a></header><section className="section"><span className="eyebrow">Personalization</span><h1>Styles</h1><p>Choose how your writing is capitalized and punctuated for different contexts.</p><div className="grid">{styles.map((style) => <article className="card" key={style.id ?? style.name}><h3>{style.name}</h3><p>{style.description}</p><span>{style.is_enabled === false ? "Disabled" : "Available"}</span></article>)}</div></section></main>;
}