// Loaded with `node --import ./tests/register.mjs --test`.
// App code imports "next/server" the way the Next.js bundler expects. Plain
// Node ESM needs the file name, because the next package has no exports map.
import { register } from "node:module";

register(
	"data:text/javascript," +
		encodeURIComponent(`
export async function resolve(specifier, context, next) {
	if (specifier === "next/server") return next("next/server.js", context);
	return next(specifier, context);
}
`),
	import.meta.url,
);
