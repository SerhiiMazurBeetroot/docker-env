import Link from "next/link";
import { notFound } from "next/navigation";
import AppHeader from "../../components/layout/AppHeader";
import MermaidDiagrams from "../../components/docs/MermaidDiagrams";
import { isDeveloperSection, isDevelopmentMode, listDocs, readDoc } from "../../../lib/docs";

export const dynamic = "force-dynamic";

export function generateMetadata({ params }) {
	const slug = (params.slug || []).join("/");
	const doc = readDoc(slug);
	const developer = isDeveloperSection(slug);
	const devMode = isDevelopmentMode();
	if (developer && !devMode) {
		return { title: "Docs · docker-env" };
	}
	const section = developer ? "Developer docs" : "Docs";
	return { title: doc ? `${doc.title} · ${section}` : `${section} · docker-env` };
}

export default function DocsPage({ params }) {
	const slug = (params.slug || []).join("/");
	const doc = readDoc(slug);
	if (!doc) {
		notFound();
	}
	const developer = isDeveloperSection(doc.slug);
	const devMode = isDevelopmentMode();
	if (developer && !devMode) {
		notFound();
	}
	const groups = listDocs(developer ? "developer" : "user");

	return (
		<div className="min-h-screen">
			<AppHeader subtitle={developer ? "Developer docs" : "Documentation"} />
			<div className="mx-auto grid max-w-6xl gap-8 px-6 py-8 lg:grid-cols-[220px_minmax(0,1fr)]">
				<nav className="lg:sticky lg:top-20 lg:self-start">
					{devMode ? (
						<div className="mb-5 flex rounded-lg border border-line p-0.5 text-xs font-semibold">
							<Link
								href="/docs"
								className={`flex-1 rounded-md px-2 py-1.5 text-center ${developer ? "text-muted hover:text-fg" : "bg-raised text-fg"}`}
							>
								Using
							</Link>
							<Link
								href="/docs/dev"
								className={`flex-1 rounded-md px-2 py-1.5 text-center ${developer ? "bg-raised text-fg" : "text-muted hover:text-fg"}`}
							>
								Developing
							</Link>
						</div>
					) : null}
					{groups.map((group) => (
						<div key={group.id} className="mb-6">
							<div className="mb-2 text-[11px] font-semibold uppercase tracking-wider text-muted">{group.title}</div>
							<ul className="m-0 list-none space-y-1 p-0">
								{group.pages.map((page) => {
									const href = page.slug ? `/docs/${page.slug}` : "/docs";
									const active = page.slug === doc.slug;
									return (
										<li key={page.rel}>
											<Link
												href={href}
												className={`block rounded-lg px-2.5 py-1.5 text-sm ${
													active ? "bg-raised font-semibold text-fg" : "text-muted hover:text-fg"
												}`}
											>
												{page.title}
											</Link>
										</li>
									);
								})}
							</ul>
						</div>
					))}
				</nav>
				<article className="doc-prose min-w-0" dangerouslySetInnerHTML={{ __html: doc.html }} />
				<MermaidDiagrams slug={doc.slug} />
			</div>
		</div>
	);
}
