FROM colmap/colmap@sha256:187ca5ec98e55ed8fbec5f43f9d8f78b7a322b3b7413356634191f7a43c1efcf

LABEL org.opencontainers.image.title="cloud-workstation"
LABEL org.opencontainers.image.version="headless-surveyor-v0.1-dev"
LABEL org.opencontainers.image.description="Headless COLMAP image for photogrammetry reconstruction before Gaussian Splatting training."
LABEL org.opencontainers.image.base.name="colmap/colmap@sha256:187ca5ec98e55ed8fbec5f43f9d8f78b7a322b3b7413356634191f7a43c1efcf"

ENV SURVEYOR_IMAGE_VERSION=headless-surveyor-v0.1-dev
ENV WORKSPACE_ROOT=/workspace
ENV INCOMING_DIR=/workspace/incoming
ENV SCENES_DIR=/workspace/scenes
ENV LOGS_DIR=/workspace/logs
ENV ARCHIVES_DIR=/workspace/archives
ENV TEMP_DIR=/workspace/temp

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        coreutils \
        curl \
        ffmpeg \
        findutils \
        gzip \
        jq \
        python3 \
        rsync \
        sqlite3 \
        tar \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/runpod-keepalive.sh /usr/local/bin/runpod-keepalive.sh
COPY scripts/validate-surveyor.sh /usr/local/bin/validate-surveyor.sh
COPY scripts/survey-scene.sh /usr/local/bin/survey-scene.sh
COPY scripts/package-surveyor-scene.sh /usr/local/bin/package-surveyor-scene.sh

RUN mkdir -p \
    /workspace/incoming \
    /workspace/scenes \
    /workspace/logs \
    /workspace/archives \
    /workspace/temp \
    && chmod +x \
    /usr/local/bin/runpod-keepalive.sh \
    /usr/local/bin/validate-surveyor.sh \
    /usr/local/bin/survey-scene.sh \
    /usr/local/bin/package-surveyor-scene.sh

WORKDIR /workspace

ENTRYPOINT []
CMD ["runpod-keepalive.sh"]
