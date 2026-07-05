# The Trainer v0.2 Handoff

## 1. Propósito del documento

Este documento entrega al agente de The Trainer v0.2 el contexto funcional, documental y probatorio heredado de v0.1. Su objetivo es permitir que una misión nueva empiece desde la baseline correcta sin confundir la ejecución histórica de Prueba02 con el runtime final.

Convenciones usadas aquí:

- **Hecho verificado:** deriva de una referencia Git o de un archivo versionado citado.
- **Evidencia histórica preservada:** deriva del registro de Prueba02 y sus evidencias versionadas.
- **Atestación del operador:** declaración del propietario/operador sin registros primarios preservados.
- **Deuda, experimento o propuesta:** trabajo registrado, todavía no implementado ni validado.

Este handoff no autoriza desarrollo funcional, ejecución GPU, cambio de dependencias ni publicación Docker.

## 2. Identidades heredadas

| Identidad | Valor | Base |
| --- | --- | --- |
| v0.1 documentation head | `123652ea97f549e1d06d3993f55c2bcab252f840` | Referencia Git congelada `headless-gsplat-v0.1-dev` |
| v0.1 final runtime | `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3` | Commit que incorpora `preparar-escena`; el commit siguiente sólo actualiza documentación |
| v0.1 final Docker digest | `sha256:726ac98c9678431fc34fbcc1de0bf07b71adbff215d672f04740a95999a6bf98` | Atestación final en `docs/validation-runs/2026-07-04-trainer-v0.1-final-operator-attestation.md` |
| historical Prueba02 runtime | `90196251d59907754cc19caf76b59a737752893b` | Identidad histórica heredada para gobierno; no aparece en el registro original de Prueba02 |
| historical Prueba02 digest | `sha256:535822530f4b23fca3eee3970b147e3e979162a32c2e9de9f76a829836b63a89` | Identidad histórica heredada para gobierno; no aparece en el registro original de Prueba02 |
| v0.2 starting branch | `headless-gsplat-v0.2-dev` | Creada desde el documentation head de v0.1 |

El primer commit propio de v0.2 incorpora únicamente `AGENTS.md` y este handoff. No modifica `Dockerfile`, workflows, requirements, scripts, patches, tests ni runtime. Por tanto, los archivos funcionales de inicio de v0.2 permanecen idénticos al runtime `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3`.

La diferencia entre `221c4ef...` y `123652e...` está limitada a `README.md`, `CHANGELOG.md` y documentación de validación/operación. Verificar esta afirmación con `git diff --name-status 221c4ef... 123652e...` antes de usarla en un release.

## 3. Dos niveles de validación

### Prueba02 original

El registro `docs/validation-runs/2026-06-29-prueba02-trainer-e2e.md` conserva una ejecución anterior con evidencia primaria:

- runtime anterior al final v0.1;
- extracción manual del archivo Surveyor;
- checksum recibido y verificado;
- entrenamiento de `300` pasos;
- checkpoint `ckpt_299_rank0.pt`;
- PLY estándar y comprimido;
- empaquetado y transferencia real;
- inspección independiente del PLY estándar;
- carga en SuperSplat v2.27.4.

Las métricas, tamaños, conteos y hashes de ese documento pertenecen exclusivamente a esa ejecución. El conteo de Gaussianas no cambió, por lo que Prueba02 no demostró densificación. La carga en el visor demostró compatibilidad, no calidad profesional o comercial.

### Baseline final v0.1

El registro `docs/validation-runs/2026-07-04-trainer-v0.1-final-operator-attestation.md` cubre el runtime final:

```text
validation_status: passed
validation_authority: repository-owner-operator
evidence_level: operator-confirmed
primary_execution_records: not-preserved
```

La atestación confirma para el runtime `221c4ef...`:

- `preparar-escena` automático;
- instalación transaccional;
- `train-scene.sh --check`;
- entrenamiento CUDA;
- checkpoint y PLY generados;
- empaquetado y transferencias;
- carga en visor.

No se preservaron fecha exacta de ejecución, logs, transcript, checkpoint ni artefactos primarios. No se deben heredar métricas de Prueba02, certificar densificación ni afirmar calidad profesional/comercial. Esta atestación no es evidencia primaria preservada.

## 4. Arquitectura real del Trainer

### Imagen y runtime

`Dockerfile` fija la imagen base:

```text
runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5
```

