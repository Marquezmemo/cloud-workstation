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

`Workstation_v0.1` es una baseline minima.

Incluye:

- Dockerfile reproducible
- documentacion inicial
- estructura de carpetas para futuras iteraciones
- workflow de GitHub Actions para publicar la imagen al crear el tag `v0.1`

No incluye todavia:

- XFCE u otro entorno grafico
- Blender
- Houdini
- Parsec
- Sunshine
- audio stack
- X11 o sesion de escritorio
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

La imagen esperada para `v0.1` es:

```text
docker.io/${DOCKERHUB_USERNAME}/cloud-workstation:v0.1
```

El workflow publica la imagen solo cuando se empuja el tag Git `v0.1`.

Secretos requeridos en GitHub:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

No se publica `latest` en esta version para preservar el baseline congelado.
