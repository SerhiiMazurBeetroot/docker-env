import assert from "node:assert/strict";
import test from "node:test";
import { filterProjects, groupProjectsByType, projectTypeCounts } from "../app/lib/projects.js";

const SITES = [
	{ domain: "blog", type: "wordpress", running: true },
	{ domain: "shop", type: "wordpress", running: false },
	{ domain: "front", type: "nextjs", running: true },
	{ domain: "cms", type: "directus", running: false },
];

const domains = (list) => list.map((item) => item.domain);

test("projectTypeCounts counts sites per type, sorted by name", () => {
	assert.deepEqual(projectTypeCounts(SITES), [
		{ type: "directus", count: 1 },
		{ type: "nextjs", count: 1 },
		{ type: "wordpress", count: 2 },
	]);
	assert.deepEqual(projectTypeCounts(null), []);
});

test("no selected types shows every type", () => {
	assert.deepEqual(domains(filterProjects(SITES, "", "all", [])), ["blog", "shop", "front", "cms"]);
	assert.deepEqual(domains(filterProjects(SITES, "", "all")), ["blog", "shop", "front", "cms"]);
});

test("selected types narrow the list and can be combined", () => {
	assert.deepEqual(domains(filterProjects(SITES, "", "all", ["wordpress"])), ["blog", "shop"]);
	assert.deepEqual(domains(filterProjects(SITES, "", "all", ["nextjs", "directus"])), ["front", "cms"]);
});

test("type chips combine with the status filter and search", () => {
	assert.deepEqual(domains(filterProjects(SITES, "", "running", ["wordpress"])), ["blog"]);
	assert.deepEqual(domains(filterProjects(SITES, "", "stopped", ["wordpress"])), ["shop"]);
	assert.deepEqual(domains(filterProjects(SITES, "sho", "all", ["wordpress"])), ["shop"]);
	assert.deepEqual(domains(filterProjects(SITES, "blog", "all", ["nextjs"])), []);
});

test("groupProjectsByType makes one sorted section per type with its guide", () => {
	const sites = [...SITES, { domain: "docs", type: "nextjs", guide: "/docs/projects/nextjs" }];
	const groups = groupProjectsByType(sites);
	assert.deepEqual(
		groups.map((group) => [group.type, domains(group.items), group.guide]),
		[
			["directus", ["cms"], ""],
			["nextjs", ["front", "docs"], "/docs/projects/nextjs"],
			["wordpress", ["blog", "shop"], ""],
		],
	);
	assert.deepEqual(groupProjectsByType([]), []);
});
