FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

LABEL org.opencontainers.image.title="cloud-workstation"
LABEL org.opencontainers.image.version="v0.1"
LABEL org.opencontainers.image.description="Frozen baseline for a Runpod GPU interactive workstation."
LABEL org.opencontainers.image.base.name="runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04"
