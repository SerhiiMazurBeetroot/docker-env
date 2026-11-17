/** @type {import('next').NextConfig} */
const nextConfig = {
	output: "standalone",
	// next dev (Develop image) blocks its own scripts and live reload for any host but
	// "localhost" since Next 16. The Web UI is opened at 127.0.0.1:7777, so allow it.
	// Production (next start) ignores this setting.
	allowedDevOrigins: ["127.0.0.1"],
};

module.exports = nextConfig;
