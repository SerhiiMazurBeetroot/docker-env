import StaticPage from "@/components/Layouts/StaticPage"

export const metadata = {
  title: 'Home | Next js 13 starter template',
}

export default function Home({ params }) {
  return <StaticPage params={params} />
}
