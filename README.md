# cloud-workstation

Baseline reproducible y versionada para una workstation GPU interactiva en Runpod.

## Objetivo del proyecto

Crear una base tecnica estable para una workstation cloud-first con GPU, baja latencia, escritorio remoto acelerado por GPU y soporte futuro para aplicaciones DCC como Blender y Houdini.

La version inicial `Workstation_v0.1` funciona como punto congelado de restauracion y como fuente de verdad para iteraciones posteriores.

## Filosofia de diseno

La prioridad absoluta del proyecto es:

- estabilidad
- experiencia interactiva
- reproducibilidad
- observabilidad
- facilidad de debugging

Este proyecto no busca optimizar recursos en esta etapa. No se introducen optimizaciones prematuras, orquestacion avanzada, multi-container, microservicios ni capas adicionales antes de validar cada bloque.

## Imagen base utilizada

La unica imagen base permitida para `v0.1` es:

```text
runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
```

No debe cambiarse, sustituirse ni reemplazarse por alternativas.

## Validaciones ya realizadas

La imagen base fue validada manualmente para:

- CUDA funcional
- GPU NVIDIA funcional
- NVENC funcional
- SSH funcional
- networking funcional en Runpod
- compatibilidad general con Runpod

## Estado actual del proyecto

`Workstation_v0.1` es una baseline minima congelada.

`Workstation_v0.2-dev` es la primera rama experimental de integracion desktop.

Incluye:

- Dockerfile reproducible
- documentacion inicial
- estructura de carpetas para futuras iteraciones
- workflow de GitHub Actions para publicar la imagen congelada `v0.1`
- workflow de GitHub Actions para publicar la imagen experimental `v0.2-dev`

`Workstation_v0.2-dev` agrega:

- `ubuntu-desktop-minimal`
- `mesa-utils`
- `dbus-x11`
- `xorg`
- `supervisor`
- startup observable con logs en `/var/log/workstation/`
- script de recoleccion de diagnosticos

No incluye todavia:

- Blender
- Houdini
- Parsec
- Sunshine
- audio stack
- capa de streaming

## Roadmap inicial

1. Freeze baseline
2. Add desktop layer
3. Add streaming layer
4. Add startup orchestration
5. Add observability
6. Add Blender
7. Future Houdini support

## Estructura del repositorio

```text
cloud-workstation/
├── Dockerfile
├── README.md
├── CHANGELOG.md
├── docs/
│   ├── architecture.md
│   ├── validation.md
│   └── roadmap.md
├── scripts/
├── startup/
├── healthchecks/
├── logs/
└── .gitignore
```

## Publicacion de imagen

La imagen congelada esperada para `v0.1` es:

```text
docker.io/${DOCKERHUB_USERNAME}/cloud-workstation:v0.1
```

La imagen experimental esperada para `v0.2-dev` es:

```text
docker.io/${DOCKERHUB_USERNAME}/cloud-workstation:v0.2-dev
```

El workflow de `v0.1` publica la imagen solo cuando se empuja el tag Git `v0.1`.
El workflow de `v0.2-dev` publica la imagen cuando se actualiza la rama `workstation-v0.2-dev` o se ejecuta manualmente.

Secretos requeridos en GitHub:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

No se publica `latest` en esta version para preservar el baseline congelado.