El nombre de la base declara Python 3.11, PyTorch 2.4.0 y CUDA 12.4.1. No sustituir esa identidad por versiones observadas en otras ejecuciones. `TORCH_CUDA_ARCH_LIST=8.9` se fija en `Dockerfile`.

La imagen instala:

- `gsplat==1.5.3` desde `requirements-gsplat.txt`;
- los ejemplos oficiales desde `https://github.com/nerfstudio-project/gsplat.git` en el commit `937e29912570c372bed6747a5c9bf85fed877bae`;
- el trainer en `/opt/gsplat/examples/simple_trainer.py`;
- dependencias directas fijadas en `requirements-gsplat-trainer.txt`;
- `runpodctl v2.5.0`, cuyo binario Linux amd64 se verifica durante build con SHA-256 `f484ce7d790ddc6b4a63363f3c975c70fa87bf3be1bcbad019812f6e3f4ba54e`.

COLMAP no se instala en Trainer. `pycolmap` se usa para consumir una escena ya preparada. Surveyor es responsable de reconstrucción y selección sparse.

### Trainer oficial y patch headless

`scripts/patch-gsplat-simple-trainer-headless.sh` reemplaza tres importaciones superiores relacionadas con viewer por stubs locales y verifica que esas importaciones no permanezcan. No cambia el algoritmo de entrenamiento, parser de cámaras, checkpoints ni exportación.

`scripts/train-scene.sh` fuerza `--disable_viewer` y rechaza `DISABLE_VIEWER=false`. Ejecuta el trainer oficial con rutas explícitas para escena y resultados.

### Flujo funcional

```text
Surveyor archive + portable checksum
-> preparar-escena
-> /workspace/scenes/<scene>
-> train-scene.sh --check
-> train-scene.sh
-> /workspace/outputs/<scene>/ckpts
-> generar
-> standard/compressed PLY
-> empaquetar
-> runpodctl transfer
```

La preparación, entrenamiento, exportación, empaquetado y transferencia son pasos separados. No existe un orquestador fire-and-forget.

## 5. Contrato de entrada

Trainer recibe dos archivos adyacentes:

```text
<scene>-surveyor-scene.tar.gz
<scene>-surveyor-scene.tar.gz.sha256
```

`scripts/preparar-escena-trainer.sh`, instalado como `preparar-escena`, valida:

1. que ambos archivos existan, sean no vacíos y no sean symlinks;
2. que el nombre del archivo termine en `-surveyor-scene.tar.gz`;
3. que la escena cumpla `[A-Za-z0-9][A-Za-z0-9._-]*`;
4. que el checksum tenga exactamente un registro `sha256sum` y mencione sólo el basename exacto del archivo;
5. que el digest sea correcto antes de extraer;
6. que el TAR no contenga rutas absolutas, separadores no POSIX, `.`/`..`, duplicados, links ni entradas especiales;
7. que exista una única raíz explícita y que coincida con el nombre de escena del archivo;
8. que existan `images/`, `sparse/0/cameras.bin`, `images.bin`, `points3D.bin` y `surveyor-manifest.json`;
9. que los tres binarios COLMAP sean no vacíos;
10. que el manifest sea un objeto JSON y que `scene` coincida;
11. cuando existan, que `trainer_ready_sparse_path`, `registered_images` y `database_images` cumplan las restricciones implementadas;
12. que el resultado pase el `train-scene.sh --check` productivo.

El importador no demuestra que las imágenes sean buenas, que los binarios COLMAP sean semánticamente correctos, que la selección sparse sea óptima ni que el entrenamiento converja. Es una puerta estructural, de integridad y de instalación.

Por defecto una escena existente no se reemplaza. `OVERWRITE=true` activa reemplazo explícito con backup y rollback. El staging ocurre bajo `/workspace/temp`; un fallo durante la validación final intenta restaurar el destino anterior.

## 6. Contrato instalado

Una importación Surveyor aceptada queda así:

```text
/workspace/scenes/<scene>/
├── images/
├── sparse/
│   └── 0/
│       ├── cameras.bin
│       ├── images.bin
│       └── points3D.bin
└── surveyor-manifest.json
```

`preparar-escena` exige específicamente `sparse/0` y archivos `.bin`. El validador más general `train-scene.sh --check` acepta `sparse/0` o `sparse` y, para cada tabla COLMAP, `.bin` o `.txt`. No confundir la flexibilidad del check con el contrato más estricto del paquete Surveyor.

