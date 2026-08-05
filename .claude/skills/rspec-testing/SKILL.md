---
name: rspec-testing
description: >-
  Binxtils' RSpec testing conventions — how to structure specs with
  `context` and `let`, what kinds of tests to write, and what to avoid
  (mocks, weakened assertions, testing private methods). Trigger when
  writing or modifying any `*_spec.rb` file, adding test coverage for new
  code, refactoring tests, or designing the test layout for a new module.
  Includes Good/Bad examples of the project's preferred style. (For
  JavaScript, the Vitest tests live in `index.test.js`.)
---

# RSpec testing in Binxtils

Binxtils is a Ruby gem (the npm package's tests use Vitest in
`index.test.js`). This project uses RSpec; all business logic should be
tested. Run the suite with `bin/rspec`.

## Run only the specs your change touches

Pass the files or directories you changed — `bin/rspec spec/binxtils/time_parser_spec.rb`.
A bare `bin/rspec` runs everything including the `type: :system` specs,
which boot the dummy Rails app. CI runs the full suite.

When something fails outside the files you changed, re-run that spec file
on its own before treating it as yours. Passing alone means the full run
was order-dependent; failing alone means it's real — and a real failure
gets fixed, never excused as pre-existing.

## What to test (and what not to)

- Tests should either: help make the code correct now, or prevent bugs in the future. Don't add tests that don't do one of those things.
- Avoid testing private methods (in functionable modules, those are the `conceal`ed methods) — test them through the public surface that calls them.
- Avoid mocking objects. Drive the real code path with real inputs.

## Stubbing ENV

Never partial-mock `ENV` with `allow(ENV).to receive(:[]).and_call_original` —
it makes every subsequent `ENV[...]` lookup go through RSpec's message
router, which is slow and easy to break by forgetting a `.with(...)` branch.

Use `stub_const` against a merged hash instead:

### Good

```ruby
stub_const("ENV", ENV.to_hash.merge("SECRET_TOKEN" => "test_token"))
```

### Bad

```ruby
allow(ENV).to receive(:[]).and_call_original
allow(ENV).to receive(:[]).with("SECRET_TOKEN").and_return("test_token")
```

## Always fix failing tests

Fix every failing test, even ones that were already failing on `main`. Confirming a failure pre-dates your branch (via `git stash` or checking out `main`) explains *what* broke — not whether you fix it. You fix it.

## Don't weaken assertions to make a failing test pass

When a test goes red, the correct move is **investigate why**, not edit the assertion to match the new output. Watch for these tempting "fixes" that are actually erasing signal:

- Changing an expected value to whatever the code now happens to return (e.g. an exact count → a range, a specific string → a substring/regex).
- Loosening `eq` to `include`, dropping `count:` constraints, or replacing `expect(...).to ...` with `expect(...).not_to be_nil`.
- Deleting the assertion entirely with a "looks unrelated" handwave.

The right loop: reproduce the failure, figure out *what* changed and *why*, then decide intentionally — fix the code if the original assertion captured the right behavior, or update the assertion (with a comment) if the behavior intentionally changed. If you're about to change a test "to make it easier", stop and explain why the new expectation is correct, not just convenient.

## Match a target attributes hash, not one attribute at a time

When you're checking several fields on the same object or result, build one expected hash and assert against it in a single matcher. Don't write a chain of one-attribute-per-line `expect`s.

- Object: `expect(record).to have_attributes(target_attributes)`
- Hash (parsed result, JSON): `expect(hash).to eq(target)` for a full match, or `expect(hash).to include(target_attributes)` for partial.

This collapses several brittle assertions into one, makes the *contract* visible at a glance, and gives a single readable diff when something changes. It also avoids the trap of weak per-field assertions like `expect(x).to be_present` standing in for "the right value" — match the value directly.

### Good

```ruby
target_attributes = {kind: "found", description: "Some description"}
expect(result).to have_attributes(target_attributes)
```

### Bad

```ruby
expect(result.kind).to eq("found")
expect(result.description).to be_present
expect(result.description).to eq("Some description")
```

