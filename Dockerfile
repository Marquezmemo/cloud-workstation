FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5

LABEL org.opencontainers.image.title="cloud-workstation"
LABEL org.opencontainers.image.version="headless-gsplat-v0.1-dev"
LABEL org.opencontainers.image.description="Headless CUDA/PyTorch base image for Gaussian Splatting training on RunPod."
LABEL org.opencontainers.image.base.name="runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5"
LABEL io.cloud-workstation.gsplat.version="1.5.3"
LABEL io.cloud-workstation.gsplat.source="PyPI wheel plus official v1.5.3 examples"
LABEL io.cloud-workstation.gsplat.examples.ref="937e29912570c372bed6747a5c9bf85fed877bae"

ARG GSPLAT_VERSION=1.5.3
ARG GSPLAT_EXAMPLES_REPO=https://github.com/nerfstudio-project/gsplat.git
ARG GSPLAT_EXAMPLES_REF=937e29912570c372bed6747a5c9bf85fed877bae

ENV TRAINING_IMAGE_VERSION=headless-gsplat-v0.1-dev
ENV GSPLAT_VERSION=${GSPLAT_VERSION}
ENV GSPLAT_EXAMPLES_REPO=${GSPLAT_EXAMPLES_REPO}
ENV GSPLAT_EXAMPLES_REF=${GSPLAT_EXAMPLES_REF}
ENV GSPLAT_OFFICIAL_DIR=/opt/gsplat
ENV GSPLAT_SIMPLE_TRAINER=/opt/gsplat/examples/simple_trainer.py
ENV TORCH_CUDA_ARCH_LIST=8.9
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

COPY requirements-gsplat-trainer.txt /tmp/requirements-gsplat-trainer.txt
COPY scripts/patch-gsplat-simple-trainer-headless.sh /tmp/patch-gsplat-simple-trainer-headless.sh

RUN git clone "${GSPLAT_EXAMPLES_REPO}" "${GSPLAT_OFFICIAL_DIR}" \
    && cd "${GSPLAT_OFFICIAL_DIR}" \
    && git checkout "${GSPLAT_EXAMPLES_REF}" \
    && rm -rf .git \
    && bash /tmp/patch-gsplat-simple-trainer-headless.sh "${GSPLAT_SIMPLE_TRAINER}" \
    && python -m pip install --no-cache-dir --upgrade-strategy only-if-needed -r /tmp/requirements-gsplat-trainer.txt \
    && rm -f /tmp/requirements-gsplat-trainer.txt /tmp/patch-gsplat-simple-trainer-headless.sh

COPY scripts/validate-gpu.sh /usr/local/bin/validate-gpu.sh
COPY scripts/collect-training-diagnostics.sh /usr/local/bin/collect-training-diagnostics.sh
COPY scripts/runpod-keepalive.sh /usr/local/bin/runpod-keepalive.sh
COPY scripts/prepare-dataset.sh /usr/local/bin/prepare-dataset.sh
COPY scripts/train-scene.sh /usr/local/bin/train-scene.sh
COPY scripts/patch-gsplat-simple-trainer-headless.sh /usr/local/bin/patch-gsplat-simple-trainer-headless.sh

RUN mkdir -p \
    /workspace/datasets \
    /workspace/scenes \
    /workspace/outputs \
    /workspace/logs \
    /workspace/checkpoints

RUN chmod +x \
    /usr/local/bin/validate-gpu.sh \
    /usr/local/bin/collect-training-diagnostics.sh \
    /usr/local/bin/runpod-keepalive.sh \
    /usr/local/bin/prepare-dataset.sh \
    /usr/local/bin/train-scene.sh \
    /usr/local/bin/patch-gsplat-simple-trainer-headless.sh

WORKDIR /workspace

CMD ["runpod-keepalive.sh"]
