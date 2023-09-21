'use client'

import { forwardRef } from "react"
import Link from "next/link"
import styles from "./index.module.scss"

const Button = forwardRef(({ children, ...props }, ref) => {
  const {
    type = "button",
    active = false,
    variant = "default",
    width = "auto",
    loading = false,
    disabled = false,
    onClick,
    className,
    ...rest
  } = props

  const dataAttributes = {
    "data-active": active ? "true" : undefined,
    "data-loading": loading ? "true" : undefined,
    "data-disabled": disabled ? "true" : undefined,
  }

  const classNames = [
    "button",
    styles.button,
    styles[variant],
    styles[width],
    className,
  ]
    .filter(Boolean)
    .join(" ")

  const Props = {
    ref,
    className: classNames,
    ...dataAttributes,
    ...rest,
  }

  if (type === "link") {
    return (
      <Link href="#" passHref {...Props}>
        {children}
      </Link>
    )
  }

  return (
    <button
      type="button"
      {...Props}
      onClick={(e) => {
        onClick && onClick(e)
      }}
    >
      {children}
    </button>
  )
})

export default Button
