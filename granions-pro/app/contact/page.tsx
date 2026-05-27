"use client";

import { useState } from "react";

export default function ContactPage() {
  const [submitted, setSubmitted] = useState(false);
  const [form, setForm] = useState({
    name: "",
    email: "",
    subject: "Demande d'information",
    message: "",
  });

  function update<K extends keyof typeof form>(k: K, v: string) {
    setForm((f) => ({ ...f, [k]: v }));
  }

  function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitted(true);
  }

  return (
    <div className="mx-auto max-w-5xl px-4 py-12">
      <h1 className="text-2xl font-bold text-slate-800">Contact</h1>
      <p className="mt-1 text-sm text-slate-600">
        Notre équipe vous répond sous 48h ouvrées.
      </p>

      <div className="mt-10 grid gap-10 md:grid-cols-[1fr_320px]">
        <form onSubmit={onSubmit} className="grid gap-5 sm:grid-cols-2">
          <label className="block">
            <span className="block text-sm font-medium text-slate-700">Nom</span>
            <input
              required
              value={form.name}
              onChange={(e) => update("name", e.target.value)}
              className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2"
            />
          </label>
          <label className="block">
            <span className="block text-sm font-medium text-slate-700">Email</span>
            <input
              type="email"
              required
              value={form.email}
              onChange={(e) => update("email", e.target.value)}
              className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2"
            />
          </label>
          <label className="block sm:col-span-2">
            <span className="block text-sm font-medium text-slate-700">Sujet</span>
            <select
              value={form.subject}
              onChange={(e) => update("subject", e.target.value)}
              className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2"
            >
              <option>Demande d'information</option>
              <option>Question commerciale</option>
              <option>Formation</option>
              <option>Réclamation produit</option>
              <option>Autre</option>
            </select>
          </label>
          <label className="block sm:col-span-2">
            <span className="block text-sm font-medium text-slate-700">Message</span>
            <textarea
              required
              rows={6}
              value={form.message}
              onChange={(e) => update("message", e.target.value)}
              className="mt-1 w-full rounded-md border border-slate-300 px-3 py-2"
            />
          </label>
          <div className="sm:col-span-2">
            <button
              type="submit"
              className="rounded-md bg-brand-600 px-5 py-2.5 font-medium text-white hover:bg-brand-700"
            >
              Envoyer
            </button>
            {submitted && (
              <p className="mt-3 text-sm text-brand-700">
                Merci, votre message a bien été pris en compte (démo).
              </p>
            )}
          </div>
        </form>

        <aside className="rounded-xl border border-slate-200 bg-slate-50 p-6 text-sm">
          <h2 className="font-semibold text-slate-800">Service Pro</h2>
          <p className="mt-2 text-slate-600">Du lundi au vendredi, 9h–18h.</p>
          <ul className="mt-4 space-y-2 text-slate-700">
            <li>Téléphone : <span className="font-medium">01 00 00 00 00</span></li>
            <li>Email : <span className="font-medium">pro@granions.example</span></li>
          </ul>
          <h3 className="mt-6 font-semibold text-slate-800">Votre délégué</h3>
          <p className="mt-2 text-slate-600">
            Connectez-vous à votre espace pour retrouver les coordonnées de votre délégué régional.
          </p>
        </aside>
      </div>
    </div>
  );
}
