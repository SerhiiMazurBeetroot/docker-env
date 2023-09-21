export default function Wrap({
  children,
  size = 'xl',
  className = '',
  align = 'left',
  ...rest
}) {
  const classNames = [
    'wrap',
    align,
    className,
  ].filter(Boolean).join(' ')

  return (
    <div
      {...rest}
      data-size={size}
      className={classNames}
    >
      {children}
    </div>
  )
}
