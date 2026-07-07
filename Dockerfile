FROM ghcr.io/cirruslabs/flutter:3.29.3 AS build

WORKDIR /app

# URL del backend propio; se inyecta como build arg desde Railway.
# Si queda vacia, la app usa su default compilado en app_config.dart.
ARG SALTA_API_BASE_URL=""

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN if [ -n "$SALTA_API_BASE_URL" ]; then \
      flutter build web --release --dart-define=SALTA_API_BASE_URL="$SALTA_API_BASE_URL"; \
    else \
      flutter build web --release; \
    fi

FROM caddy:2.8-alpine

COPY deploy/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/build/web /srv
