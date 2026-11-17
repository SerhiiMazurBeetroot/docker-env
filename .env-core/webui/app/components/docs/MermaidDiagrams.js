"use client";

import { useEffect } from "react";

// Draws ```mermaid blocks that lib/docs.js marks with data-mermaid.
// The source <pre> stays in the page (hidden once drawn), so a block that fails to
// parse still shows its text, and a theme change can redraw from the same source.

function mermaidTheme() {
	return document.documentElement.getAttribute("data-theme") === "light" ? "default" : "dark";
}

let renderCount = 0;

async function drawAll(isCancelled) {
	const blocks = Array.from(document.querySelectorAll("pre[data-mermaid]"));
	if (blocks.length === 0) return;

	let mermaid;
	try {
		mermaid = (await import("mermaid")).default;
	} catch (err) {
		return;
	}
	if (isCancelled()) return;

	mermaid.initialize({ startOnLoad: false, securityLevel: "strict", theme: mermaidTheme() });

	for (const block of blocks) {
		if (isCancelled() || !block.isConnected) return;

		const id = `doc-mermaid-${(renderCount += 1)}`;
		try {
			const { svg } = await mermaid.render(id, block.textContent || "");
			if (isCancelled() || !block.isConnected) return;

			let figure = block.nextElementSibling;
			if (!figure || !figure.classList.contains("doc-mermaid")) {
				figure = document.createElement("div");
				figure.className = "doc-mermaid";
				block.after(figure);
			}
			figure.innerHTML = svg;
			block.hidden = true;
		} catch (err) {
			// Leave the source visible. Mermaid can leave its scratch element behind on a parse error.
			document.getElementById(`d${id}`)?.remove();
			block.hidden = false;
		}
	}
}

export default function MermaidDiagrams({ slug }) {
	useEffect(() => {
		let cancelled = false;
		const isCancelled = () => cancelled;

		drawAll(isCancelled);

		const observer = new MutationObserver(() => drawAll(isCancelled));
		observer.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });

		return () => {
			cancelled = true;
			observer.disconnect();
		};
	}, [slug]);

	return null;
}
