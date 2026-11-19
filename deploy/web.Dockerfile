# syntax=docker/dockerfile:1.7
# Bloom web image: both Flutter Web apps behind nginx, plus the /api/ reverse proxy.
# Build context is the REPO ROOT: the Flutter code is a pub workspace (root
# pubspec.yaml lists apps/* and packages/*), so every member pubspec is copied
# before `pub get` and the workspace resolves against the root pubspec.lock.
#
# Layer order is chosen for fast rebuilds:
#   1. Flutter SDK + web precache          (changes only when FLUTTER_VERSION changes)
#   2. pub get on the manifests only        (changes only when a pubspec/lock changes)
#   3. packages/ + gen-l10n                 (shared code)
#   4. apps/patient build, 5. apps/clinic build  (a clinic-only edit skips the patient build)
# The pub cache is also a BuildKit cache mount, so a changed lockfile re-downloads
# only the packages that changed.

# ---------------------------------------------------------------- stage 1: build
FROM debian:bookworm-slim AS build

# Flutter 3.50.0 stable, pinned by version and sha256 (no official 3.50.0 image exists).
# sha256 from storage.googleapis.com/flutter_infra_release/releases/releases_linux.json
ARG FLUTTER_VERSION=3.50.0
ARG FLUTTER_SHA256=6ea2d806fd57269ae783e6788e2a81fc26eaad782f1e0d0ff38623bb765ff9f5

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL --retry 3 -o /tmp/flutter.tar.xz \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
 && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/flutter.tar.xz -C /opt \
 && rm /tmp/flutter.tar.xz \
 && git config --global --add safe.directory /opt/flutter

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH" \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    PUB_CACHE=/root/.pub-cache \
    CI=true

RUN flutter config --no-analytics --no-cli-animations \
 && flutter config --no-enable-android --no-enable-ios --no-enable-linux-desktop --no-enable-macos-desktop --no-enable-windows-desktop \
 && flutter precache --web \
 && flutter --version

WORKDIR /src

# Resolve the workspace from the manifests only, so this layer survives code edits.
COPY pubspec.yaml pubspec.lock analysis_options.yaml ./
COPY apps/patient/pubspec.yaml apps/patient/
COPY apps/clinic/pubspec.yaml apps/clinic/
COPY packages/bloom_ui/pubspec.yaml packages/bloom_ui/
COPY packages/core_domain/pubspec.yaml packages/core_domain/
COPY packages/core_data/pubspec.yaml packages/core_data/
COPY packages/l10n/pubspec.yaml packages/l10n/
RUN --mount=type=cache,id=bloom-pub-cache,target=/root/.pub-cache \
    flutter pub get

# Shared packages. gen-l10n regenerates the localizations from the ARB files so the
# build does not depend on generated files being committed.
COPY packages ./packages
RUN --mount=type=cache,id=bloom-pub-cache,target=/root/.pub-cache \
    (flutter pub get --offline || flutter pub get) \
 && cd packages/l10n && flutter gen-l10n

# Common flags for both apps:
#   --no-web-resources-cdn  bundle CanvasKit locally; the demo must not depend on gstatic.com
#   --web-content-hash      main.dart.<hash>.js etc., so nginx can cache them as immutable
#   --no-wasm-dry-run       skip the extra wasm compile (we ship the JS build)
#   API_BASE_URL=/api       same-origin relative path: no hostname is baked into the build
ARG API_BASE_URL=/api
ENV BLOOM_WEB_FLAGS="--release --no-web-resources-cdn --web-content-hash --no-source-maps --no-wasm-dry-run"

COPY apps/patient ./apps/patient
RUN --mount=type=cache,id=bloom-pub-cache,target=/root/.pub-cache \
    cd apps/patient \
 && flutter build web ${BLOOM_WEB_FLAGS} --base-href /intake/ --dart-define=API_BASE_URL=${API_BASE_URL}

COPY apps/clinic ./apps/clinic
RUN --mount=type=cache,id=bloom-pub-cache,target=/root/.pub-cache \
    cd apps/clinic \
 && flutter build web ${BLOOM_WEB_FLAGS} --base-href /doctor/ --dart-define=API_BASE_URL=${API_BASE_URL}

# ---------------------------------------------------------------- stage 2: serve
# Unprivileged nginx (uid 101, listens on 8080). Pinned by tag; same nginx as before.
FROM nginxinc/nginx-unprivileged:1.28.0-alpine

USER root
RUN rm -f /etc/nginx/conf.d/default.conf \
 && mkdir -p /etc/nginx/snippets
COPY deploy/nginx.conf /etc/nginx/conf.d/bloom.conf
COPY deploy/nginx-security-headers.conf /etc/nginx/snippets/bloom-security-headers.conf
COPY --from=build /src/apps/patient/build/web /usr/share/nginx/html/intake
COPY --from=build /src/apps/clinic/build/web /usr/share/nginx/html/doctor
COPY deploy/landing/ /usr/share/nginx/html/
USER 101
# Validate the config at build time; drop the pid file so the runtime nginx can create it.
RUN nginx -t && rm -f /tmp/nginx.pid

EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/intake/ || exit 1
