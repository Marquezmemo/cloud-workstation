# Command Reference

Guia operativa de comandos disponibles para el flujo headless de Gaussian Splatting.

Esta guia documenta uso manual. No implica automatizacion de pipeline completo.

## Validar GPU Y Runtime

Comprobar GPU NVIDIA, CUDA, PyTorch, importacion de `gsplat` y operacion CUDA simple:

```bash
validate-gpu.sh
```

## Preparar Dataset

Crear el esqueleto esperado para una escena:

```bash
prepare-dataset.sh <scene>
```

La escena debe quedar bajo:

```text
/workspace/scenes/<scene>
```

El layout minimo esperado para entrenamiento es:

```text
/workspace/scenes/<scene>/
+-- images/
+-- sparse/
    +-- 0/
        +-- cameras.bin
        +-- images.bin
        +-- points3D.bin
```

Tambien pueden existir archivos COLMAP en formato `.txt`.

## Instalar Una Escena Recibida De Surveyor

Para un paquete real producido por Surveyor, mantener juntos el archivo y su checksum portable:

```text
<scene>-surveyor-scene.tar.gz
<scene>-surveyor-scene.tar.gz.sha256
```

Instalar y validar la escena:

```bash
preparar-escena <scene>-surveyor-scene.tar.gz
```

`preparar-escena`:

1. verifica que el checksum contenga exactamente el nombre portable del archivo;
2. valida el checksum antes de extraer;
3. rechaza rutas absolutas, traversal, enlaces, entradas especiales, raíces múltiples y nombres de escena inconsistentes;
4. valida `surveyor-manifest.json` y el contrato COLMAP bajo `sparse/0`;
5. instala la escena transaccionalmente bajo `/workspace/scenes/<scene>`;
6. ejecuta `train-scene.sh --check <scene>`;
7. revierte la instalación si la validación final falla.

Por defecto no reemplaza una escena existente. El reemplazo explícito usa:

```bash
OVERWRITE=true preparar-escena <scene>-surveyor-scene.tar.gz
```

El comando y su rollback están cubiertos por la suite de regresión. La validación final v0.1 confirmó su uso con una escena Surveyor real en el runtime `221c4ef`; esa ejecución es `operator-confirmed` y sus registros primarios no fueron preservados.

## Validar Escena

Validar una escena sin iniciar entrenamiento:

```bash
train-scene.sh --check <scene>
```

Ejemplo:

```bash
train-scene.sh --check room
```

Este comando comprueba directorio de escena, `images/`, `sparse/` y archivos COLMAP.

## Entrenar

Smoke test de 100 pasos:

```bash
MAX_STEPS=100 train-scene.sh <scene>
```

Ejemplo:

```bash
MAX_STEPS=100 train-scene.sh room
```

Pasar argumentos adicionales al trainer oficial despues de `--`:

```bash
MAX_STEPS=100 train-scene.sh <scene> -- --data_factor 2 --test_every 12
```

Ejemplo:

```bash
MAX_STEPS=100 train-scene.sh room -- --data_factor 2 --test_every 12
```

Las escenas se entrenan individualmente. El script no entrena todas las escenas automaticamente.

## Generar PLY

Cuando existe una sola opcion clara de checkpoint:

```bash
generar
```

Seleccionar una escena explicitamente:

```bash
generar --scene room
```

Seleccionar un checkpoint explicitamente:

```bash
generar --checkpoint /workspace/outputs/room/ckpts/ckpt_100.pt
```

Seleccionar un directorio de checkpoints:

```bash
generar --ckpt-dir /workspace/outputs/room/ckpts
```

Elegir formato de exportacion:

```bash
generar --scene room --format both
generar --scene room --format ply
generar --scene room --format ply_compressed
```

Elegir dispositivo de exportacion con fallback:

```bash
generar --scene room --device cuda --fallback-cpu
```

No usar:

```bash
generar --room
generar /room
generar --/workspace/checkpoints/room
```

La sintaxis oficial actual es `generar --scene <scene>`. La forma `generar <scene>` queda registrada solo como posible mejora futura.

## Empaquetar

Empaquetar exports PLY de una escena:

```bash
empaquetar room
```

Alias:

```bash
comprimir room
```

Resultado esperado:

```text
/workspace/outputs/room/exports/room-ply-exports.tar.gz
/workspace/outputs/room/exports/room-ply-exports.tar.gz.sha256
```

Empaquetar logs existentes de entrenamiento, exportacion y telemetria opcional:

```bash
empaquetar-logs room
```

Resultado esperado:

```text
/workspace/outputs/room/exports/room-training-logs.tar.gz
/workspace/outputs/room/exports/room-training-logs.tar.gz.sha256
```

`empaquetar-logs` no genera telemetria. Solamente incluye archivos compatibles que ya existan bajo `/workspace/logs/room`.

## Verificar Checksum En El Pod

Entrar al directorio de exports:

```bash
cd /workspace/outputs/room/exports
```

Calcular checksum:

```bash
sha256sum room-ply-exports.tar.gz
```

Comparar con el archivo generado:

```bash
cat room-ply-exports.tar.gz.sha256
```

El checksum producido por `empaquetar` contiene actualmente la ruta absoluta del pod. Puede validarse directamente mientras esa ruta exista:

```bash
sha256sum -c room-ply-exports.tar.gz.sha256
```

Despues de transferir a la Mac, calcular el SHA-256 del archivo recibido y comparar manualmente el valor. El checksum generado por `empaquetar-logs` si usa un nombre relativo portable.

## Transferir Con runpodctl

Enviar el paquete desde el pod:

```bash
runpodctl send /workspace/outputs/room/exports/room-ply-exports.tar.gz
```

El comando imprime un codigo de transferencia. En la maquina receptora:

```bash
runpodctl receive <transfer-code>
```

Si tambien se transfiere el checksum:

```bash
runpodctl send /workspace/outputs/room/exports/room-ply-exports.tar.gz.sha256
runpodctl receive <transfer-code>
```

La instalacion y el uso real de `runpodctl` quedaron validados con evidencia en la ejecución original de `Prueba02`. La validación final v0.1 también pasó las transferencias por declaración del operador, sin registros primarios preservados. Cada prueba futura debe seguir registrando comandos, tamaños, hashes antes y despues, duracion y resultado. Los codigos efimeros de transferencia no se guardan en Git.

El orden validado es generar primero y empaquetar después. `empaquetar` no prepara ni extrae escenas y falla correctamente si los exports todavía no existen:

```bash
generar --scene Prueba02
empaquetar Prueba02
```

## Flujo Completo De Una Escena

```bash
preparar-escena /ruta/room-surveyor-scene.tar.gz
train-scene.sh --check room
MAX_STEPS=100 train-scene.sh room
generar --scene room
empaquetar room
cd /workspace/outputs/room/exports
sha256sum room-ply-exports.tar.gz
cat room-ply-exports.tar.gz.sha256
runpodctl send /workspace/outputs/room/exports/room-ply-exports.tar.gz
```

En la Mac:

```bash
runpodctl receive <transfer-code>
```

## Flujo Con Varias Escenas

Entrenar individualmente:

```bash
MAX_STEPS=100 train-scene.sh bonsai
MAX_STEPS=100 train-scene.sh room
```

Generar individualmente:

```bash
generar --scene bonsai
generar --scene room
```

Empaquetar individualmente:

```bash
empaquetar bonsai
empaquetar room
```

Descargar cada paquete con `runpodctl`.
