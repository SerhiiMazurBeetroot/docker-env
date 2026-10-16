import { spawn } from "child_process";
import { decorateList, recordDiagnostic } from "../diagnostics.js";
import {
	hostsStatusFor,
	hostTokenSet,
	listProjectsFast,
	loadHostsText,
	readInstanceSites,
	urlsForProject,
} from "../listSnapshot";
import { freshSnapshot, rememberSnapshot } from "./cache.js";
import { extractJson, runCli } from "./run.js";

let listChain = Promise.resolve();

function enqueueList() {
	const task = listChain.then(listProjectsOnce, listProjectsOnce);
	listChain = task.then(
		() => undefined,
		() => undefined
	);
	return task;
}

async function listProjectsOnce() {
	try {
		const fast = await listProjectsFast();
		if (fast.body?.ok && Array.isArray(fast.body.projects)) {
			return { status: 200, body: { ok: true, ...fast.body, partial: false } };
		}
	} catch (err) {
		// fall through to CLI list
	}

	const result = await runCli(["list"]);
	const data = extractJson(result.stdout);

	if (data && Array.isArray(data.projects)) {
		return { status: 200, body: { ok: true, ...data, partial: false } };
	}

	const log = `${result.stdout}\n${result.stderr}`.trim();
	recordDiagnostic({
		source: "webui",
		action: "list",
		message: "Could not list projects",
		detail: log,
	});
	return {
		status: 500,
		body: {
			ok: false,
			error: "Could not list projects",
			log,
			code: result.code,
		},
	};
}

export async function listProjects({ force = false } = {}) {
	let result;
	const cached = force ? null : freshSnapshot();
	if (cached) {
		result = { status: 200, body: cached };
	} else {
		result = await enqueueList();
		if (!result.body?.ok) {
			await new Promise((resolve) => setTimeout(resolve, 400));
			result = await enqueueList();
		}
		if (result.body?.ok) rememberSnapshot(result.body);
	}
	if (result.body?.ok) {
		return { status: result.status, body: decorateList(result.body) };
	}
	return result;
}

function dockerNames(args) {
	return new Promise((resolve) => {
		const child = spawn("docker", args, { env: process.env });
		let out = "";
		const timer = setTimeout(() => {
			child.kill("SIGKILL");
			resolve([]);
		}, 4000);
		child.stdout.on("data", (chunk) => {
			out += chunk.toString();
		});
		child.on("error", () => {
			clearTimeout(timer);
			resolve([]);
		});
		child.on("close", () => {
			clearTimeout(timer);
			resolve(
				out
					.split("\n")
					.map((line) => line.trim())
					.filter(Boolean)
			);
		});
	});
}

function projectLooksRunning(names, domain) {
	const prefix = `${domain}-`;
	return names.some((name) => name === domain || name.startsWith(prefix));
}

function liteSystemService(id, name, container, urls, actions, names) {
	const running = names.includes(container);
	return {
		id,
		name,
		container,
		running,
		state: running ? "running" : "missing",
		health: "",
		status: "",
		urls,
		actions,
	};
}

export async function listProjectsLite() {
	const names = await dockerNames(["ps", "--format", "{{.Names}}"]);
	const hosts = await loadHostsText();
	const tokens = hostTokenSet(hosts.text);
	const webuiHost =
		process.env.WEBUI_HOST && process.env.WEBUI_HOST !== "0.0.0.0" ? process.env.WEBUI_HOST : "127.0.0.1";
	const webuiUrl = `http://${webuiHost}:${process.env.WEBUI_PORT || "7777"}`;
	const systemActions = ["start", "stop", "restart"];

	const projects = readInstanceSites().map((row) => {
		const urls = urlsForProject(row.type, row.domainFull);
		const url = row.domainFull ? `https://${row.domainFull}` : "";
		return {
			domain: row.domain,
			status: row.status,
			type: row.type,
			domainFull: row.domainFull,
			running: projectLooksRunning(names, row.domain),
			url,
			urls,
			services: [],
			hosts: hostsStatusFor(row.type, row.domainFull, tokens, hosts.ok),
			partial: true,
		};
	});

	return {
		status: 200,
		body: decorateList({
			ok: true,
			partial: true,
			projects,
			system: [
				liteSystemService("nginx", "Nginx", "nginx-proxy", [], systemActions, names),
				liteSystemService(
					"dozzle",
					"Dozzle",
					"nginx-dozzle",
					[{ key: "UI", url: "http://127.0.0.1:7007" }],
					systemActions,
					names
				),
				liteSystemService(
					"webui",
					"Web UI",
					process.env.WEBUI_CONTAINER || "nginx-webui",
					[{ key: "UI", url: webuiUrl }],
					[],
					names
				),
			],
		}),
	};
}
