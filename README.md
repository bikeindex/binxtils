# Binxtils

Bike Index utility modules. Install it by adding the following line to your Gemfile

```ruby
gem "binxtils"
```

## Modules

- **Binxtils::InputNormalizer** - Sanitize and normalize user input strings
- **Binxtils::TimeParser** - Parse fuzzy time/date strings into `Time` objects
- **Binxtils::TimeZoneParser** - Parse and resolve time zone strings

## Usage

All modules use [Functionable](https://github.com/sethherr/functionable) and are called as class methods:

```ruby
Binxtils::TimeParser.parse("next thursday")
Binxtils::InputNormalizer.string("  Some Input  ")
Binxtils::TimeZoneParser.parse("Eastern Time")
```

## npm package

This repo also publishes `@bikeindex/time-localizer`, an npm package for localizing time elements in the browser. Luxon is bundled into the published package, so consumers don't need to install it separately.

To publish a new version: update the version in `package.json`, then run `npm publish` from the repo root (requires npm login with access to the `@bikeindex` scope). The `prepublishOnly` script automatically builds `dist/index.js` before publishing.
