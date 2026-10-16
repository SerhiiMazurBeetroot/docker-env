"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

export default function LoginPage() {
	const router = useRouter();
	const [from, setFrom] = useState("/");
	const [token, setToken] = useState("");
	const [error, setError] = useState("");
	const [busy, setBusy] = useState(false);

	useEffect(() => {
		const params = new URLSearchParams(window.location.search);
		const next = params.get("from") || "/";
		setFrom(next.startsWith("/login") ? "/" : next);
	}, []);

	async function submit(event) {
		event.preventDefault();
		setBusy(true);
		setError("");
		try {
			const response = await fetch("/api/auth/login", {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({ token: token.trim() }),
			});
			const body = await response.json();
			if (!response.ok || !body.ok) {
				setError(body.error || "Sign in failed");
				return;
			}
			router.replace(from.startsWith("/login") ? "/" : from);
		} catch (err) {
			setError(err.message || "Sign in failed");
		} finally {
			setBusy(false);
		}
	}

	return (
		<div className="flex min-h-screen items-center justify-center px-6">
			<div className="w-full max-w-md rounded-2xl border border-line bg-panel/90 p-6 shadow-lg">
				<h1 className="m-0 text-xl font-bold tracking-tight">docker-env Web UI</h1>
				<p className="mt-2 text-sm text-muted">
					Show the token in the CLI: <strong className="font-semibold text-fg">1 System → 2 Web UI → 4 Show sign-in token</strong>, then paste it here.
				</p>
				<form className="mt-6 space-y-4" onSubmit={submit}>
					<label className="block text-sm font-medium">
						Token
						<input
							type="password"
							autoComplete="off"
							className="mt-1 w-full rounded-lg border border-line bg-bg px-3 py-2 text-sm"
							value={token}
							onChange={(event) => setToken(event.target.value)}
							placeholder="Paste WEBUI_TOKEN"
						/>
					</label>
					{error ? <p className="text-sm text-red-400">{error}</p> : null}
					<button
						type="submit"
						disabled={busy || !token.trim()}
						className="w-full rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
					>
						{busy ? "Signing in…" : "Sign in"}
					</button>
				</form>
			</div>
		</div>
	);
}