El check escribe:

```text
/workspace/logs/<scene>/run.env
/workspace/logs/<scene>/run.summary
```

y crea el enlace de checkpoints descrito en la siguiente sección. No inicia entrenamiento.

## 7. Contrato de salida

| Salida | Ruta real | Notas |
| --- | --- | --- |
| Variables de ejecución | `/workspace/logs/<scene>/run.env` | Rutas, configuración, commit de ejemplos y timestamp |
| Resumen de ejecución | `/workspace/logs/<scene>/run.summary` | Estado del check o estado/comando/resultado del entrenamiento |
| Log de entrenamiento | `/workspace/logs/<scene>/train.log` | Salida combinada del trainer |
| Cola de error | `/workspace/logs/<scene>/error.tail` | Sólo se escribe si falla el entrenamiento |
| Resultados del trainer | `/workspace/outputs/<scene>/` | `result_dir` del ejemplo oficial; su contenido adicional es responsabilidad del backend |
| Checkpoints reales | `/workspace/outputs/<scene>/ckpts/ckpt_*.pt` | Generados por el trainer oficial |
| Vista persistente de checkpoints | `/workspace/checkpoints/<scene>` | Symlink a `/workspace/outputs/<scene>/ckpts` |
| Log de exportación | `/workspace/logs/<scene>/generate-ply.log` | Checkpoint, shapes, formatos, archivos y validación |
| PLY estándar | `/workspace/outputs/<scene>/exports/<scene>.ply` | Exportado con `gsplat.export_splats` |
| PLY comprimido | `/workspace/outputs/<scene>/exports/<scene>.compressed.ply` | Puede filtrar splats de opacidad muy baja |
| Paquete PLY | `/workspace/outputs/<scene>/exports/<scene>-ply-exports.tar.gz` | Incluye los `.ply` existentes de la escena |
| Checksum PLY | `<scene>-ply-exports.tar.gz.sha256` en el mismo directorio | Actualmente contiene la ruta absoluta del pod |
| Paquete de logs | `/workspace/outputs/<scene>/exports/<scene>-training-logs.tar.gz` | Logs elegibles y manifest, sin datasets/checkpoints/PLY |
| Checksum de logs | `<scene>-training-logs.tar.gz.sha256` en el mismo directorio | Portable; contiene sólo el nombre del archivo |
| Diagnóstico global | `/workspace/logs/diagnostics/training-diagnostics-<UTC>.tar.gz` | Puede contener ambiente y datos sensibles; revisar antes de compartir |

`generar` valida que el PLY estándar declare el mismo número de vértices que splats de entrada. Para PLY comprimido sólo rechaza un conteo mayor al original. Estas puertas son estructurales, no métricas de calidad.

`empaquetar-logs` rehúsa sobrescribir, comprueba patrones comunes de secretos, excluye diagnósticos globales no ligados a la escena, verifica TAR y checksum y no genera telemetría GPU. Sólo incluye telemetría scene-scoped si ya existe con uno de los nombres admitidos por el script.

## 8. Comandos públicos

| Comando | Sintaxis implementada | Responsabilidad |
| --- | --- | --- |
| Validar GPU | `validate-gpu.sh` | `nvidia-smi`, imports, CUDA disponible y operación CUDA simple |
| Diagnóstico global | `collect-training-diagnostics.sh` | Snapshot de runtime/workspace/logs bajo `/workspace/logs/diagnostics` |
| Esqueleto manual | `prepare-dataset.sh <scene>` | Crea layout base; no ejecuta COLMAP |
| Importar Surveyor | `preparar-escena <scene>-surveyor-scene.tar.gz` | Verifica, instala transaccionalmente y ejecuta el check |
| Reemplazo explícito | `OVERWRITE=true preparar-escena <archive>` | Reemplazo con backup/rollback |
| Validar escena | `train-scene.sh --check <scene>` | Check estructural sin entrenamiento |
| Entrenar | `MAX_STEPS=<steps> train-scene.sh <scene>` | Ejecuta trainer oficial headless |
| Passthrough del trainer | `train-scene.sh <scene> -- <args>` | Añade argumentos al trainer oficial |
| Exportación inferida | `generar` | Sólo cuando existe una selección no ambigua |
| Exportación por escena | `generar --scene <scene>` | Selecciona el checkpoint más reciente de la escena |
| Exportación explícita | `generar --checkpoint <path>` | Usa un checkpoint específico |
| Directorio de checkpoints | `generar --ckpt-dir <path>` | Busca `ckpt_*.pt` en ese directorio |
| Formato | `generar --scene <scene> --format both|ply|ply_compressed` | Controla formatos nativos |
| Dispositivo | `generar --scene <scene> --device cpu|cuda [--fallback-cpu]` | CPU es el default |
| Empaquetar PLY | `empaquetar <scene>` | TAR y checksum; no transfiere |
| Alias de empaquetado | `comprimir <scene>` | Ejecuta `empaquetar` |
| Empaquetar evidencia | `empaquetar-logs <scene>` | Paquete portable de logs existentes |
| Enviar | `runpodctl send <path>` | Produce un código efímero de transferencia |
| Recibir | `runpodctl receive <transfer-code>` | Recibe el archivo en el otro extremo |

