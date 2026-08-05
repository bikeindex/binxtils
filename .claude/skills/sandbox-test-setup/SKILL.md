---
name: sandbox-test-setup
description: >-
  Binxtils Ruby + RSpec + npm environment setup. Two environments:
  **(A) local macOS Conductor workspace** (`/Users/…/conductor/workspaces/…`)
  — Ruby is installed via mise but Claude Code's shell sometimes spawns
  subprocesses without the mise shim, so bare `ruby`/`bundle` falls back
  to system 2.6 and fails with `Could not find 'bundler'` or
  `Bundler::RubyVersionMismatch`. Fix is a PATH prefix, not a reinstall.
  **(B) Claude Code's Linux web sandbox** — Ruby 3.4.9 must be built from
  a GitHub source clone (`cache.ruby-lang.org` is firewalled), plus a
  postgres `rails` superuser and the `binxtils_test` database, then
  `bundle install` and `npm install`. Trigger whenever a session runs
  `bin/rspec`, `bin/lint`, `bundle`, `npm test`, or the user reports
  `Could not find 'bundler'`, `Bundler::RubyVersionMismatch`,
  `command not found: rspec`, a postgres connection error, or a missing
  `binxtils_test` database.
---

# Running Ruby + RSpec + npm for Binxtils

Binxtils is a Ruby gem that also publishes the `@bikeindex/time-localizer`
npm package. Tests run with RSpec (`bin/rspec`) and Vitest (`npm test`).
Postgres is used by the specs (the `binxtils_test` database).

Pick the section matching the environment by its path: macOS paths under
`/Users/…/conductor/workspaces/…` use **Local macOS**; the Linux web
sandbox uses **Claude Code web sandbox**.

## Local macOS (Conductor workspace)

Ruby 3.4.9 is installed via [mise](https://mise.jdx.dev/) (pinned in
`.tool-versions`), but Claude Code's shell sometimes spawns subprocesses
without the mise shim on PATH — bare `ruby` then resolves to
`/usr/bin/ruby` (2.6) and `bundle` fails with `Could not find 'bundler'`
or a `Bundler::RubyVersionMismatch`. **The Ruby is installed; the PATH
just isn't right** — don't reinstall, don't edit the Gemfile.

Check first; only prefix PATH if `ruby -v` doesn't already print 3.4.9
(`mise exec -- ruby`/`bundle` are unreliable in this harness — they can
still resolve to system 2.6, so use the direct prefix):

```bash
ruby -v
# If it's the system 2.6:
export PATH="$HOME/.local/share/mise/installs/ruby/3.4.9/bin:$PATH"
ruby -v   # should now print 3.4.9
```

Postgres is handled by your local dev environment. If specs can't
connect, confirm it's running and that a `binxtils_test` database exists
(see the **Services + DB** block below — the same SQL applies locally).

Then run the suites the normal way:

```bash
bin/rspec                 # Ruby specs
npm test                  # JavaScript (Vitest) tests
bin/lint                  # format + lint (bin/lint --no-fix to check only)
```

## Claude Code web sandbox

The session-start setup that used to live in a `SessionStart` hook is
captured here. Run it once per sandbox.

### One-shot Ruby 3.4.9 build

The project builds against **3.4.9**. No prebuilt binary is reachable
(`cache.ruby-lang.org` is firewalled), so build from the GitHub source
tag — about 8–10 min on a 4-core sandbox. Skip if
`/opt/rbenv/versions/3.4.9/bin/ruby -v` already prints 3.4.9.

Three quirks the block handles: (1) GitHub's archive-tarball endpoint
(`/archive/refs/tags/*.tar.gz`) and `codeload.github.com` **403 through
the sandbox proxy**, even though plain `git` over https to github.com
works — so clone the tag shallowly instead of `curl`-ing a tarball;
(2) the source tree ships no pre-generated `configure`, so `autogen.sh`
runs first; (3) it ships no bundled-gem `.gem` files, so we pre-fetch each
from rubygems.org (which is reachable) before handing a repacked tarball
to `ruby-build` via a local definition.

