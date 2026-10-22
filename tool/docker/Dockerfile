# syntax=docker/dockerfile:1
FROM debian@sha256:62bd423aeee912639ca8ee681c2b762cb3e25137e0a92b20be455898a9f034ad

# Session trust is supplied during builds, never copied into the image.
RUN --mount=type=secret,id=system_ca,required=true \
    apt-get -o Acquire::http::Proxy="$HTTP_PROXY" \
            -o Acquire::https::Proxy="$HTTPS_PROXY" \
            -o Acquire::https::CaInfo=/run/secrets/system_ca update \
    && apt-get -o Acquire::http::Proxy="$HTTP_PROXY" \
               -o Acquire::https::Proxy="$HTTPS_PROXY" \
               -o Acquire::https::CaInfo=/run/secrets/system_ca install -y --no-install-recommends \
       ca-certificates curl git unzip xz-utils python3 openjdk-21-jdk-headless \
       libstdc++6 libglu1-mesa libpulse0 libnss3 libxkbcommon0 libx11-6 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --uid 1000 --create-home --shell /bin/bash builder

COPY --chmod=755 tool/docker/entrypoint.sh /usr/local/bin/worktime-entrypoint
USER builder
WORKDIR /workspace/repository-of-codex
ENTRYPOINT ["/usr/local/bin/worktime-entrypoint"]
