# Bloom web image: both Flutter Web apps behind nginx, plus the /api/ reverse proxy.
# Build context is the REPO ROOT: the Flutter code is a pub workspace (root
# pubspec.yaml lists apps/* and packages/*), so the whole workspace is copied.

# ---------------------------------------------------------------- stage 1: build
FROM debian:bookworm-slim AS build

# Flutter 3.50.0 stable, pinned by version and sha256 (no official 3.50.0 image exists).
ARG FLUTTER_VERSION=3.50.0
ARG FLUTTER_SHA256=6ea2d806fd57269ae783e6788e2a81fc26eaad782f1e0d0ff38623bb765ff9f5

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/flutter.tar.xz \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
 && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/flutter.tar.xz -C /opt \
 && rm /tmp/flutter.tar.xz \
 && git config --global --add safe.directory /opt/flutter

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH" \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    PUB_CACHE=/root/.pub-cache

RUN flutter config --no-analytics --no-cli-animations \
 && flutter config --no-enable-android --no-enable-ios --no-enable-linux-desktop --no-enable-macos-desktop --no-enable-windows-desktop \
 && flutter precache --web \
 && flutter --version

WORKDIR /src

# Resolve the workspace from the manifests first so the pub cache layer is reused.
COPY pubspec.yaml pubspec.lock analysis_options.yaml ./
COPY apps/patient/pubspec.yaml apps/patient/
COPY apps/clinic/pubspec.yaml apps/clinic/
COPY packages/bloom_ui/pubspec.yaml packages/bloom_ui/
COPY packages/core_domain/pubspec.yaml packages/core_domain/
COPY packages/core_data/pubspec.yaml packages/core_data/
COPY packages/l10n/pubspec.yaml packages/l10n/
RUN flutter pub get

COPY apps ./apps
COPY packages ./packages

ARG API_BASE_URL=/api
RUN flutter pub get \
 && (cd packages/l10n && flutter gen-l10n) \
 && (cd apps/patient && flutter build web --release --base-href /intake/ --dart-define=API_BASE_URL=${API_BASE_URL}) \
 && (cd apps/clinic && flutter build web --release --base-href /doctor/ --dart-define=API_BASE_URL=${API_BASE_URL})

# ---------------------------------------------------------------- stage 2: serve
FROM nginx:1.28.0-alpine

RUN rm -f /etc/nginx/conf.d/default.conf
COPY deploy/nginx.conf /etc/nginx/conf.d/bloom.conf
COPY --from=build /src/apps/patient/build/web /usr/share/nginx/html/intake
COPY --from=build /src/apps/clinic/build/web /usr/share/nginx/html/doctor

EXPOSE 80
HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD wget -q -O /dev/null http://127.0.0.1/intake/ || exit 1