`Generar` también existe como alias instalado, pero la documentación operativa usa `generar`. No están implementados `generar <scene>` ni `generar --list`.

## 9. Archivos importantes

| Ruta | Responsabilidad | Cuándo modificarla | Pruebas relacionadas | Riesgo |
| --- | --- | --- | --- | --- |
| `Dockerfile` | Imagen base, labels, dependencias, comandos y layout | Sólo con misión de runtime y autorización de build/publicación | Regresiones de workflow y build autorizado | Muy alto: cambia digest/runtime |
| `requirements-gsplat.txt` | Runtime `gsplat` directo | Sólo con justificación de compatibilidad | Import local cuando sea posible; GPU/build autorizado para cierre | Alto |
| `requirements-gsplat-trainer.txt` | Dependencias del ejemplo oficial | Sólo con análisis de import/API y autorización | Build/import; pruebas específicas de la función afectada | Alto; transitivas no totalmente congeladas |
| `scripts/preparar-escena-trainer.sh` | Contrato Surveyor e instalación transaccional | Cambios explícitos al importador/contrato | `bash -n` y `tests/test-preparar-escena-trainer.sh` | Alto: integridad y overwrite |
| `scripts/train-scene.sh` | Check, metadata y ejecución headless | Cambios explícitos de entrenamiento | `bash -n`; suite del importador cubre `--check`; GPU para entrenamiento real | Alto |
| `scripts/generate-ply.py` | Descubrimiento de checkpoint y exportación nativa | Cambios explícitos de exportación | No hay suite dedicada; diseñar fixture y smoke proporcional | Alto: formato/compatibilidad |
| `scripts/Generar` | Wrapper de `generate-ply.py` | Sólo si cambia entrypoint | Sintaxis y smoke del generador | Medio |
| `scripts/empaquetar` / `scripts/comprimir` | Paquete de PLY y checksum | Cambios explícitos de packaging | No hay suite dedicada versionada | Medio; checksum no portable |
| `scripts/empaquetar-logs` | Paquete scene-scoped de evidencia | Cambios explícitos de evidencia/seguridad | No hay suite dedicada versionada | Alto: secretos y cadena de custodia |
| `scripts/patch-gsplat-simple-trainer-headless.sh` | Elimina imports de viewer al construir | Sólo con cambio compatible del trainer fijado | `bash -n`, build autorizado, help/import del trainer | Muy alto: build puede romper |
| `scripts/validate-gpu.sh` | Smoke CUDA/gsplat | Cambios de diagnóstico GPU | Requiere GPU para validación real | Medio |
| `scripts/collect-training-diagnostics.sh` | Evidencia global de runtime | Cambios de diagnóstico/privacidad | Smoke local; revisión de contenido antes de compartir | Alto: captura `env` |
| `tests/test-preparar-escena-trainer.sh` | 15 casos de importación, contrato, overwrite y rollback | Junto con cambios al importador | Ejecutar el propio script | Bajo para runtime; alto si reduce cobertura |
| `.github/workflows/publish-headless-gsplat-dev.yml` | Regresión, build y publicación de la rama v0.1 | Sólo con misión administrativa/de release | Revisión de trigger y ejecución autorizada | Muy alto: publicación externa |
| `docs/command-reference.md` | Sintaxis canónica de operador | Con cada cambio público de comandos | `git diff --check` y contraste con scripts | Medio |
| `docs/training-workflow.md` / `docs/ply-export.md` | Arquitectura y exportación operativa | Con cambios de comportamiento | Revisión cruzada con scripts | Medio |
| `docs/validation.md` y `docs/validation-runs/` | Clasificación y evidencia | Sólo con hechos y autoridad identificables | Revisión de fuentes, hashes y alcance | Alto: sobreafirmación |

