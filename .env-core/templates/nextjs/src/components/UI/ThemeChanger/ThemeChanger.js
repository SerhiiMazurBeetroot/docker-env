import { useTheme } from 'next-themes'
import UseIcon from '@/components/UI/UseIcon'
import { useState, useEffect } from 'react'
import Button from '@/components/UI/Button'

export const ThemeChanger = () => {
  const [mounted, setMounted] = useState(false)
  const { theme, setTheme } = useTheme()
  const iconName = theme === 'dark' ? 'sun' : 'moon'

  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return null
  }

  return (
    <Button
      variant="transparent"
      onClick={e => theme === 'dark' ? setTheme('light') : setTheme('dark')}>
      <UseIcon name={iconName} />
    </Button>
  )
}
