import UpdatesPage from "../components/updates/UpdatesPage";
import { wipFeatureEnabled } from "../../lib/features";

export const dynamic = "force-dynamic";

export const metadata = {
	title: "Updates · docker-env",
};

export default function Updates() {
	return <UpdatesPage enabled={wipFeatureEnabled("updates")} />;
}
