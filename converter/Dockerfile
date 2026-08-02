FROM node:22-slim

ARG INSTALL_SPLAT_TRANSFORM=1
ARG SPLAT_TRANSFORM_PACKAGE=@playcanvas/splat-transform

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /workspace

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gzip \
      python3 \
      tar \
      unzip \
      zip \
    && rm -rf /var/lib/apt/lists/*

RUN if [ "${INSTALL_SPLAT_TRANSFORM}" = "1" ]; then \
      npm install -g "${SPLAT_TRANSFORM_PACKAGE}" || \
      echo "WARNING: splat-transform install failed; Converter will skip tool-backed formats at runtime."; \
    fi

COPY converter /workspace/converter
COPY docs/converter-*.md /workspace/docs/

RUN chmod +x /workspace/converter/scripts/*.sh \
    && /workspace/converter/scripts/validate-converter.sh

ENTRYPOINT ["/workspace/converter/scripts/convert-scene.sh"]
