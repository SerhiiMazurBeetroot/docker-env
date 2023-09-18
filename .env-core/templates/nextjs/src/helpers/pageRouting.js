const templates = new Map([
  ['404', '404'],
  ['home', 'Home'],
  ['default', 'Page'],
  ['about', 'About'],
])

export function getPageTemplate(params) {
  const joinedParams = params?.page?.map((p, i) => `${p}${i !== params?.page?.length - 1 ? '/' : ''}`).join('')
  
  let id = joinedParams?.length ? joinedParams : 'home'

  if (!templates.has(id)) id = '404'

  return templates.get(id)
}
