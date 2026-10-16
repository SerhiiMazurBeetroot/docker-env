import fs from "fs";
import { mediaFile, mediaType } from "../../../../lib/docs";

export const dynamic = "force-dynamic";

export function GET(_request, { params }) {
	const file = mediaFile(params.path || []);
	if (!file) {
		return new Response("Not found", { status: 404 });
	}
	const body = fs.readFileSync(file);
	return new Response(body, {
		headers: {
			"Content-Type": mediaType(file),
			"Cache-Control": "private, max-age=3600",
		},
	});
}
