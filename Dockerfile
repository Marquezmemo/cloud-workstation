FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:892a770019c7dc6f4078893924429020fbe30e241c1522d7982894f417c93ffe

LABEL org.opencontainers.image.title="cloud-workstation"
LABEL org.opencontainers.image.version="v0.2-dev"
LABEL org.opencontainers.image.description="Experimental desktop integration layer for a Runpod GPU interactive workstation."
LABEL org.opencontainers.image.base.name="runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:892a770019c7dc6f4078893924429020fbe30e241c1522d7982894f417c93ffe"

ENV DEBIAN_FRONTEND=noninteractive
ENV WORKSTATION_VERSION=Workstation_v0.2-dev
ENV WORKSTATION_LOG_DIR=/var/log/workstation

RUN apt-get update \
    && apt-get install -y --no-upgrade \
        ubuntu-desktop-minimal \
        mesa-utils \
        dbus-x11 \
        xorg \
        supervisor \
        procps \
        pciutils \
        kmod \
        x11-utils \
    && rm -rf /var/lib/apt/lists/*

COPY startup/workstation-entrypoint.sh /usr/local/bin/workstation-entrypoint.sh
COPY startup/start-gdm.sh /usr/local/bin/start-gdm.sh
COPY startup/desktop-probe-loop.sh /usr/local/bin/desktop-probe-loop.sh
COPY startup/supervisord.conf /etc/supervisor/conf.d/workstation.conf
COPY scripts/collect-diagnostics.sh /usr/local/bin/collect-diagnostics.sh
COPY healthchecks/desktop-probe.sh /usr/local/bin/desktop-probe.sh

RUN chmod +x \
        /usr/local/bin/workstation-entrypoint.sh \
        /usr/local/bin/start-gdm.sh \
        /usr/local/bin/desktop-probe-loop.sh \
        /usr/local/bin/collect-diagnostics.sh \
        /usr/local/bin/desktop-probe.sh \
    && mkdir -p /var/log/workstation /var/run/sshd /run/dbus

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s CMD /usr/local/bin/desktop-probe.sh || exit 1

CMD ["/usr/local/bin/workstation-entrypoint.sh"]
