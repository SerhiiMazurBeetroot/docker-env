// ESLint flat config. Next.js 16 removed `next lint`; run `npm run lint`.
// ESLint stays on 9: the import, jsx-a11y and react plugins inside
// eslint-config-next 16 declare peer support up to ESLint 9 only.
import nextCoreWebVitals from "eslint-config-next/core-web-vitals";

const config = [
	...nextCoreWebVitals,
	{
		ignores: [".next/**", "node_modules/**", "next-env.d.ts"],
	},
	{
		rules: {
			// Ten components set state in an effect on purpose (read localStorage
			// after mount, reset on prop change, loading flags). Moving them to
			// useSyncExternalStore / derived state is its own refactor; until
			// then this reports as a warning instead of failing lint.
			"react-hooks/set-state-in-effect": "warn",
			// Pages Router rule. app/layout.js is the root layout, so its font
			// link already applies to every page.
			"@next/next/no-page-custom-font": "off",
		},
	},
];

export default config;
