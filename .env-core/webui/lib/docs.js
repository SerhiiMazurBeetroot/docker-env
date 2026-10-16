import fs from "fs";
import path from "path";

const MEDIA_EXT = new Set([".gif", ".jpg", ".jpeg", ".png", ".webp", ".svg"]);

const ROOT_ORDER = ["README.md", "getting-started.md", "web-ui.md", "system.md", "troubleshooting.md"];

function envDir() {
	return process.env.ENV_DIR || process.env.DOCKER_ENV_DIR || path.resolve(process.cwd(), "../..");
}

export function docsRoot() {
	return path.join(envDir(), ".env-core", "docs");
}

function insideRoot(root, candidate) {
	const rel = path.relative(root, candidate);
	return rel === "" || (!rel.startsWith("..") && !path.isAbsolute(rel));
}

function escapeHtml(value) {
	return String(value)
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;");
}

export function slugFromRel(relPath) {
	const normalized = relPath.split(path.sep).join("/");
	const parts = normalized.replace(/\.md$/i, "").split("/");
	if (parts[parts.length - 1].toLowerCase() === "readme") {
		parts.pop();
	}
	return parts.filter(Boolean).join("/");
}

export function relFromSlug(slug) {
	const clean = String(slug || "")
		.split("/")
		.filter((part) => part && part !== "." && part !== "..")
		.join("/");
	if (!clean) {
		return "README.md";
	}
	const root = docsRoot();
	const asFile = path.join(root, `${clean}.md`);
	if (fs.existsSync(asFile)) {
		return path.relative(root, asFile);
	}
	const asReadme = path.join(root, clean, "README.md");
	if (fs.existsSync(asReadme)) {
		return path.relative(root, asReadme);
	}
	return null;
}

