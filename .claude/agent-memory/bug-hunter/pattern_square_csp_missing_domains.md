---
name: Square CSP missing domains
description: secure_headers.rb lacked Square's frame_src and connect_src domains, blocking Square payments in-browser via CSP violations
type: project
---

Square's Web Payments SDK requires browser-side endpoints that must be explicitly allowed in the CSP:

- `connect_src`: `https://pci.squareup.com`, `https://pci.squareupsandbox.com`, `https://connect.squareup.com`, `https://connect.squareupsandbox.com` — used by the JS SDK for card tokenisation XHR
- `frame_src`: `https://web.squarecdn.com`, `https://sandbox.web.squarecdn.com` — the SDK renders its card input inside an iframe from these origins

Adding Square's JS files to `script_src` (as done in an earlier change) is not sufficient — the SDK's runtime network calls and iframes require the above too.

**Why:** The CSP was updated to add Square to `script_src` but the associated runtime domains were omitted, silently breaking Square card payments in the browser (CSP violations are reported in the console but don't surface as server errors).

**How to apply:** Any time Square endpoints are added to `script_src`, verify that `connect_src` and `frame_src` are also updated with Square's PCI/connect/CDN origins. Check both production (`squareup.com`) and sandbox (`squareupsandbox.com`) variants.