The bad version spreads one logical assertion across many lines, mixes weak presence checks with the real expected value, and produces noisier failure output.

## Structuring with `context` and `let`

Use `context` and `let` to isolate what varies between examples. Each `it` block should live in a `context` that names the condition, with `let` overrides for only what differs in that case. **Avoid repeating setup across sibling `it` blocks.**

### Good

```ruby
RSpec.describe Binxtils::TimeZoneParser, type: :service do
  let(:subject) { described_class }

  describe "parse" do
    let(:target_time_zone) { ActiveSupport::TimeZone[time_zone_str] }

    context "America/Los_Angeles" do
      let(:time_zone_str) { "America/Los_Angeles" }
      it "returns the correct time_zone" do
        expect(subject.parse(time_zone_str)).to eq target_time_zone
        expect(subject.parse(time_zone_str).utc_offset).to eq(-28800)
      end
    end

    context "with an offset prefix" do
      let(:time_zone_str) { "(GMT-07:00) America/Denver" }
      let(:target_time_zone) { ActiveSupport::TimeZone["America/Denver"] }
      it "strips the offset and returns the zone" do
        expect(subject.parse(time_zone_str)).to eq target_time_zone
      end
    end

    context "blank" do
      it "returns nil" do
        expect(subject.parse("")).to be_nil
        expect(subject.parse(nil)).to be_nil
      end
    end
  end
end
```

### Bad

```ruby
it "returns LA" do
  parser = Binxtils::TimeZoneParser
  expect(parser.parse("America/Los_Angeles")).to eq ActiveSupport::TimeZone["America/Los_Angeles"]
end
it "returns Denver from an offset" do
  parser = Binxtils::TimeZoneParser
  allow(parser).to receive(:something) { true }
  expect(parser.parse("(GMT-07:00) America/Denver")).to eq ActiveSupport::TimeZone["America/Denver"]
end
```

The bad version repeats setup, mocks the object, and doesn't communicate what each case represents.

## One example per distinct setup — combine same-setup `it` blocks

`context`/`let`/`before` isolate what *varies*. The corollary runs the other way: if two sibling `it` blocks share the **same** setup — no differing `context`, `before`, or `let` override between them — collapse them into **one** example. Each distinct setup earns exactly one `it`; put all of that setup's assertions in that single block.

Splitting same-setup assertions across sibling `it` blocks re-runs identical setup once per block for zero isolation benefit, and scatters one logical behavior across the file. Two `it` blocks that differ *only* in the argument passed or the assertion — with identical `let`s and no `before` between them — are one example.

After writing a spec, scan each `context`/`describe`: if it holds multiple `it` blocks and they don't each sit behind a distinct `context`/`before`/`let`, merge them.

### Good

```ruby
context "in America/Chicago" do
  let(:time_zone) { ActiveSupport::TimeZone["America/Chicago"] }

  it "parses each supported format" do
    expect(subject.parse("2024-01-15", time_zone)).to eq time_zone.parse("2024-01-15")
    expect(subject.parse("01/15/2024", time_zone)).to eq time_zone.parse("2024-01-15")
    expect(subject.parse("2024-01-15 13:00", time_zone)).to eq time_zone.parse("2024-01-15 13:00")
  end
end
```

### Bad

```ruby
context "in America/Chicago" do
  let(:time_zone) { ActiveSupport::TimeZone["America/Chicago"] }   # re-built for every it below

  it "parses an ISO date" do
    expect(subject.parse("2024-01-15", time_zone)).to eq time_zone.parse("2024-01-15")
  end
  it "parses a US date" do
    expect(subject.parse("01/15/2024", time_zone)).to eq time_zone.parse("2024-01-15")
  end
  it "parses a datetime" do
    expect(subject.parse("2024-01-15 13:00", time_zone)).to eq time_zone.parse("2024-01-15 13:00")
  end
end
```

This only merges blocks whose setup is identical. Different setup still means separate examples, each in its own `context` with the `let`/`before` that differs — that's the section above, not a contradiction of it.