function titleFromMarkdown(source, fallback) {
	const match = source.match(/^#\s+(.+)$/m);
	return match ? match[1].trim() : fallback;
}

function walkMarkdown(dir, root, out) {
	if (!fs.existsSync(dir)) {
		return;
	}
	for (const name of fs.readdirSync(dir)) {
		if (name.startsWith(".")) {
			continue;
		}
		const full = path.join(dir, name);
		const stat = fs.statSync(full);
		if (stat.isDirectory()) {
			walkMarkdown(full, root, out);
			continue;
		}
		if (stat.isFile() && name.toLowerCase().endsWith(".md")) {
			const rel = path.relative(root, full);
			const source = fs.readFileSync(full, "utf8");
			out.push({
				rel: rel.split(path.sep).join("/"),
				slug: slugFromRel(rel),
				title: titleFromMarkdown(source, name.replace(/\.md$/i, "")),
			});
		}
	}
}

export function isDeveloperDoc(slug) {
	return slug === "dev" || String(slug || "").startsWith("dev/");
}

const WIP_PROJECT_SLUGS = new Set([
	"projects/laravel",
	"projects/directus-nextjs",
	"projects/wordpress-nextjs",
	"projects/nodejs-api",
]);

export function isWipProjectDoc(slug) {
	return WIP_PROJECT_SLUGS.has(String(slug || ""));
}

export function isDeveloperSection(slug) {
	return isDeveloperDoc(slug) || isWipProjectDoc(slug);
}

export function isDevelopmentMode() {
	try {
		const file = path.join(envDir(), ".env-core", "data", "settings.log");
		const text = fs.readFileSync(file, "utf8");
		const line = text.split(/\r?\n/).find((row) => row.startsWith("ENV_MODE="));
		if (!line) {
			return false;
		}
		let value = line.slice("ENV_MODE=".length).trim();
		if ((value.startsWith("'") && value.endsWith("'")) || (value.startsWith('"') && value.endsWith('"'))) {
			value = value.slice(1, -1);
		}
		return value === "development";
	} catch {
		return false;
	}
}

export function listDocs(audience = "user") {
	const root = docsRoot();
	const pages = [];
	walkMarkdown(root, root, pages);

	const byRel = new Map(pages.map((page) => [page.rel, page]));
	const rootPages = ROOT_ORDER.map((name) => byRel.get(name)).filter(Boolean);
	const extraRoot = pages
		.filter((page) => !page.rel.includes("/") && !ROOT_ORDER.includes(page.rel))
		.sort((a, b) => a.title.localeCompare(b.title));
	const projects = pages
		.filter((page) => page.rel.startsWith("projects/"))
		.sort((a, b) => a.title.localeCompare(b.title));
	const dev = pages
		.filter((page) => page.rel.startsWith("dev/"))
		.sort((a, b) => {
			if (a.slug === "dev") {
				return -1;
			}
			if (b.slug === "dev") {
				return 1;
			}
			return a.title.localeCompare(b.title);
		});

	const wipProjects = projects.filter((page) => isWipProjectDoc(page.slug));
	const stableProjects = projects.filter((page) => !isWipProjectDoc(page.slug));

	if (audience === "developer") {
		return [
			{ id: "dev", title: "Developer guide", pages: dev },
			{ id: "wip", title: "WIP projects", pages: wipProjects },
		].filter((group) => group.pages.length > 0);
	}

	return [
		{ id: "use", title: "Guides", pages: [...rootPages, ...extraRoot] },
		{ id: "projects", title: "Projects", pages: stableProjects },
	].filter((group) => group.pages.length > 0);
}

function hrefForMarkdown(url, fileDir, root) {
	if (/^https?:\/\//i.test(url)) {
		return url;
	}
	if (url.startsWith("#")) {
		return url;
	}
	const [pathPart, hash = ""] = url.split("#");
	if (!pathPart || !/\.md$/i.test(pathPart)) {
		return null;
	}
	const abs = path.resolve(fileDir, pathPart);
	if (!insideRoot(root, abs) || !fs.existsSync(abs)) {
		return null;
	}
	const slug = slugFromRel(path.relative(root, abs));
	const hashPart = hash ? `#${encodeURIComponent(hash)}` : "";
	return `/docs${slug ? `/${slug}` : ""}${hashPart}`;
}

function srcForMedia(url, fileDir, root) {
	if (/^https?:\/\//i.test(url)) {
		return url;
	}
	const abs = path.resolve(fileDir, url.split("#")[0].split("?")[0]);
	if (!insideRoot(root, abs)) {
		return null;
	}
	const ext = path.extname(abs).toLowerCase();
	if (!MEDIA_EXT.has(ext) || !fs.existsSync(abs)) {
		return null;
	}
	const rel = path.relative(root, abs).split(path.sep).join("/");
	return `/docs/media/${rel.split("/").map(encodeURIComponent).join("/")}`;
}

function inline(text, ctx) {
	let source = text;
	const slots = [];
	const stash = (html) => {
		const token = `\u0000${slots.length}\u0000`;
		slots.push(html);
		return token;
	};

	source = source.replace(/`([^`]+)`/g, (_, code) => stash(`<code>${escapeHtml(code)}</code>`));
	source = source.replace(/!\[([^\]]*)\]\(([^)\s]+)\)/g, (match, alt, url) => {
		const src = srcForMedia(url, ctx.fileDir, ctx.root);
		if (!src) {
			return escapeHtml(match);
		}
		return stash(`<img src="${escapeHtml(src)}" alt="${escapeHtml(alt)}" />`);
	});
	source = source.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (match, label, url) => {
		const href = hrefForMarkdown(url, ctx.fileDir, ctx.root);
		if (!href) {
			if (/^https?:\/\//i.test(url)) {
				return stash(
					`<a href="${escapeHtml(url)}" target="_blank" rel="noreferrer">${inline(label, ctx)}</a>`,
				);
			}
			return escapeHtml(label);
		}
		return stash(`<a href="${escapeHtml(href)}">${inline(label, ctx)}</a>`);
	});
	source = source.replace(/\*\*([^*]+)\*\*/g, (_, bold) => stash(`<strong>${inline(bold, ctx)}</strong>`));

	source = escapeHtml(source);
	return source.replace(/\u0000(\d+)\u0000/g, (_, index) => slots[Number(index)] || "");
}

function renderTable(rows, ctx) {
	const head = rows[0].map((cell) => `<th>${inline(cell.trim(), ctx)}</th>`).join("");
	const body = rows
		.slice(1)
		.map((row) => `<tr>${row.map((cell) => `<td>${inline(cell.trim(), ctx)}</td>`).join("")}</tr>`)
		.join("");
	return `<div class="doc-table"><table><thead><tr>${head}</tr></thead><tbody>${body}</tbody></table></div>`;
}

function isTableSep(line) {
	return /^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$/.test(line);
}

function splitRow(line) {
	let value = line.trim();
	if (value.startsWith("|")) {
		value = value.slice(1);
	}
	if (value.endsWith("|")) {
		value = value.slice(0, -1);
	}
	return value.split("|");
}

export function renderMarkdown(source, fileDir) {
	const root = docsRoot();
	const ctx = { fileDir, root };
	const lines = String(source).replace(/\r\n/g, "\n").split("\n");
	const html = [];
	let i = 0;

	while (i < lines.length) {
		const line = lines[i];

		if (line.startsWith("```")) {
			const lang = line.slice(3).trim();
			const buf = [];
			i += 1;
			while (i < lines.length && !lines[i].startsWith("```")) {
				buf.push(lines[i]);
				i += 1;
			}
			i += 1;
			const className = lang ? ` class="lang-${escapeHtml(lang)}"` : "";
			html.push(`<pre${className}><code>${escapeHtml(buf.join("\n"))}</code></pre>`);
			continue;
		}

		if (!line.trim()) {
			i += 1;
			continue;
		}

		const heading = /^(#{1,3})\s+(.+)$/.exec(line);
		if (heading) {
			const level = heading[1].length;
			const id = heading[2]
				.toLowerCase()
				.replace(/[^\w\s-]/g, "")
				.trim()
				.replace(/\s+/g, "-");
			html.push(`<h${level} id="${escapeHtml(id)}">${inline(heading[2], ctx)}</h${level}>`);
			i += 1;
			continue;
		}

		if (line.includes("|") && i + 1 < lines.length && isTableSep(lines[i + 1])) {
			const rows = [splitRow(line)];
			i += 2;
			while (i < lines.length && lines[i].includes("|") && lines[i].trim()) {
				rows.push(splitRow(lines[i]));
				i += 1;
			}
			html.push(renderTable(rows, ctx));
			continue;
		}

		if (/^[-*]\s+/.test(line)) {
			const items = [];
			while (i < lines.length && /^[-*]\s+/.test(lines[i])) {
				items.push(`<li>${inline(lines[i].replace(/^[-*]\s+/, ""), ctx)}</li>`);
				i += 1;
			}
			html.push(`<ul>${items.join("")}</ul>`);
			continue;
		}

		if (/^\d+\.\s+/.test(line)) {
			const items = [];
			while (i < lines.length && /^\d+\.\s+/.test(lines[i])) {
				items.push(`<li>${inline(lines[i].replace(/^\d+\.\s+/, ""), ctx)}</li>`);
				i += 1;
			}
			html.push(`<ol>${items.join("")}</ol>`);
			continue;
		}

		const para = [];
		while (
			i < lines.length &&
			lines[i].trim() &&
			!lines[i].startsWith("```") &&
			!/^(#{1,3})\s+/.test(lines[i]) &&
			!/^[-*]\s+/.test(lines[i]) &&
			!/^\d+\.\s+/.test(lines[i])
		) {
			if (lines[i].includes("|") && i + 1 < lines.length && isTableSep(lines[i + 1])) {
				break;
			}
			para.push(lines[i]);
			i += 1;
		}
		html.push(`<p>${inline(para.join(" "), ctx)}</p>`);
	}

	return html.join("\n");
}

