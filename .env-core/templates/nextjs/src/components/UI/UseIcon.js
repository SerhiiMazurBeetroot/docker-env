import { AiFillGithub, AiFillLinkedin, AiFillFacebook, AiFillRedditCircle } from 'react-icons/ai'
import { TfiWorld } from 'react-icons/tfi'
import { FaMoon, FaSun } from 'react-icons/fa'

export default function UseIcon({ name, className }) {
  const IconComponent = icons[name]

  if (!IconComponent) {
    return null
  }

  return <IconComponent className={className} />
}

export const icons = {
  github: AiFillGithub,
  linkedin: AiFillLinkedin,
  facebook: AiFillFacebook,
  web: TfiWorld,
  reddit: AiFillRedditCircle,
  moon: FaMoon,
  sun: FaSun,
}
