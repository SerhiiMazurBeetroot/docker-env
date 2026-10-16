import { recordDiagnostic } from "../diagnostics.js";
import { applyHostsExtras } from "../listSnapshot";
import { markSnapshotDirty } from "./cache.js";
import { isSafeDomain, locks, recordLastAction } from "./shared.js";

export function streamHostsAction(action, domain, signal) {
	if (!new Set(["add", "rem"]).has(action) || !isSafeDomain(domain)) {
		return { error: { status: 400, body: { ok: false, error: "Invalid hosts action" } } };
	}

	const lockKey = `domain:${domain}`;
	if (locks.has("bulk") || locks.has(lockKey)) {
		return {
			error: {
				status: 409,
				body: { ok: false, error: `An action is already running for ${domain}` },
			},
		};
	}

	locks.add(lockKey);
	const encoder = new TextEncoder();
	let closed = false;

	const stream = new ReadableStream({
		start(controller) {
			const send = (payload) => {
				if (closed) return;
				controller.enqueue(encoder.encode(`data: ${JSON.stringify(payload)}\n\n`));
			};

			const abort = () => {
				closed = true;
			};
			if (signal?.aborted) abort();
			else signal?.addEventListener("abort", abort);

			applyHostsExtras(action, domain)
				.then((result) => {
					send({ type: "log", text: `${result.log || ""}\n` });
					send({
						type: "done",
						ok: !!result.ok,
						domain,
						action: action === "add" ? "add hosts extras" : "remove hosts extras",
						target: domain,
						error: result.ok ? "" : result.log || "Hosts update failed",
						log: result.log || "",
					});
					if (result.ok) {
						recordLastAction(domain, action === "add" ? "add hosts extras" : "remove hosts extras", true);
					} else {
						const message = result.log || "Hosts update failed";
						const label = action === "add" ? "add hosts extras" : "remove hosts extras";
						recordDiagnostic({
							source: "webui",
							action: label,
							target: domain,
							message,
						});
						recordLastAction(domain, label, false, message);
					}
				})
				.catch((error) => {
					const message = error.message || "Hosts update failed";
					const label = action === "add" ? "add hosts extras" : "remove hosts extras";
					recordDiagnostic({
						source: "webui",
						action: label,
						target: domain,
						message,
					});
					recordLastAction(domain, label, false, message);
					send({
						type: "done",
						ok: false,
						domain,
						error: error.message || "Hosts update failed",
						log: "",
					});
				})
				.finally(() => {
					locks.delete(lockKey);
					markSnapshotDirty();
					signal?.removeEventListener("abort", abort);
					if (!closed) {
						closed = true;
						controller.close();
					}
				});
		},
		cancel() {
			closed = true;
			locks.delete(lockKey);
		},
	});

	return { stream };
}
