import fs from "fs";
import path from "path";
import { envDir } from "./cli/shared.js";
import { versionChoiceError as choiceError } from "./versionChoices.js";

export function versionCatalogPath() {
	return path.join(envDir(), ".env-core/data/catalog.json");
}

export function readVersionCatalog() {
	try {
		const data = JSON.parse(fs.readFileSync(versionCatalogPath(), "utf8"));
		return data && typeof data === "object" ? data : {};
	} catch {
		return {};
	}
}

export function versionChoiceError(options, catalog = readVersionCatalog()) {
	return choiceError(options, catalog);
}
