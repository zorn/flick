import Sortable from "../../vendor/sortable"

// Reorders the rows of an `inputs_for` list in the browser. Each row holds a
// hidden sort input, so the DOM order becomes the sort param on the next
// change event. A row moves by its `[data-handle]` or by its `[data-move]`
// buttons. The buttons let keyboard users reorder too.
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

  // The server re-renders buttons by position. Focus returns to the moved
  // row's button once that render lands.
  updated() {
    if (!this.focusTarget) return
    const {direction, index} = this.focusTarget
    this.el.querySelector(`[data-move="${direction}"][data-index="${index}"]`)?.focus()
    this.focusTarget = null
  },

  destroyed() {
    this.sortable.destroy()
  },

  move(button) {
    // `inputs_for` puts hidden id inputs between the rows. Look for the
    // neighbor among the rows, not the element siblings.
    const rows = this.rows()
    const row = button.closest("[data-row]")
    const direction = button.dataset.move
    const neighbor = rows[rows.indexOf(row) + (direction === "up" ? -1 : 1)]
    if (!neighbor) return

    if (direction === "up") neighbor.before(row)
    else neighbor.after(row)

    // At either end the same-direction button is disabled, so focus the other.
    const index = this.rows().indexOf(row)
    const atEnd = direction === "up" ? index === 0 : index === rows.length - 1
    const opposite = direction === "up" ? "down" : "up"
    this.focusTarget = {direction: atEnd ? opposite : direction, index}

    button.focus()
    this.pushOrder()
  },

  rows() {
    return Array.from(this.el.querySelectorAll(":scope > [data-row]"))
  },

  // Any input inside the form triggers its change event.
  pushOrder() {
    this.el.querySelector("[data-row] input").dispatchEvent(new Event("input", {bubbles: true}))
  },
}
