import { Controller } from "@hotwired/stimulus"

// TODO: roll up this controller to one level; remove from sections
// This will involve using events to select the sections when they're clicked

export default class extends Controller {
  static values = { key: String }
  static targets = [ "input" ]

  connect() {
    this.#restoreToggle()
  }

  toggle() {
    console.log(this.element)
    if (this.element.hasAttribute("data-ignore")) {
      // console.log("Don't save it!")
    } else {
      // console.log("Save it!")
      if (this.element.open) {
        localStorage.removeItem(this.#localStorageKey)
      } else {
        localStorage.setItem(this.#localStorageKey, this.keyValue)
      }
    }
  }

  // OK, here's the behavior we want:
  // Open the dialog, and the sections are in various states of collapsed/open.
  // When you filter, we open them all.
  // When the filter is empty, we need to go back to the saved state.
  showAll() {
    console.log(this.element)
    // When filtering, we open everything and don't save to local storage.
    // When the filter is cleared, we restore toggles
    if (this.inputTarget.value) {
      for (const section of this.#sections) {
        section.setAttribute("data-ignore", true)
        section.setAttribute("open", true)
      }
    } else {
      // UGH! This works in the context of the controller on the section, not from the birds-eye view of the details el.
      this.#restoreToggle()
    }
  }

  #restoreToggle() {
    // console.log("RESTORE TOGGLE")
    const isCollapsed = localStorage.getItem(this.#localStorageKey) != null
    if (isCollapsed) this.element.open = false
  }

  get #localStorageKey() {
    return this.keyValue
  }

  get #sections() {
    return this.element.querySelectorAll(":scope details:not([open])")
  }
}
