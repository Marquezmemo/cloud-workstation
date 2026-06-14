FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5

LABEL org.opencontainers.image.title="cloud-workstation"
LABEL org.opencontainers.image.version="headless-gsplat-v0.1-dev"
LABEL org.opencontainers.image.description="Headless CUDA/PyTorch base image for Gaussian Splatting training on RunPod."
LABEL org.opencontainers.image.base.name="runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5"
LABEL io.cloud-workstation.gsplat.version="1.5.3"
LABEL io.cloud-workstation.gsplat.source="PyPI"

ARG GSPLAT_VERSION=1.5.3

ENV TRAINING_IMAGE_VERSION=headless-gsplat-v0.1-dev
ENV GSPLAT_VERSION=${GSPLAT_VERSION}
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV WORKSPACE_ROOT=/workspace
ENV DATASETS_DIR=/workspace/datasets
ENV SCENES_DIR=/workspace/scenes
ENV OUTPUTS_DIR=/workspace/outputs
ENV LOGS_DIR=/workspace/logs
ENV CHECKPOINTS_DIR=/workspace/checkpoints

RUN apt-get update \
    && apt-get install -y --no-upgrade \
        git \
        cmake \
        ninja-build \
        build-essential \
        ffmpeg \
        wget \
        curl \
        unzip \
        nano \
        htop \
        tmux \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements-gsplat.txt /tmp/requirements-gsplat.txt

RUN python -m pip install --no-cache-dir --upgrade-strategy only-if-needed -r /tmp/requirements-gsplat.txt \
    && rm -f /tmp/requirements-gsplat.txt

COPY scripts/validate-gpu.sh /usr/local/bin/validate-gpu.sh
COPY scripts/collect-training-diagnostics.sh /usr/local/bin/collect-training-diagnostics.sh

RUN mkdir -p \
    /workspace/datasets \
    /workspace/scenes \
    /workspace/outputs \
    /workspace/logs \
    /workspace/checkpoints

RUN chmod +x \
    /usr/local/bin/validate-gpu.sh \
    /usr/local/bin/collect-training-diagnostics.sh

WORKDIR /workspace

CMD ["/bin/bash"]
