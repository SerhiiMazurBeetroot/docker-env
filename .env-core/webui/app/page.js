import { Suspense } from "react";
import Dashboard from "./components/dashboard/Dashboard";

export default function HomePage() {
	// Dashboard reads ?view= with useSearchParams, which needs a Suspense boundary.
	return (
		<Suspense fallback={null}>
			<Dashboard />
		</Suspense>
	);
}