Pruebas actualmente registradas por el workflow para el importador/wrapper:

```bash
bash -n scripts/preparar-escena-trainer.sh
bash -n scripts/train-scene.sh
bash tests/test-preparar-escena-trainer.sh
```

No presentar esa suite como cobertura de exportación, empaquetado, transferencia o entrenamiento CUDA.

## 10. Decisiones congeladas de v0.1

- Surveyor y Trainer son imágenes y responsabilidades separadas.
- El runtime final heredado es `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3`.
- `preparar-escena` forma parte de ese runtime.
- El entrenamiento es headless y el viewer permanece deshabilitado.
- `gsplat==1.5.3` y los ejemplos oficiales en `937e29912570c372bed6747a5c9bf85fed877bae` están fijados.
- `/workspace` aloja escenas, outputs, logs, checkpoints y temp; su persistencia depende del volumen/almacenamiento de RunPod.
- Generación PLY y empaquetado son pasos separados.
- `empaquetar` no transfiere; `runpodctl` es una herramienta separada.
- Las métricas de Prueba02 no se transfieren a la validación final ni a v0.2.
- Calidad profesional/comercial y criterios de captura quedan fuera del baseline técnico.

Modificar cualquiera de estas decisiones requiere misión explícita y autorización del propietario.

## 11. Limitaciones actuales

- La validación final v0.1 carece de logs, transcript, checkpoint y artefactos primarios preservados.
- Densificación y crecimiento de Gaussianas no están certificados.
- No hay benchmark de calidad; PSNR, SSIM, LPIPS y renders comparables siguen pendientes.
- Calidad profesional, captura y utilidad comercial no fueron evaluadas.
- Las dependencias directas están fijadas, pero no existe lock completo con hashes para todas las transitivas.
- El checksum de `empaquetar` contiene una ruta absoluta; el de `empaquetar-logs` sí es portable.
- Transferencias mayores a 1 GB, interrupción, resume y throughput medido no están validados.
- Los costos observados de compilación CUDA inicial y descarga de AlexNet pertenecen a Prueba02; no son garantías del runtime final.
- El warning futuro de `torch.load` continúa registrado como deuda; no asumir que está resuelto en todos los caminos.
- No hay regresiones dedicadas versionadas para exportación PLY, packaging PLY, packaging de logs o transferencia.
- `collect-training-diagnostics.sh` captura el ambiente completo; puede incluir secretos y requiere saneamiento antes de compartir.
- Trainer no incluye COLMAP, viewer, desktop, Nerfstudio ni un pipeline automático completo.

## 12. Deuda y posibles áreas v0.2

Estas áreas provienen de `docs/roadmap.md`, `docs/validation.md` y el registro original de Prueba02. No se inicia ninguna mediante este handoff.

| Área | Clasificación | GPU | Condición |
| --- | --- | --- | --- |
| Mensaje correctivo exportar antes de empaquetar | Deuda confirmada | No | Mantener comportamiento o proponer UX sin tocar contrato |
| Preservar registros primarios en futuras validaciones | Deuda confirmada | No | Definir captura antes de ejecutar |
| Proceso reproducible de release Trainer | Propuesta | No | Requiere autorización de release |
| Compilación CUDA inicial y descarga de AlexNet | Experimento | Sí / red | Medir sin heredar cifras históricas |
| Warning futuro de `torch.load` | Deuda confirmada | No inicialmente | Inspeccionar rutas; validar runtime proporcionalmente |
| OPENCV frente a PINHOLE/undistortion | Experimento y contrato compartido | Sí para cierre real | Coordinar con Surveyor; evitar doble undistortion |
| Densificación y crecimiento de Gaussianas | Experimento | Sí | Definir criterios antes de entrenar |
| PSNR, SSIM, LPIPS y renders comparables | Propuesta de validación | Sí | Definir dataset y umbrales |
| Archivo mayor a 1 GB, interrupción y resume | Experimento de transferencia | No GPU; sí infraestructura | Registrar hashes, tiempos y reintentos |
| Calidad profesional/comercial | Fuera de alcance técnico actual | Depende | Requiere criterios del propietario |

