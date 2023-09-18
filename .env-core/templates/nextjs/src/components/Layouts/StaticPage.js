import dynamic from 'next/dynamic'
import { notFound } from "next/navigation"
import { getPageTemplate } from "@/helpers/pageRouting"

export default async function StaticPage({ params }) {
  try {
    const template = getPageTemplate(params)

    if (template === '404') notFound()

    const PageTemplate = dynamic(() => import(`@/components/PageTemplates/${template}`), { ssr: true })

    return (
      <main data-page-template={template}>
        <PageTemplate />
      </main>
    )
  } catch (err) {
    notFound()
  }
}
