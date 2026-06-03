# Workstation_v0.2-dev Error Log

Use this file as the manual integration journal for desktop bring-up.

## Rules

- Record real failures before applying fixes.
- Do not hide errors with silent configuration changes.
- Do not force X11, disable Wayland, or patch GDM until the observed failure justifies it.
- Keep each attempt reproducible: image tag, pod type, command, timestamp, logs, and result.

## Attempt Template

```text
Date:
Image:
Runpod GPU:
Pod template/settings:
Startup command:

Goal:

Observed behavior:

Relevant logs:
- /var/log/workstation/startup.log
- /var/log/workstation/supervisord.log
- /var/log/workstation/dbus.log
- /var/log/workstation/gdm.log
- /var/log/workstation/xorg.log
- /var/log/workstation/gpu.log
- /var/log/workstation/desktop-probe.log

Hypothesis:

Action taken:

Result:

Next step:
```

## Attempts

No desktop integration attempts recorded yet.
