import "./globals.css";
import { DisplayProvider } from "./components/display/DisplayProvider";
import { ThemeProvider } from "./components/theme/ThemeProvider";
import { LogSettingsProvider } from "./components/logs/LogSettingsProvider";
import { SnapshotProvider } from "./components/snapshot/SnapshotProvider";

export const metadata = {
	title: "docker-env",
	description: "Local project containers",
};

export const viewport = {
	width: "device-width",
	initialScale: 1,
	viewportFit: "cover",
};

const themeBootScript = `(function(){try{var p=localStorage.getItem("docker-env-theme")||"dark";var d=p==="auto"?(window.matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light"):(p==="light"?"light":"dark");document.documentElement.setAttribute("data-theme",d);document.documentElement.style.colorScheme=d;}catch(e){}})();`;

export default function RootLayout({ children }) {
	return (
		<html lang="en" suppressHydrationWarning>
			<head>
				<script dangerouslySetInnerHTML={{ __html: themeBootScript }} />
				<link rel="preconnect" href="https://fonts.googleapis.com" />
				<link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
				<link
					href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap"
					rel="stylesheet"
				/>
			</head>
			<body>
				<ThemeProvider>
					<DisplayProvider>
						<LogSettingsProvider>
							<SnapshotProvider>{children}</SnapshotProvider>
						</LogSettingsProvider>
					</DisplayProvider>
				</ThemeProvider>
			</body>
		</html>
	);
}
