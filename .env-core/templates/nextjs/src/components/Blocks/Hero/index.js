import Wrap from '@/components/Layouts/Wrappers/Wrap'
import UseIcon from '@/components/UI/UseIcon'
import Button from '@/components/UI/Button'

import styles from './index.module.scss'

export default function Hero({ ...props }) {
  const {
    h2,
  } = props

  return (
    <Wrap size='s' align="center">
      <div className={styles.content}>
        <h1 className={styles.h1}>
          <span className={styles.gradientText}>Next js 13</span> Starter-kit
        </h1>

        {h2 && <h2 className={styles.h2}>{h2}</h2>}

        <p>Provides clean and structured code, allowing you to create scalable and maintainable web applications with maximim efficiency.</p>
      </div>

      <Button
        type="link"
        target='_blank'
        href="https://github.com/SerhiiMazurBeetroot/devENV"
        variant="default"
        className={styles.button}
      >
        <UseIcon name='github' />
        <span>Add star on Github</span>
      </Button>
    </Wrap>
  )
}
