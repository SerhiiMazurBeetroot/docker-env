import { spawn } from "child_process";
import { parseDockerLogLine } from "../logParse";
import { SYSTEM_CONTAINERS, isSafeContainerName } from "./shared.js";

export { isSafeContainerName };

function isAllowedLogContainer(name) {
	if (SYSTEM_CONTAINERS.has(name)) return true;
	return /^[A-Za-z0-9][A-Za-z0-9.-]{0,80}-[A-Za-z0-9][A-Za-z0-9_.-]{0,80}$/.test(name);
}

function inspectContainerName(name) {
	return new Promise((resolve) => {
		const child = spawn("docker", ["inspect", "--format", "{{.Name}}", name]);
		let out = "";
		child.stdout.on("data", (chunk) => {
			out += chunk.toString();
		});
		child.on("error", () => resolve(""));
		child.on("close", (code) => {
			resolve(code === 0 ? out.trim().replace(/^\//, "") : "");
		});
	});
}

export function streamContainerLogs(name, signal) {
	if (!isSafeContainerName(name) || !isAllowedLogContainer(name)) {
		return { error: { status: 400, body: { ok: false, error: "Invalid container" } } };
	}

	const encoder = new TextEncoder();
	let closed = false;
	let child = null;
	let pingTimer = null;

	const stream = new ReadableStream({
		async start(controller) {
			const sendRaw = (chunk) => {
				if (closed) return;
				controller.enqueue(encoder.encode(chunk));
			};
			const send = (event, payload) => {
				sendRaw(`event: ${event}\ndata: ${JSON.stringify(payload)}\n\n`);
			};

			const stop = () => {
				clearInterval(pingTimer);
				child?.kill("SIGTERM");
				setTimeout(() => child?.kill("SIGKILL"), 1500);
				if (!closed) {
					closed = true;
					try {
						controller.close();
					} catch (err) {
						// already closed
					}
				}
			};

			const inspected = await inspectContainerName(name);
			if (closed) return;
			if (inspected !== name) {
				send("fail", { error: `Container not found: ${name}` });
				stop();
				return;
			}

			child = spawn("docker", ["logs", "--timestamps", "--tail", "200", "-f", "--", name], {
				env: process.env,
			});

			let buffer = "";
			const onChunk = (chunk) => {
				buffer += chunk.toString();
				const lines = buffer.split("\n");
				buffer = lines.pop() || "";
				for (const line of lines) {
					const entry = parseDockerLogLine(line.replace(/\r$/, ""));
					if (entry) send("entry", entry);
				}
			};

			child.stdout.on("data", onChunk);
			child.stderr.on("data", onChunk);
			child.on("error", (error) => {
				send("fail", { error: error.message || "docker logs failed" });
			});
			child.on("close", (code) => {
				if (buffer) {
					const entry = parseDockerLogLine(buffer.replace(/\r$/, ""));
					if (entry) send("entry", entry);
				}
				send("done", { ok: code === 0 });
				stop();
			});

			pingTimer = setInterval(() => sendRaw(": ping\n\n"), 15000);

			const onAbort = () => {
				signal?.removeEventListener("abort", onAbort);
				stop();
			};

			if (signal) {
				if (signal.aborted) onAbort();
				else signal.addEventListener("abort", onAbort);
			}
		},
		cancel() {
			clearInterval(pingTimer);
			closed = true;
			child?.kill("SIGTERM");
			setTimeout(() => child?.kill("SIGKILL"), 1500);
		},
	});

	return { stream };
}
