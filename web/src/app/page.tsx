import Link from "next/link";
import { brand } from "@/config/brand";

const features=[["Voice typing","Speak naturally and turn your thoughts into usable text across your workflow."],["Personal context","Shape output with vocabulary, replacements, snippets, and writing styles."],["Transforms","Refine selected text with recoverable rewrite, polish, summarize, and tone operations."],["Command mode","Separate spoken commands from ordinary dictation with an explicit action boundary."],["Meetings","Capture meetings, transcripts, summaries, decisions, and action items."],["Privacy controls","Make cloud processing, retention, analytics, and diagnostics explicit product settings."]];

export default function Home(){
 return <>
  <header className="container nav"><Link className="brand" href="/">{brand.name}</Link><nav className="navLinks"><Link href="/features">Features</Link><Link href="/developers">Developers</Link><Link href="/pricing">Pricing</Link><Link href="/download">Download</Link><Link className="pill" href="/login">Sign in</Link></nav></header>
  <main>
   <section className="container hero"><span className="eyebrow">Cross-platform voice productivity</span><h1>{brand.tagline}</h1><p>{brand.description}</p><div className="actions"><Link className="primary" href="/download">Download</Link><Link className="secondary" href="/features">Explore features</Link></div><div className="demo"><div className="demoInner"><div><strong>Voice interaction preview</strong><p>Replace this surface with the product demo when the media pipeline is connected.</p></div></div></div></section>
   <section className="section"><div className="container"><h2>Built around the way you work.</h2><p className="sectionLead">A single product surface for dictation, personal language controls, text refinement, commands, meetings, and synchronized preferences.</p><div className="grid">{features.map(([title,copy])=><article className="card" key={title}><h3>{title}</h3><p>{copy}</p></article>)}</div></div></section>
   <section className="section"><div className="container"><h2>One foundation. Every device.</h2><p className="sectionLead">Preserve the existing native applications while adding a web control plane and shared contracts instead of replacing working device integrations.</p><div className="actions" style={{justifyContent:"flex-start"}}><Link className="secondary" href="/download">Mac · Windows · iPhone · Android</Link><Link className="secondary" href="/developers">Developer platform</Link></div></div></section>
  </main>
  <footer className="footer"><div className="container"><strong>{brand.name}</strong><p>Original implementation with replaceable product identity and assets.</p></div></footer>
 </>;
}
