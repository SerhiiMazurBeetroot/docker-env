import path from "path";
import { spawn } from "child_process";

let cache = null;

function envDir() {
	return process.env.ENV_DIR || process.env.DOCKER_ENV_DIR || path.resolve(process.cwd(), "../..");
}

function cliScript() {
	return path.join(envDir(), ".env-core/webui/webui_cli.sh");
}

function parseCatalogStdout(stdout) {
	const trimmed = String(stdout || "").trim();
	if (!trimmed) {
		throw new Error("empty catalog");
	}
	try {
		return JSON.parse(trimmed);
	} catch (err) {
		const start = trimmed.indexOf("{");
		const end = trimmed.lastIndexOf("}");
		if (start >= 0 && end > start) {
			return JSON.parse(trimmed.slice(start, end + 1));
		}
		throw err;
	}
}

export function clearProjectCatalogCache() {
	cache = null;
}

export function loadProjectCatalog() {
	if (cache) {
		return Promise.resolve(cache);
	}

	return new Promise((resolve, reject) => {
		const child = spawn("bash", [cliScript(), "catalog"], {
			env: {
				...process.env,
				ENV_DIR: envDir(),
				DOCKER_ENV_DIR: envDir(),
			},
		});

		let stdout = "";
		let stderr = "";

		child.stdout.on("data", (chunk) => {
			stdout += chunk.toString();
		});
		child.stderr.on("data", (chunk) => {
			stderr += chunk.toString();
		});
		child.on("error", (error) => {
			reject(error);
		});
		child.on("close", (code) => {
			if (code !== 0) {
				reject(new Error(stderr.trim() || `catalog exit ${code}`));
				return;
			}

			try {
				cache = parseCatalogStdout(stdout);
				resolve(cache);
			} catch (err) {
				reject(err);
			}
		});
	});
}

export function catalogTypeIds(catalog) {
	return new Set((catalog?.types || []).map((item) => item.id).filter(Boolean));
}

export function composeRelForType(catalog, type) {
	const row = (catalog?.types || []).find((item) => item.id === type);
	return row?.compose || "";
}
