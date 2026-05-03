FROM alpine:latest AS source
ARG MASTODON_VERSION

RUN apk add --no-cache ca-certificates curl tar
WORKDIR /src
RUN set -eux; \
  test -n "$MASTODON_VERSION"; \
  curl -fsSL "https://github.com/mastodon/mastodon/archive/refs/tags/v${MASTODON_VERSION}.tar.gz" \
  | tar -xz --strip-components=1

FROM alpine:latest AS build

ENV RAILS_ENV=production \
  NODE_ENV=production \
  BUNDLE_DEPLOYMENT=true \
  BUNDLE_WITHOUT=development:test \
  BUNDLE_PATH=/usr/local/bundle \
  GEM_HOME=/usr/local/bundle \
  GEM_PATH=/usr/local/bundle \
  PATH=/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apk add --no-cache \
  build-base \
  ca-certificates \
  curl \
  gdbm-dev \
  git \
  gmp-dev \
  hiredis-dev \
  icu-dev \
  jemalloc-dev \
  libidn-dev \
  libxml2-dev \
  libxslt-dev \
  linux-headers \
  nodejs \
  npm \
  openssl-dev \
  pkgconf \
  postgresql18-dev \
  protobuf-dev \
  ruby \
  ruby-dev \
  vips-dev \
  yaml-dev \
  zlib-dev

WORKDIR /opt/mastodon
COPY --from=source /src/ ./

RUN set -eux; \
  bundler_version="$(sed -n '/^BUNDLED WITH$/{n;s/^[[:space:]]*//;p;q;}' Gemfile.lock)"; \
  gem install --no-document bundler -v "$bundler_version"; \
  bundle "_${bundler_version}_" config set frozen true; \
  bundle "_${bundler_version}_" config set without "development test"; \
  bundle "_${bundler_version}_" config set build.nokogiri "--use-system-libraries"; \
  bundle "_${bundler_version}_" install -j"$(nproc)"; \
  rm -rf /usr/local/bundle/cache /root/.bundle/cache

