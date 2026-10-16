import path from "path";
import { spawn } from "child_process";
import { ACTION_TIMEOUT_MS, envDir } from "./shared.js";

function cliPath() {
	return path.join(envDir(), ".env-core/webui/webui_cli.sh");
}

export function extractUrls(text) {
	const match = String(text || "").match(/WEBUI_URLS_JSON:(\[.*\])/m);
	if (!match) return [];
	try {
		const parsed = JSON.parse(match[1]);
		return Array.isArray(parsed) ? parsed : [];
	} catch (err) {
		return [];
	}
}

export function stripUrlMarker(text) {
	return String(text || "").replace(/^[ \t]*WEBUI_URLS_JSON:.*$/m, "");
}

export function extractJson(text) {
	const trimmed = (text || "").trim();
	if (!trimmed) return null;

	try {
		return JSON.parse(trimmed);
	} catch (err) {
		const start = trimmed.indexOf("{");
		const end = trimmed.lastIndexOf("}");
		if (start >= 0 && end > start) {
			try {
				return JSON.parse(trimmed.slice(start, end + 1));
			} catch (inner) {
				return null;
			}
		}
		return null;
	}
}

function spawnCli(args) {
	const cwd = envDir();
	const env = {
		...process.env,
		ENV_DIR: cwd,
		DOCKER_ENV_DIR: cwd,
	};
	const cli = cliPath();

	if (process.platform === "linux") {
		return spawn("stdbuf", ["-oL", "-eL", "bash", cli, ...args], { cwd, env });
	}

	return spawn("bash", [cli, ...args], { cwd, env });
}

export function runCli(args, { onChunk, signal, timeoutMs } = {}) {
	return new Promise((resolve) => {
		const child = spawnCli(args);
		let stdout = "";
		let stderr = "";
		let settled = false;
		let urls = [];

		const emit = (text) => {
			if (onChunk && text) onChunk(text);
		};

		const finish = (code, extraErr = "") => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			signal?.removeEventListener("abort", onAbort);
			urls = extractUrls(stdout);
			resolve({
				code: code == null ? 1 : code,
				stdout,
				stderr: extraErr ? `${stderr}\n${extraErr}` : stderr,
				urls,
			});
		};

		const onAbort = () => {
			child.kill("SIGTERM");
			setTimeout(() => child.kill("SIGKILL"), 2000);
		};

		const timer = setTimeout(() => {
			child.kill("SIGKILL");
		}, timeoutMs || ACTION_TIMEOUT_MS);

		if (signal) {
			if (signal.aborted) onAbort();
			else signal.addEventListener("abort", onAbort);
		}

		child.stdout.on("data", (chunk) => {
			const text = chunk.toString();
			stdout += text;
			emit(text);
		});
		child.stderr.on("data", (chunk) => {
			const text = chunk.toString();
			stderr += text;
			emit(text);
		});
		child.on("error", (error) => {
			finish(1, error.message);
		});
		child.on("close", (code) => {
			finish(code);
		});
	});
}
