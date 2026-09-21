export default function Skeleton({ className = "" }) {
	return <div className={`animate-pulse rounded-2xl bg-panel ${className}`} />;
}

export function SystemSkeleton() {
	return (
		<section className="mb-4 flex items-center gap-2 rounded-xl border border-line bg-panel/80 px-3 py-2">
			<Skeleton className="h-3 w-12 rounded" />
			<Skeleton className="h-7 w-20 rounded-lg" />
			<Skeleton className="h-7 w-20 rounded-lg" />
			<Skeleton className="h-7 w-20 rounded-lg" />
		</section>
	);
}

export function ProjectSkeleton({ compact = false, grid = false }) {
	const cards = grid ? (
		<div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
			{[0, 1, 2].map((item) => (
				<article key={item} className="rounded-2xl border border-line bg-panel/90 p-3.5">
					<Skeleton className="h-5 w-16 rounded-full" />
					<Skeleton className="mt-3 h-5 w-28 rounded-lg" />
					<Skeleton className="mt-2 h-3 w-40 rounded" />
					<div className="mt-4 flex gap-2">
						<Skeleton className="h-6 w-20 rounded-lg" />
						<Skeleton className="h-6 w-16 rounded-lg" />
					</div>
				</article>
			))}
		</div>
	) : compact ? (
		<div className="grid gap-1.5">
			{[0, 1].map((item) => (
				<article key={item} className="rounded-xl border border-line bg-panel/90 px-3 py-2">
					<div className="flex items-center gap-2">
						<Skeleton className="h-5 w-16 rounded-full" />
						<Skeleton className="h-5 w-28 rounded-lg" />
						<Skeleton className="ml-auto h-7 w-28 rounded-lg" />
					</div>
				</article>
			))}
		</div>
	) : (
		<div className="grid gap-3">
			{[0, 1].map((item) => (
				<article key={item} className="rounded-2xl border border-line bg-panel/90 p-4">
					<div className="flex flex-col gap-4 xl:flex-row">
						<div className="min-w-0 flex-1">
							<div className="mb-3 flex gap-2">
								<Skeleton className="h-6 w-20 rounded-full" />
							</div>
							<Skeleton className="h-6 w-40 rounded-lg" />
							<Skeleton className="mt-2 h-3 w-56 rounded" />
							<div className="mt-4 flex gap-2">
								<Skeleton className="h-8 w-36 rounded-lg" />
								<Skeleton className="h-8 w-28 rounded-lg" />
							</div>
						</div>
						<Skeleton className="h-10 w-64 rounded-xl" />
					</div>
				</article>
			))}
		</div>
	);

	return (
		<div className={compact ? "grid gap-4" : "grid gap-6"}>
			{[0, 1].map((group) => (
				<section key={group}>
					<div className="mb-2 flex items-center gap-2">
						<Skeleton className="h-5 w-24 rounded-full" />
						<Skeleton className="h-3 w-16 rounded" />
					</div>
					{cards}
				</section>
			))}
		</div>
	);
}
