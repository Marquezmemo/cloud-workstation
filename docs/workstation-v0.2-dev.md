# Workstation_v0.2-dev

`Workstation_v0.2-dev` is the first desktop integration branch.

The goal is not a perfect desktop stack. The goal is to install a real Ubuntu desktop layer, attempt startup in Runpod, and preserve enough logs to understand what fails.

## Base

This version derives from the frozen `Workstation_v0.1` digest:

```text
runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5
```

Do not move or modify:

- `v0.1`
- `workstation-v0.1`
- `cloud-workstation:v0.1`

## Added Packages

- `ubuntu-desktop-minimal`
- `mesa-utils`
- `dbus-x11`
- `xorg`
- `supervisor`
- `procps`
- `pciutils`
- `kmod`
- `x11-utils`

The Dockerfile intentionally does not run:

- `apt upgrade`
- `apt dist-upgrade`
- broad updates of existing packages

## Startup Model

The container starts with:

```text
/usr/local/bin/workstation-entrypoint.sh
```

That entrypoint prepares `/var/log/workstation/`, records environment and GPU context, then launches `supervisord`.

Supervisor attempts to run:

- `sshd`
- system `dbus-daemon`
- GDM via `start-gdm.sh`
- `desktop-probe-loop.sh`

No systemd is introduced in this version.

## Logs

Primary logs are written to:

- `/var/log/workstation/startup.log`
- `/var/log/workstation/supervisord.log`
- `/var/log/workstation/sshd.log`
- `/var/log/workstation/dbus.log`
- `/var/log/workstation/gdm.log`
- `/var/log/workstation/gdm.stdout.log`
- `/var/log/workstation/gdm.stderr.log`
- `/var/log/workstation/xorg.log`
- `/var/log/workstation/gpu.log`
- `/var/log/workstation/desktop-probe.log`

Use this inside the pod to collect diagnostics:

```bash
collect-diagnostics.sh
```

## Validation Targets

- Does the pod stay alive?
- Does SSH stay available?
- Does `nvidia-smi` work?
- Does GDM start or fail clearly?
- Does the session use Wayland, Xorg, or neither?
- Does a display socket appear?
- Does `glxinfo -B` return useful OpenGL data?

## Out of Scope

- Blender
- Houdini
- Parsec
- Sunshine
- Audio stack
- Forced X11 configuration
- Wayland disablement
- GDM overrides
