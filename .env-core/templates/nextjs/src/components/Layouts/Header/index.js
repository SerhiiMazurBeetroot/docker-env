'use client'

import Link from 'next/link'
import Menu from '@/components/Layouts/Header/Menu'
import { NAVIGATION } from '@/helpers/config/const'
import NextIcon from '@/assets/images/Nextjs-logo.svg'
import Wrap from '@/components/Layouts/Wrappers/Wrap'
import { ThemeChanger } from '@/components/UI/ThemeChanger/ThemeChanger'

import styles from './styles/index.module.scss'

export default function Header({ data }) {

  return (
    <header className={styles.header}>
      <Wrap size="l" className={styles.wrap}>

        <div className={styles.left}>
          <Link href={'/'} className={styles.logo}>
            <NextIcon width={156} height={32} />
          </Link>
        </div>

        <div className={styles.right}>
          <Menu items={NAVIGATION} />
          <ThemeChanger />
        </div>

      </Wrap>
    </header>
  )
}


