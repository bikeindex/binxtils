Binxtils is a Ruby Gem — Bike Index utility modules.

It also publishes `@bikeindex/time-localizer`, an npm package for localizing time elements in the browser.

[mise](https://mise.jdx.dev/) is used for Ruby and Node version management (`.tool-versions`).

## Initial setup

```bash
bundle install # ruby dependencies
npm install    # javascript dependencies
```

## Code style

Ruby is formatted with the standard gem. Run `bin/lint` to automatically format the code, or `bin/lint --no-fix` to check without fixing. Always use `bin/lint`, don't use other formatters.

**Pass it the files or directories you changed** — `bin/lint lib/binxtils/time_parser.rb`. A bare `bin/lint` walks the whole repo, which is slow and reformats files you aren't working on. Save it for a final check before pushing.

**Never revert what the linter wrote.** If a too-broad `bin/lint` reformats files outside your change, leave those fixes in the diff — don't `git checkout` them away. Scope the next run more tightly instead.

### Code guidelines:

- Code in a functional way. Avoid mutation (side effects) when you can.
  - use the functionable gem to make functional modules
- Don't mutate arguments
- Don't monkeypatch
- make methods private if possible (use `conceal :method_name` in functionable modules)
- Omit named arguments' values from hashes (ie prefer `{x:, y:}` instead of `{x: x, y: y}`)
- Prefer less code, by character count (excluding whitespace and comments). Use `bin/char_count {FILE OR FOLDER}` to get the non-whitespace character count
- prefer un-abbreviated variable names
- Use full class/module names everywhere — `Binxtils::TimeZoneParser`, not the `TimeZoneParser` that lexical scope also resolves from inside `Binxtils`
- Keep comments pithy — often they aren't necessary. Explain *why* only where a reader would otherwise get it wrong; don't narrate the change that introduced the code, and don't defend a choice against an edit nobody would make — a failing test already defends it
- **Prefer composition over inheritance and `include`.** Share behavior by calling an object that owns it, not by mixing a module into several classes or adding a base class. A `module` extracted only to be `include`d in two classes is usually one of those classes with a parameter — pass the difference in as an argument instead. Rails' own extension points (such as `Binxtils::Engine`) are fine; new mixins of our own are what to avoid.
- **Utility modules** (`lib/binxtils/`): a stateless utility is a `module` with `extend Functionable` (see the `functionable` gem) — inputs passed as args, no instance state, private methods via `conceal` + a `# private below here` block. Don't write a stateless utility as a `class` with `def self.` methods.

## JavaScript

The npm package (`@bikeindex/time-localizer`) lives in `index.js` with `package.json` at the repo root. It depends on Luxon and is published separately from the gem.

## Testing

This project uses Rspec for Ruby tests (`bin/rspec`) and Vitest for JavaScript tests (`npm test`). All business logic should be tested. The `rspec-testing` skill covers project-specific style.

- Tests should either: help make the code correct now or prevent bugs in the future. Don't add tests that don't do one of those things.
- Avoid mocking objects
- Never make a failing test pass by swapping its target for a fixture or a mock — keep tests exercising real code, and make the brittle expectation robust instead (e.g. derive the expected value from whatever varies)
- Ruby: Use `context` and `let` to isolate what varies between examples.
  - Each `it` block should live in a `context` that names the condition, with `let` overrides for only what differs in that case. Avoid repeating setup across sibling `it` blocks.
- JavaScript: Tests are in `index.test.js`. The vitest config pins `TZ=America/Chicago` for deterministic output.

## Pull requests

When creating a PR, run the `/pr` workflow rather than calling `gh pr create` directly.

## Subagents

When a command fans out to subagents — `/simplify`, `/code-review`, or an ad-hoc fan-out — pick the model by how much of the *search* the agent has to invent, not by how simple the task sounds:

- **`model: "haiku"`** when the command is already specified: "run this grep and summarise it", "read these four files and pull out X". There's nothing to devise.
- **`model: "sonnet"`** when the agent has to work out *how* to look ("every call site of X", "which specs touch Y"). A weaker model compensates by flailing — on a real enumeration it reached the same answer as sonnet, but took 3x the tool calls, 1.6x the wall clock and more total tokens, so the per-token discount didn't survive.
- **Omit `model:`** (inherit the session model) for judgement — the passes that catch a subtly wrong parse or a shared helper's edge case.

Worth delegating enumeration at all rather than eyeballing a grep: in that same test both subagents found two call sites the hand-written grep missed, because it anchored on the wrong method name.
