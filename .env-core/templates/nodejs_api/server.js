const express = require("express");

const app = express();
// Host PORT is the published port. The process always listens on 3000.
const port = 3000;

app.get("/health", function health(_req, res) {
	res.json({ ok: true });
});

app.get("/", function root(_req, res) {
	res.json({
		ok: true,
		name: process.env.SITE_TITLE || "api",
	});
});

const server = app.listen(port, "0.0.0.0", function onListen() {
	console.log("listening on " + port);
});

server.on("error", function onError(err) {
	console.error(err.message);
	process.exit(1);
});

function shutdown() {
	server.close(function onClose() {
		process.exit(0);
	});
}

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