RUN set -eux; \
  npm install -g corepack; \
  corepack enable; \
  yarn_version="$(node -p 'require("./package.json").packageManager.split("@").pop()')"; \
  corepack prepare "yarn@${yarn_version}" --activate; \
  yarn workspaces focus --production @mastodon/mastodon @mastodon/streaming; \
  SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile; \
  yarn workspaces focus --production @mastodon/streaming; \
  yarn cache clean; \
  rm -rf /root/.cache /tmp/* /opt/mastodon/tmp/cache

RUN set -eux; \
  rm -rf \
    .annotaterb.yml \
    .browserslistrc \
    .buildpacks \
    .devcontainer \
    .editorconfig \
    .env.development \
    .env.production.sample \
    .env.test \
    .env.vagrant \
    .foreman \
    .gitattributes \
    .github \
    .gitignore \
    .haml-lint.yml \
    .nvmrc \
    .oxfmtrc.json \
    .rspec \
    .rubocop \
    .rubocop.yml \
    .rubocop_todo.yml \
    .ruby-gemset \
    .slugignore \
    .storybook \
    .watchmanconfig \
    Aptfile \
    AUTHORS.md \
    CHANGELOG.md \
    CODE_OF_CONDUCT.md \
    CONTRIBUTING.md \
    Dockerfile \
    FEDERATION.md \
    Procfile \
    Procfile.dev \
    README.md \
    SECURITY.md \
    Vagrantfile \
    app.json \
    chart \
    crowdin.yml \
    dist \
    docker-compose.yml \
    eslint.config.mjs \
    docs \
    jsconfig.json \
    lint-staged.config.js \
    priv-config \
    publiccode.yml \
    scalingo.json \
    spec \
    stylelint.config.js \
    storybook-static \
    tsconfig.json \
    vitest.config.mts \
    vitest.shims.d.ts \
    public/packs-test; \
  [ ! -d app/javascript ] || find app/javascript -type d \( -name __tests__ -o -name __mocks__ -o -name __snapshots__ \) -prune -exec rm -rf {} +; \
  [ ! -d app/javascript ] || find app/javascript -type f \( -name "*.stories.*" -o -name "*.test.*" -o -name "*-test.*" -o -name "*.spec.*" \) -delete; \
  find /usr/local/bundle -type f \( -name "*.o" -o -name "*.gem" \) -delete; \
  [ ! -d node_modules ] || find node_modules -type d -name .cache -prune -exec rm -rf {} +; \
  [ ! -d node_modules ] || find node_modules -type f -name "*.tsbuildinfo" -delete; \
  [ ! -d public ] || find public -type f -name "*.map" -delete; \
  find /usr/local/bundle node_modules -type f \( -name "*.so" -o -name "*.node" \) -exec strip --strip-unneeded {} + 2>/dev/null || true

FROM alpine:latest
ARG MASTODON_VERSION

LABEL org.opencontainers.image.title="mastodon" \
  org.opencontainers.image.description="Alpine all-in-one Mastodon image built from upstream source" \
  org.opencontainers.image.source="https://github.com/mastodon/mastodon" \
  org.opencontainers.image.version="${MASTODON_VERSION}" \
  org.opencontainers.image.licenses="AGPL-3.0-or-later"

ENV RAILS_ENV=production \
  NODE_ENV=production \
  RAILS_SERVE_STATIC_FILES=false \
  BIND=0.0.0.0 \
  PORT=3000 \
  WEB_CONCURRENCY=0 \
  MIN_THREADS=1 \
  MAX_THREADS=1 \
  DB_POOL=1 \
  SIDEKIQ_CONCURRENCY=1 \
  STREAMING_CLUSTER_NUM=1 \
  RUBY_YJIT_ENABLE=0 \
  NODE_OPTIONS=--max-old-space-size=24 \
  REDIS_HOST=127.0.0.1 \
  REDIS_PORT=6379 \
  REDIS_DATA=/var/lib/redis \
  DB_HOST=/run/postgresql \
  DB_PORT=5432 \
  DB_USER=postgres \
  DB_NAME=mastodon_production \
  DB_PASS= \
  PGDATA=/var/lib/postgresql/data \
  REDIS_MAXMEMORY=24mb \
  POSTGRES_SHARED_BUFFERS=16MB \
  POSTGRES_EFFECTIVE_CACHE_SIZE=32MB \
  POSTGRES_MAINTENANCE_WORK_MEM=8MB \
  POSTGRES_WORK_MEM=1MB \
  POSTGRES_MAX_CONNECTIONS=4 \
  POSTGRES_WAL_BUFFERS=4MB \
  BUNDLE_DEPLOYMENT=true \
  BUNDLE_WITHOUT=development:test \
  BUNDLE_PATH=/usr/local/bundle \
  GEM_HOME=/usr/local/bundle \
  GEM_PATH=/usr/local/bundle \
  PATH=/opt/mastodon/bin:/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  RUBY_JEMALLOC=/usr/lib/libjemalloc.so.2 \
  MALLOC_CONF=narenas:1,background_thread:true,thp:never,dirty_decay_ms:100,muzzy_decay_ms:0,retain:false \
  RUBY_GC_HEAP_INIT_SLOTS=1500 \
  RUBY_GC_HEAP_FREE_SLOTS=200 \
  RUBY_GC_HEAP_GROWTH_FACTOR=1.02 \
  RUBY_GC_HEAP_GROWTH_MAX_SLOTS=500 \
  RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=1.0 \
  RUBY_GC_MALLOC_LIMIT=131072 \
  RUBY_GC_MALLOC_LIMIT_MAX=524288 \
  RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR=1.02 \
  RUBY_GC_OLDMALLOC_LIMIT=131072 \
  RUBY_GC_OLDMALLOC_LIMIT_MAX=524288 \
  RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR=1.02

RUN apk add --no-cache \
  ca-certificates \
  caddy \
  ffmpeg \
  file \
  hiredis \
  icu-libs \
  jemalloc \
  libidn \
  libpq \
  libxml2 \
  libxslt \
  nodejs \
  postgresql18 \
  postgresql18-client \
  postgresql18-contrib \
  redis \
  ruby \
  shared-mime-info \
  su-exec \
  tini \
  tzdata \
  vips \
  yaml; \
  addgroup -g 991 -S mastodon; \
  adduser -S -D -H -h /opt/mastodon -u 991 -G mastodon mastodon; \
  ln -s /opt/mastodon /mastodon; \
  mkdir -p /opt/mastodon /run/postgresql /var/lib/postgresql/data /var/log/postgresql /var/lib/redis; \
  chown -R mastodon:mastodon /opt/mastodon; \
  chown -R redis:redis /var/lib/redis; \
  chown -R postgres:postgres /run/postgresql /var/lib/postgresql /var/log/postgresql; \
  chmod 3775 /run/postgresql; \
  rm -rf /var/cache/apk/* /usr/share/man /usr/share/doc /usr/share/ri /tmp/*

WORKDIR /opt/mastodon
COPY --from=build /usr/local/bundle/ /usr/local/bundle/
COPY --from=build /opt/mastodon/ /opt/mastodon/
COPY --chmod=755 entrypoint /entrypoint

RUN mkdir -p /opt/mastodon/public/system /opt/mastodon/tmp; \
  chown -R mastodon:mastodon /opt/mastodon/public/system /opt/mastodon/tmp

VOLUME ["/mastodon/public/system", "/var/lib/postgresql/data", "/var/lib/redis"]
EXPOSE 80 443
ENTRYPOINT ["/usr/bin/env", \
  "-u", "DATABASE_URL", \
  "-u", "REDIS_URL", \
  "-u", "CACHE_REDIS_URL", \
  "-u", "SIDEKIQ_REDIS_URL", \
  "PGDATA=/var/lib/postgresql/data", \
  "DB_HOST=/run/postgresql", \
  "DB_PORT=5432", \
  "REDIS_HOST=127.0.0.1", \
  "REDIS_PORT=6379", \
  "/sbin/tini", "--", "/entrypoint"]
