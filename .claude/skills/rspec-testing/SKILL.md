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

## What to test (and what not to)

- Tests should either: help make the code correct now, or prevent bugs in the future. Don't add tests that don't do one of those things.
- Avoid testing private methods (in functionable modules, those are the `conceal`ed methods) — test them through the public surface that calls them.
- Avoid mocking objects. Drive the real code path with real inputs.

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
