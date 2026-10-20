# Frontend

- Tailwind CSS v4 reads its configuration from `assets/css/app.css`. Flick has no `tailwind.config.js`.
- Style elements with Tailwind utility classes in templates. Keep `@apply` out of CSS.
- Build components by hand with Tailwind. Flick does not use daisyUI.
- Bring in a third-party script or stylesheet by importing it into `app.js` or `app.css`, as `assets/vendor/` does. The layouts load only those two bundles.
