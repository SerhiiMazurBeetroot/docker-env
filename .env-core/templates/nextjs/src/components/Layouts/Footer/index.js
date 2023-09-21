import Wrap from '@/components/Layouts/Wrappers/Wrap'
import Menu from '@/components/Layouts/Footer/Menu'
import { NAVIGATION } from '@/helpers/config/const'
import styles from './styles/index.module.scss'

export default function Footer() {
  return (
    <footer className={styles.footer}>
      <Wrap size="l" className={styles.wrap}>
        <Menu items={NAVIGATION} />

        <div>© 2023 | All rights reserved</div>
      </Wrap>
    </footer>
  )
}
