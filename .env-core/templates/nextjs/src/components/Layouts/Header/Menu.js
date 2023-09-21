import MenuItem from "@/components/Layouts/Header/MenuItem"
import styles from "./styles/Menu.module.scss"

export default function Menu({ items }) {
  return (
    <nav className={styles.menu}>
      {items?.map((item, idx) => {
        return (
          <div
            key={idx}
            className={styles.item}
          >
            <MenuItem data={item} />
          </div>
        )
      })}
    </nav>
  )
}
