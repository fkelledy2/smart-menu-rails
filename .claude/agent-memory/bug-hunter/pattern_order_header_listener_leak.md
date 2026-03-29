---
name: order_header_controller.js event listener leak
description: order_header_controller adds state:order and state:changed listeners in connect() but has no disconnect() to remove them — leak accumulates on Turbo navigations
type: project
---

`app/javascript/controllers/order_header_controller.js` lines 8-9:
```js
document.addEventListener('state:order', () => this.render());
document.addEventListener('state:changed', () => this.render());
```
No `disconnect()` method is defined. On every Turbo page visit where this controller is mounted/unmounted, a new listener is added but the old one is never removed. After N navigations there are N duplicate calls to `render()` on every state event.

**Why:** Arrow functions are anonymous — cannot be removed without storing a reference.

**How to apply:** Store bound references and remove them in disconnect:
```js
connect() {
  this._onStateOrder = () => this.render();
  this._onStateChanged = () => this.render();
  document.addEventListener('state:order', this._onStateOrder);
  document.addEventListener('state:changed', this._onStateChanged);
  this.render();
}
disconnect() {
  document.removeEventListener('state:order', this._onStateOrder);
  document.removeEventListener('state:changed', this._onStateChanged);
}
```
