Binxtils is a Ruby Gem — Bike Index utility modules.

It also publishes `@bikeindex/time-localizer`, an npm package for localizing time elements in the browser.

## Code style

Ruby is formatted with the standard gem. Run `bin/lint` to automatically format the code, or `bin/lint --no-fix` to check without fixing.

### Code guidelines:

- Code in a functional way. Avoid mutation (side effects) when you can.
  - use the functionable gem to make functional modules
- Don't mutate arguments
- Don't monkeypatch
- make methods private if possible (use `conceal :method_name` in functionable modules)
- Omit named arguments' values from hashes (ie prefer `{x:, y:}` instead of `{x: x, y: y}`)
- Prefer less code, by character count (excluding whitespace and comments). Use `bin/char_count {FILE OR FOLDER}` to get the non-whitespace character count
- prefer un-abbreviated variable names

## JavaScript

The npm package (`@bikeindex/time-localizer`) lives in `index.js` with `package.json` at the repo root. It depends on Luxon and is published separately from the gem.

## Testing

This project uses Rspec for Ruby tests (`bin/rspec`) and Vitest for JavaScript tests (`npm test`). All business logic should be tested.

- Tests should either: help make the code correct now or prevent bugs in the future. Don't add tests that don't do one of those things.
- Avoid mocking objects
- Ruby: Use `context` and `let` to isolate what varies between examples.
  - Each `it` block should live in a `context` that names the condition, with `let` overrides for only what differs in that case. Avoid repeating setup across sibling `it` blocks.
- JavaScript: Tests are in `index.test.js`. The vitest config pins `TZ=America/Chicago` for deterministic output.
