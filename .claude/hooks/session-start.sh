#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

RUBY_VERSION=3.4.9

log() { echo "[session-start] $*" >&2; }

install_ruby() {
  if [ -x "/opt/rbenv/versions/${RUBY_VERSION}/bin/ruby" ]; then
    log "Ruby ${RUBY_VERSION} already installed"
    return
  fi

  # cache.ruby-lang.org is blocked in this environment, so we build from a
  # GitHub source snapshot. The snapshot lacks ./configure and the bundled
  # gem .gem files; we generate the former with autogen.sh and prefetch
  # the latter from rubygems.org (which is reachable), then hand a repacked
  # tarball to ruby-build via a local definition.
  log "Installing Ruby ${RUBY_VERSION} from GitHub snapshot"
  local cache=/tmp/ruby-cache
  local src=/tmp/ruby-${RUBY_VERSION}-src
  mkdir -p "$cache"
  rm -rf "$src"
  mkdir -p "$src"

  local github_tag
  github_tag="v$(echo "$RUBY_VERSION" | tr . _)"
  curl -sfL -o "$cache/ruby-src.tar.gz" \
    "https://github.com/ruby/ruby/archive/refs/tags/${github_tag}.tar.gz"
  tar -xzf "$cache/ruby-src.tar.gz" -C "$src" --strip-components=1

  ( cd "$src" && ./autogen.sh >/dev/null )

  log "Pre-fetching bundled gems"
  while read -r line; do
    case "$line" in ""|\#*) continue ;; esac
    set -- $line
    local gem_file="$1-$2.gem"
    [ -f "$src/gems/$gem_file" ] || \
      curl -sfL -o "$src/gems/$gem_file" "https://rubygems.org/downloads/$gem_file"
  done < "$src/gems/bundled_gems"

  local tarball="$cache/ruby-${RUBY_VERSION}.tar.gz"
  ( cd "$src" && tar czf "$tarball" . --transform "s,^\.,ruby-${RUBY_VERSION}," )
  local sha
  sha=$(sha256sum "$tarball" | awk '{print $1}')

  mkdir -p "$HOME/.local/share/ruby-build"
  cat > "$HOME/.local/share/ruby-build/${RUBY_VERSION}-local" <<EOF
install_package "ruby-${RUBY_VERSION}" "file://${tarball}#${sha}" enable_shared standard
EOF

  RUBY_BUILD_DEFINITIONS="$HOME/.local/share/ruby-build" \
    /opt/rbenv/plugins/ruby-build/bin/ruby-build \
    "${RUBY_VERSION}-local" "/opt/rbenv/versions/${RUBY_VERSION}"

  rbenv rehash
}

start_postgres() {
  if pg_isready -q 2>/dev/null; then
    log "Postgres already running"
  else
    log "Starting Postgres"
    service postgresql start >/dev/null
    until pg_isready -q; do sleep 1; done
  fi

  if ! su postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='rails'\"" | grep -q 1; then
    log "Creating rails Postgres role"
    su postgres -c "psql -c \"CREATE USER rails WITH SUPERUSER PASSWORD 'password';\"" >/dev/null
  fi

  if ! su postgres -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='binxtils_test'\"" | grep -q 1; then
    log "Creating binxtils_test database"
    su postgres -c "createdb -O rails binxtils_test"
  fi
}

install_ruby
start_postgres

export RBENV_VERSION="$RUBY_VERSION"
eval "$(rbenv init - bash)"

log "Running bundle install"
bundle install --quiet

log "Running npm install"
npm install --silent --no-audit --no-fund

cat >> "$CLAUDE_ENV_FILE" <<EOF
export RBENV_VERSION=$RUBY_VERSION
export PATH=/opt/rbenv/versions/$RUBY_VERSION/bin:\$PATH
export PGUSER=rails
export PGPASSWORD=password
export PGHOST=localhost
EOF

log "Done"
