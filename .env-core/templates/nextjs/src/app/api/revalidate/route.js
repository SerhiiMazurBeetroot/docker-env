import { NextResponse } from 'next/server'
import { revalidateTag, revalidatePath } from 'next/cache'

export async function GET(request) {
  const error = NextResponse.json({
    error: 'one of the following url params is required: tag/path'
  })

  const params = request?.nextUrl?.searchParams
  if (!params) return error

  const tag = params.get('tag')
  const path = params.get('path')
  if (!tag && !path) return error

  if (tag) revalidateTag(tag)
  if (path) revalidatePath(path)

  return NextResponse.json({ revalidated: true, now: Date.now() })
}
