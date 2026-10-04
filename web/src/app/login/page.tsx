"use client";

import Link from "next/link";
import { FormEvent, useState } from "react";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setMessage("");
    try {
      const supabase = createSupabaseBrowserClient();
      const { error } = await supabase.auth.signInWithOtp({
        email,
        options: { emailRedirectTo: `${window.location.origin}/auth/callback` },
      });
      if (error) throw error;
      setMessage("Check your email for a secure sign-in link.");
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Unable to send sign-in link.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="container section">
      <Link href="/">← Home</Link>
      <h1>Sign in</h1>
      <form className="card" style={{ maxWidth: 520, marginTop: 30 }} onSubmit={submit}>
        <label>
          Email
          <input value={email} onChange={(e) => setEmail(e.target.value)} name="email" type="email" autoComplete="email" required style={{ display: "block", width: "100%", padding: 12, margin: "8px 0 18px" }} />
        </label>
        <button className="primary" type="submit" disabled={busy}>{busy ? "Sending…" : "Email me a sign-in link"}</button>
        {message && <p aria-live="polite">{message}</p>}
        <p>New here? <Link href="/signup" className="textLink">Create an account</Link>.</p>
      </form>
    </main>
  );
}