```bash
RUBY_VERSION=3.4.9
cache=/tmp/ruby-cache
src=/tmp/ruby-${RUBY_VERSION}-src
mkdir -p "$cache"; rm -rf "$src"

# 1. Source — shallow git clone of the tag. The archive tarball URL 403s
#    here; codeload does too. `git clone` over https is what works.
github_tag="v$(echo "$RUBY_VERSION" | tr . _)"
git clone --depth 1 --branch "$github_tag" https://github.com/ruby/ruby.git "$src"

# 2. Generate ./configure (the source tree doesn't ship it)
( cd "$src" && ./autogen.sh >/dev/null )

# 3. Pre-fetch the bundled gems the source tree omits
while read -r line; do
  case "$line" in ""|\#*) continue ;; esac
  set -- $line
  gem_file="$1-$2.gem"
  [ -f "$src/gems/$gem_file" ] || \
    curl -sfL -o "$src/gems/$gem_file" "https://rubygems.org/downloads/$gem_file"
done < "$src/gems/bundled_gems"

# 4. Repack and hand to ruby-build via a local definition
tarball="$cache/ruby-${RUBY_VERSION}.tar.gz"
( cd "$src" && tar czf "$tarball" . --transform "s,^\.,ruby-${RUBY_VERSION}," )
sha=$(sha256sum "$tarball" | awk '{print $1}')
mkdir -p "$HOME/.local/share/ruby-build"
cat > "$HOME/.local/share/ruby-build/${RUBY_VERSION}-local" <<EOF
install_package "ruby-${RUBY_VERSION}" "file://${tarball}#${sha}" enable_shared standard
EOF
RUBY_BUILD_DEFINITIONS="$HOME/.local/share/ruby-build" \
  /opt/rbenv/plugins/ruby-build/bin/ruby-build \
  "${RUBY_VERSION}-local" "/opt/rbenv/versions/${RUBY_VERSION}"
rbenv rehash

export RBENV_VERSION="$RUBY_VERSION"
eval "$(rbenv init - bash)"
ruby -v   # => ruby 3.4.9 ...
```

### Services + DB

Start postgres once per session; create the `rails` superuser and
`binxtils_test` database once per machine.

```bash
pg_isready -q || service postgresql start
until pg_isready -q; do sleep 1; done

# Once per machine:
su postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='rails'\"" | grep -q 1 || \
  su postgres -c "psql -c \"CREATE USER rails WITH SUPERUSER PASSWORD 'password';\""
su postgres -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='binxtils_test'\"" | grep -q 1 || \
  su postgres -c "createdb -O rails binxtils_test"

export PGUSER=rails PGPASSWORD=password PGHOST=localhost
```

### Install dependencies + run

```bash
bundle install
npm install --no-audit --no-fund

bin/rspec        # Ruby specs
npm test         # JavaScript (Vitest) tests
bin/lint         # format + lint
```

## Sandbox network: what's allowed vs. blocked

Quick probe: `curl -sIL --max-time 5 "https://<host>" -o /dev/null -w "%{http_code}\n"`.

- **Allowed**: github.com (git-over-https clone/fetch), rubygems.org,
  registry.npmjs.org, storage.googleapis.com, files.pythonhosted.org.
- **Blocked**: cache.ruby-lang.org, download.ruby-lang.org, api.github.com,
  most generic CDNs. Also GitHub's codeload / archive-tarball endpoints
  (`/archive/refs/tags/*.tar.gz`, `codeload.github.com`) 403 through the
  proxy — `git clone` the tag instead of downloading a tarball.

If a tool's default download URL is blocked, look for a GitHub or
npm-registry alternative before giving up — that's the whole reason the
Ruby build above clones source from GitHub and pulls bundled gems from
rubygems.
