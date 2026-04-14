# Binxtils

Bike Index utility modules. Install it by adding the following line to your Gemfile

```ruby
gem "binxtils"
```

## Modules

- **Binxtils::InputNormalizer** - Sanitize and normalize user input strings
- **Binxtils::TimeParser** - Parse fuzzy time/date strings into `Time` objects
- **Binxtils::TimeZoneParser** - Parse and resolve time zone strings

### Functionable modules

These modules use [Functionable](https://github.com/sethherr/functionable) and are called as class methods:

```ruby
Binxtils::TimeParser.parse("next thursday")
Binxtils::InputNormalizer.string("  Some Input  ")
Binxtils::TimeZoneParser.parse("Eastern Time")
```

### Rails concerns

- **Binxtils::SetPeriod** - Controller concern for time period filtering (hour, day, week, month, year, all, custom). Parses period params, manages timezones, and sets `@time_range`.
- **Binxtils::SortableTable** - Controller concern providing `sort_column` and `sort_direction` helpers with configurable defaults.
- **Binxtils::SortableHelper** - View helper for rendering sortable column header links with active-state indicators.

Include them in your controllers and helpers:

```ruby
class ApplicationController < ActionController::Base
  include Binxtils::SetPeriod
  include Binxtils::SortableTable

  # Optionally configure the earliest date for the "all" period
  self.default_earliest_time = Time.at(1714460400).freeze
end

module ApplicationHelper
  include Binxtils::SortableHelper

  # Optionally extend the permitted search params
  def default_search_keys
    super + [:organization_id, query_items: []]
  end
end
```

`SortableTable` requires a `sortable_columns` method in your controller:

```ruby
class BikesController < ApplicationController
  def sortable_columns
    %w[created_at updated_at manufacturer_id]
  end
end
```

## npm package

This repo also publishes `@bikeindex/time-localizer`, an npm package for localizing time elements in the browser. Luxon is bundled into the published package, so consumers don't need to install it separately.

To publish a new version: update the version in `package.json`, then run `npm publish` from the repo root (requires npm login with access to the `@bikeindex` scope). The `prepublishOnly` script automatically builds `dist/index.js` before publishing.

## Releasing

From the `main` branch, run `bin/release` with a version number:

```
bin/release 0.3.0
```

This bumps the version, commits, tags, pushes, builds and publishes the gem to RubyGems, and creates a GitHub release.
