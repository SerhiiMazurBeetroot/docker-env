'use client'

import { usePathname } from "next/navigation"
import Link from "next/link"

export default function MenuItem({ data, className }) {
  const pathname = usePathname()
  const isActive = pathname.split('/').some(segment => data?.path === segment)

  if (!data?.path) return (
    <div className={className}>
      <h4>{data?.name}</h4>
    </div>
  )

  return (
    <Link className={className} href={data?.path} data-active={isActive}>
      <span>{data?.name}</span>
    </Link>
  )
}
