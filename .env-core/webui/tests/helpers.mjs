import fs from "node:fs";
import os from "node:os";
import path from "node:path";

// A throwaway ENV_DIR with .env-core/data, removed after the test.
export function makeEnvDir(t, files = {}) {
	const dir = fs.mkdtempSync(path.join(os.tmpdir(), "docker-env-webui-test-"));
	fs.mkdirSync(path.join(dir, ".env-core", "data"), { recursive: true });
	for (const [rel, text] of Object.entries(files)) {
		const file = path.join(dir, rel);
		fs.mkdirSync(path.dirname(file), { recursive: true });
		fs.writeFileSync(file, text);
	}
	t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
	return dir;
}

// Set env vars for one test and restore them afterwards.
export function withEnv(t, vars) {
	const saved = {};
	for (const [key, value] of Object.entries(vars)) {
		saved[key] = process.env[key];
		if (value == null) delete process.env[key];
		else process.env[key] = value;
	}
	t.after(() => {
		for (const [key, value] of Object.entries(saved)) {
			if (value === undefined) delete process.env[key];
			else process.env[key] = value;
		}
	});
}
