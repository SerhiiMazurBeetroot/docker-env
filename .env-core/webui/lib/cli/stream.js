import { recordDiagnostic } from "../diagnostics.js";
import { markSnapshotDirty } from "./cache.js";
import { stripUrlMarker, runCli } from "./run.js";
import { failureLine, locks, recordLastAction } from "./shared.js";

export function streamLockedCli(args, lockKey, signal, doneMeta) {
	if (locks.has("bulk") || (lockKey === "bulk" && locks.size > 0) || locks.has(lockKey)) {
		const message = `An action is already running for ${doneMeta.target}`;
		recordDiagnostic({
			source: "webui",
			action: doneMeta.action,
			target: doneMeta.target,
			message,
		});
		return {
			error: {
				status: 409,
				body: { ok: false, error: message },
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

			runCli(args, {
				signal,
				onChunk: (text) => send({ type: "log", text }),
				timeoutMs: doneMeta.timeoutMs,
			})
				.then((result) => {
					const log = stripUrlMarker(`${result.stdout}\n${result.stderr}`).trim();
					const failed = result.code !== 0;
					const line = failureLine(log, `Failed to ${doneMeta.action} ${doneMeta.target}`);
					if (failed) {
						recordDiagnostic({
							source: "webui",
							action: doneMeta.action,
							target: doneMeta.target,
							message: line,
							detail: log,
						});
					}
					send({
						type: "done",
						ok: !failed,
						...doneMeta,
						error: failed ? line : "",
						log,
					});
					if (doneMeta.domain) {
						const label = doneMeta.service
							? `${doneMeta.action} ${doneMeta.service}`
							: doneMeta.action;
						recordLastAction(doneMeta.domain, label, !failed, failed ? line : "");
					}
				})
				.catch((error) => {
					const message = error.message || `Failed to ${doneMeta.action} ${doneMeta.target}`;
					recordDiagnostic({
						source: "webui",
						action: doneMeta.action,
						target: doneMeta.target,
						message,
					});
					if (doneMeta.domain) {
						recordLastAction(doneMeta.domain, doneMeta.action, false, message);
					}
					send({
						type: "done",
						ok: false,
						...doneMeta,
						error: message,
						log: "",
					});
				})
				.finally(() => {
					locks.delete(lockKey);
					markSnapshotDirty();
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
