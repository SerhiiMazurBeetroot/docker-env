import Link from 'next/link'
import Wrap from '@/components/Layouts/Wrappers/Wrap'
import styles from '@/styles/layout/404.scss'

export default function NotFound() {
  return (
    <main data-page-template="404">
      <Wrap size='s' align="center">
        <h2>Opps! That page can’t be found</h2>
        <p>Make sure URL is correct and try again</p>
        <Link type="link" href="/">
          <span>Go to homepage</span>
        </Link>
      </Wrap>
    </main>
  )
}
