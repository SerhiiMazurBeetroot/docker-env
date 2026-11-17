import fs from "fs";
import { mediaFile, mediaType } from "../../../../lib/docs";

export const dynamic = "force-dynamic";

export async function GET(_request, props) {
	const params = await props.params;
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
