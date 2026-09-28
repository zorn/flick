import Sortable from "../../vendor/sortable"

// Reorders the rows of an `inputs_for` list in the browser. Each row carries a
// hidden sort input, so the new DOM order becomes the new sort param once the
// form sends its change event. Rows move by dragging their `[data-handle]` or
// by pressing their `[data-move]` buttons, which keep keyboard users covered.
// Those buttons need ids ending in `-up-<index>` or `-down-<index>`.
//
// Adapted from https://github.com/bemesa21/components_examples.
export default {
  mounted() {
    this.sortable = new Sortable(this.el, {
      animation: 150,
      draggable: "[data-row]",
      handle: "[data-handle]",
      ghostClass: "opacity-40",
      forceFallback: true,
      onEnd: ({oldIndex, newIndex}) => {
        if (oldIndex !== newIndex) this.pushOrder()
      },
    })

    this.el.addEventListener("click", event => {
      const button = event.target.closest("[data-move]")
      if (button && !button.disabled) this.move(button)
    })
  },

  // Button ids follow the row position, so after the server re-renders, focus
  // goes back to the moved row's button at its new position.
  updated() {
    if (!this.focusId) return
    document.getElementById(this.focusId)?.focus()
    this.focusId = null
  },

  destroyed() {
    this.sortable.destroy()
  },

  move(button) {
    // `inputs_for` puts each row's hidden id inputs between the rows, so
    // neighbors are found among the rows rather than the element siblings.
    const rows = this.rows()
    const row = button.closest("[data-row]")
    const direction = button.dataset.move
    const neighbor = rows[rows.indexOf(row) + (direction === "up" ? -1 : 1)]
    if (!neighbor) return

    if (direction === "up") neighbor.before(row)
    else neighbor.after(row)

    const index = this.rows().indexOf(row)
    const atEnd = direction === "up" ? index === 0 : index === rows.length - 1
    const focusDirection = atEnd ? (direction === "up" ? "down" : "up") : direction
    const prefix = button.id.replace(/-(up|down)-\d+$/, "")
    this.focusId = `${prefix}-${focusDirection}-${index}`

    button.focus()
    this.pushOrder()
  },

  rows() {
    return Array.from(this.el.querySelectorAll(":scope > [data-row]"))
  },

  pushOrder() {
    this.el.querySelector("input").dispatchEvent(new Event("input", {bubbles: true}))
  },
}
