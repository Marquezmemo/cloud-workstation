# Architecture

`cloud-workstation` esta disenado como una workstation GPU cloud-first, construida por capas y congelada por versiones.

## Arquitectura conceptual

```text
Workstation GPU cloud-first
↓
Ubuntu 22.04
↓
NVIDIA runtime
↓
Future desktop layer
↓
Future streaming layer
↓
Future DCC applications
```

## Workstation_v0.2-dev

La primera integracion desktop usa una estrategia observada:

```text
Frozen v0.1 digest
↓
Ubuntu desktop minimal
↓
supervisord
↓
dbus + GDM attempt + probes
↓
/var/log/workstation/
↓
diagnostics + error journal
```

Esta fase no fuerza X11 ni deshabilita Wayland. Primero se observa el comportamiento real del desktop en Runpod.

## Principios

- La imagen base validada es el punto de partida unico.
- Cada capa futura debe agregarse de forma incremental y documentada.
- Cada version debe poder restaurarse y compararse con versiones anteriores.
- Las decisiones tecnicas deben registrarse dentro del repositorio.
- La facilidad de debugging tiene prioridad sobre la compactacion u optimizacion temprana.

## Estado de v0.1

`v0.1` contiene solo la baseline reproducible. No modifica todavia el entorno grafico ni instala herramientas DCC.