export function readDoc(slug) {
	const rel = relFromSlug(slug);
	if (!rel) {
		return null;
	}
	const root = docsRoot();
	const full = path.resolve(root, rel);
	if (!insideRoot(root, full) || !fs.existsSync(full)) {
		return null;
	}
	const source = fs.readFileSync(full, "utf8");
	return {
		slug: slugFromRel(rel),
		title: titleFromMarkdown(source, path.basename(rel, ".md")),
		html: renderMarkdown(source, path.dirname(full)),
	};
}

export function mediaFile(parts) {
	const root = docsRoot();
	const rel = parts.map((part) => decodeURIComponent(part)).join("/");
	if (!rel || rel.includes("\0")) {
		return null;
	}
	const full = path.resolve(root, rel);
	if (!insideRoot(root, full) || !fs.existsSync(full) || !fs.statSync(full).isFile()) {
		return null;
	}
	const ext = path.extname(full).toLowerCase();
	if (!MEDIA_EXT.has(ext)) {
		return null;
	}
	return full;
}

export function mediaType(filePath) {
	switch (path.extname(filePath).toLowerCase()) {
		case ".gif":
			return "image/gif";
		case ".jpg":
		case ".jpeg":
			return "image/jpeg";
		case ".png":
			return "image/png";
		case ".webp":
			return "image/webp";
		case ".svg":
			return "image/svg+xml";
		default:
			return "application/octet-stream";
	}
}