## 13. Límites frente a Surveyor

Trainer consume el archivo, checksum, layout COLMAP y manifest entregados por Surveyor. Trainer puede rechazar un paquete que no cumpla su contrato, pero no debe corregir unilateralmente:

- imágenes de captura;
- parámetros o ejecución COLMAP;
- selección del modelo sparse;
- nombres o semántica del manifest compartido;
- geometría o cámara producida por Surveyor;
- runtime, Dockerfile o dependencias de Surveyor.

Si un cambio de Trainer necesita datos nuevos, distinta estructura, imágenes undistorted o nueva semántica de manifest, primero debe existir una propuesta de contrato, evaluación de compatibilidad y autorización. Cambiar sólo una mitad del tratamiento de cámara puede producir doble undistortion o intrínsecos inconsistentes.

## 14. Flujo recomendado para el nuevo agente

1. Confirmar rama, HEAD, estado y remote.
2. Leer `AGENTS.md`.
3. Leer este handoff.
4. Identificar el alcance exacto y la autoridad de la misión.
5. Inspeccionar los archivos afectados y sus pruebas reales.
6. Ejecutar regresiones sin GPU cuando sea posible.
7. Declarar si el cierre requiere GPU, red, build o publicación.
8. Mostrar diff, pruebas y limitaciones antes del commit.
9. No reconstruir ni publicar imágenes sin autorización expresa.
10. Conservar evidencia primaria de toda validación nueva y clasificarla correctamente.

Puerta mínima:

```bash
git branch --show-current
git rev-parse HEAD
git status --short
git remote -v
```

Detenerse si la rama no es `headless-gsplat-v0.2-dev` o si aparecen cambios ajenos/no identificados.

## 15. Estado inicial de v0.2

`headless-gsplat-v0.2-dev` fue creada desde `123652ea97f549e1d06d3993f55c2bcab252f840`. Su primer commit propio añade únicamente gobierno para agentes y este handoff.

Estado funcional inicial esperado:

```text
runtime inherited: 221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3
functional changes from v0.1: zero
Docker image rebuilt or published: no
v0.1 references modified: no
```

El `Dockerfile` aún contiene labels y `TRAINING_IMAGE_VERSION` de v0.1. Eso es parte del runtime heredado y no se cambia durante esta misión documental. Cualquier identidad de imagen v0.2 debe abordarse en una misión funcional/release separada.

## 16. Hechos no verificables desde Git

Declaración informada por el propietario:

> Los workflows de publicación v0.1 se encuentran desactivados en la interfaz de GitHub Actions.

El YAML `.github/workflows/publish-headless-gsplat-dev.yml` permanece versionado, conserva trigger para `headless-gsplat-v0.1-dev` y contiene un job de build/push. El estado `disabled` de la interfaz no se deduce del árbol Git y no debe presentarse como modificación del YAML.

No existe en el árbol heredado un workflow de publicación específico para `headless-gsplat-v0.2-dev`. Esto no autoriza crear uno.

## 17. Preguntas que el nuevo agente no debe resolver por su cuenta

Requieren decisión y autorización del propietario:

- cambiar el backend de entrenamiento;
- actualizar `gsplat` o el commit de ejemplos oficiales;
- cambiar Python, PyTorch, CUDA, imagen base o dependencias;
- cambiar el contrato Surveyor, manifest, cámaras o tratamiento de distorsión;
- cambiar formato, layout o compatibilidad de checkpoints;
- cambiar el exportador o formatos PLY;
- reconstruir, etiquetar o publicar Docker;
- ejecutar entrenamiento o experimentos con costo GPU;
- definir umbrales de calidad o criterios comerciales;
- incorporar orquestación, nuevas etapas o responsabilidades de Surveyor/Full;
- modificar ramas congeladas o archivos del freeze v0.1.

## Notas de incertidumbre

- Los SHAs/digests históricos de Prueba02 exigidos por este handoff no están impresos en `docs/validation-runs/2026-06-29-prueba02-trainer-e2e.md`; se conservan como identidad heredada suministrada por el propietario, separada de los hechos rederivables desde ese archivo.
- La atestación final registra el digest final y los resultados funcionales, pero no preserva los registros primarios de ejecución.
- La desactivación de workflows v0.1 es una condición informada por el propietario y no verificable mediante el contenido Git.
- Ninguna prioridad de v0.2 listada arriba constituye autorización para implementarla.
