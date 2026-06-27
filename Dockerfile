FROM colmap/colmap:20240723.601@sha256:73003557e3ffa36d801e71b7630c117f9d373c55f24e3afc6791b9b3d1ec01da

ARG COLMAP_VERSION=3.10
ARG COLMAP_COMMIT=0bd66d901c7549051e21e8f648777f802eb20a73
ARG CUDA_BASE_VERSION=12.3.1
ARG UBUNTU_VERSION=22.04
ARG GDOWN_VERSION=6.1.0

LABEL org.opencontainers.image.title="cloud-workstation"
LABEL org.opencontainers.image.version="headless-surveyor-v0.1-dev"
LABEL org.opencontainers.image.description="Headless COLMAP image for photogrammetry reconstruction before Gaussian Splatting training."
LABEL org.opencontainers.image.base.name="colmap/colmap:20240723.601@sha256:73003557e3ffa36d801e71b7630c117f9d373c55f24e3afc6791b9b3d1ec01da"
LABEL io.cloud-workstation.colmap.version="${COLMAP_VERSION}"
LABEL io.cloud-workstation.colmap.commit="${COLMAP_COMMIT}"
LABEL io.cloud-workstation.cuda.version="${CUDA_BASE_VERSION}"
LABEL io.cloud-workstation.ubuntu.version="${UBUNTU_VERSION}"
LABEL io.cloud-workstation.gdown.version="${GDOWN_VERSION}"

ARG RUNPODCTL_VERSION=2.5.0
ARG RUNPODCTL_SHA256=f484ce7d790ddc6b4a63363f3c975c70fa87bf3be1bcbad019812f6e3f4ba54e

ENV SURVEYOR_IMAGE_VERSION=headless-surveyor-v0.1-dev
ENV SURVEYOR_COLMAP_VERSION=${COLMAP_VERSION}
ENV SURVEYOR_COLMAP_COMMIT=${COLMAP_COMMIT}
ENV SURVEYOR_CUDA_VERSION=${CUDA_BASE_VERSION}
ENV SURVEYOR_UBUNTU_VERSION=${UBUNTU_VERSION}
ENV SURVEYOR_GDOWN_VERSION=${GDOWN_VERSION}
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
        python3-pip \
        rsync \
        sqlite3 \
        tar \
    && rm -rf /var/lib/apt/lists/*

COPY requirements-gdown.txt /tmp/requirements-gdown.txt

RUN python3 -m pip install \
        --no-cache-dir \
        --only-binary=:all: \
        --require-hashes \
        -r /tmp/requirements-gdown.txt \
    && rm -f /tmp/requirements-gdown.txt \
    && gdown --version | grep -F "${GDOWN_VERSION}"

RUN curl -fsSL \
        "https://github.com/runpod/runpodctl/releases/download/v${RUNPODCTL_VERSION}/runpodctl-linux-amd64" \
        -o /usr/local/bin/runpodctl \
    && echo "${RUNPODCTL_SHA256}  /usr/local/bin/runpodctl" | sha256sum -c - \
    && chmod +x /usr/local/bin/runpodctl \
    && runpodctl version

COPY scripts/runpod-keepalive.sh /usr/local/bin/runpod-keepalive.sh
COPY scripts/validate-surveyor.sh /usr/local/bin/validate-surveyor.sh
COPY scripts/validate-surveyor-scene.sh /usr/local/bin/validate-surveyor-scene.sh
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
    /usr/local/bin/validate-surveyor-scene.sh \
    /usr/local/bin/survey-scene.sh \
    /usr/local/bin/package-surveyor-scene.sh

WORKDIR /workspace

ENTRYPOINT []
CMD ["runpod-keepalive.sh"]
