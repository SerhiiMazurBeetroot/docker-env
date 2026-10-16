import fs from "fs";
import path from "path";
import { isDevelopmentMode } from "./docs.js";

function envDir() {
	return process.env.ENV_DIR || process.env.DOCKER_ENV_DIR || path.resolve(process.cwd(), "../..");
}

function featuresFile() {
	return path.join(envDir(), ".env-core", "sh", "core", "wip_features.ids");
}

export function wipFeatureIds() {
	try {
		return fs
			.readFileSync(featuresFile(), "utf8")
			.split(/\r?\n/)
			.map((line) => line.replace(/#.*/, "").trim())
			.filter(Boolean);
	} catch {
		return [];
	}
}

export function wipFeatureEnabled(id) {
	return wipFeatureIds().includes(id) && isDevelopmentMode();
}

export function wipFeatureMap() {
	const enabled = isDevelopmentMode();
	return Object.fromEntries(wipFeatureIds().map((id) => [id, enabled]));
}

export function wipFeatureDenied(id) {
	if (wipFeatureEnabled(id)) return null;
	return {
		status: 403,
		body: {
			ok: false,
			error: "This is a developer feature. Set ENV_MODE=development to use it.",
		},
	};
}
