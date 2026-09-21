# Bonsai 2 27B — Local Optimized Runtime

Runtime local optimizado de **Bonsai 2 27B** sobre el fork PrismML de llama.cpp.

## Estado

- Modelo: `Ternary-Bonsai-2-27B-PQ2_0.gguf`
- Parámetros: `26,895,998,464`
- Quantización: `PQ2_0 — 2.13 bpw`
- Visión: `Ternary-Bonsai-2-27B-mmproj-Q8_0.gguf`
- API: `http://127.0.0.1:8080/v1`
- Alias: `bonsai2-27b`
- Contexto máximo: `262144`
- Tool calling: validado
- Reasoning: validado mediante `reasoning_content`
- Visión + tools: validado
- Contexto largo: validado
- Prompt caching: validado
- Baseline optimizado: `v1.1-optimized`

## Runtime

```text
PrismML llama.cpp: prism-b10709-9a9394a
CUDA build:        13.3
Driver NVIDIA:     616.56
CUDA UMD:          13.4
GPU:               NVIDIA GeForce RTX 5060 Ti 16 GB
CPU:               Intel Core Ultra 7 265F
RAM:               31.65 GiB
OS:                Windows 11
Power plan:        Balanced
```

## Configuración estable

```text
context                 262144
parallel slots               1
GPU layers                  99

threads                      8
threads-batch                8
priority               default

quantization              PQ2_0
KV K                      q4_0
KV V                      q4_0
KV mean-centering            on

flash attention               on
CUDA Graphs                   on

MMProj                       GPU
image-min-tokens            1024

cache RAM                  4096 MiB
context checkpoints          32
idle-slot cache              on

temperature                 1.0
top-p                       0.95
top-k                         20
min-p                        0.0

CORS                    localhost
```

## Arrancar

```powershell
cd "$HOME\AI\Bonsai-demo"
.\start-bonsai.ps1
```

## Verificar

```powershell
Invoke-RestMethod http://127.0.0.1:8080/health
```

## API OpenAI-compatible

```text
Base URL: http://127.0.0.1:8080/v1
Model:    bonsai2-27b
Endpoint: POST /v1/chat/completions
```

## Archivos locales importantes

```text
start-bonsai.ps1
templates/chat_template.jinja
MODEL-MANIFEST.md
OPTIMIZATION-RESULTS.md
kv-calibration-corpus.txt
results/bonsai2-5060ti-context-curve-10709.csv
```

## Operación del repositorio

Este repositorio usa una estructura de fork deliberada para separar el proyecto oficial de PrismML de la versión local optimizada.

```text
PrismML-Eng/Bonsai-demo
        ↑
     upstream
     fetch solamente
        │
        │
Therenovatioai/Bonsai-demo
        ↑
      origin
       │
       ├── main       → espejo limpio de PrismML
       └── optimized  → versión local optimizada
```

Reglas principales:

- `upstream` apunta al repositorio oficial `PrismML-Eng/Bonsai-demo`.
- `origin` apunta al fork `Therenovatioai/Bonsai-demo`.
- `main` se mantiene como espejo limpio de `upstream/main`.
- `optimized` contiene la configuración, documentación y optimizaciones locales.
- Los tags `v1.0-stable`, `v1.1-optimized`, etc. son snapshots históricos y no deben moverse.
- El push hacia `upstream` está deshabilitado localmente para evitar modificaciones accidentales al repositorio oficial.
- El trabajo normal debe realizarse sobre `optimized`.

La guía completa de operación, actualización, recuperación y versionado está en:

```text
REPO-OPERATIONS.md
```

## Restricciones operativas

- No ejecutar Qwen/KVMem y Bonsai simultáneamente.
- Mantener `-np 1` para preservar un único slot y ejecución secuencial.
- Mantener los `262144` tokens de contexto disponibles.
- Mantener KV Q4_0 + mean-centering.
- Mantener Flash Attention y CUDA Graphs habilitados.
- No cambiar quantización, KV o parámetros CUDA críticos sin repetir benchmarks.
- El MMProj permanece en GPU; si una carga visual excepcional produce OOM, el primer fallback es `BONSAI_MMPROJ_CPU=1`.

## Historial de baselines

```text
v1.0-stable      baseline técnico inicial
v1.1-optimized   runtime optimizado y benchmarkeado
```

