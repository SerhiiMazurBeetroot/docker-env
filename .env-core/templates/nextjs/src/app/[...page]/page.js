
import StaticPage from "@/components/Layouts/StaticPage"

export const metadata = {
  title: 'Page | Next js 13 starter template',
}

export default function Page({ params }) {
  return <StaticPage params={params} />
}
