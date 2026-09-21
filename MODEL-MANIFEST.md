# Model Manifest — Bonsai 2 27B

**Estado:** Stable  
**Fecha de validación:** 2026-09-20  
**Tag:** `v1.0-stable`

## Modelo

| Campo | Valor |
|---|---|
| Modelo | `Ternary-Bonsai-2-27B-PQ2_0.gguf` |
| Parámetros | 26,895,998,464 |
| Formato | GGUF |
| Quantización | PQ2_0 — 2.13 bpw |
| Tamaño reportado | 7,195,047,936 bytes |
| MMProj | `Ternary-Bonsai-2-27B-mmproj-Q8_0.gguf` |

## API

```text
Host:     127.0.0.1
Port:     8080
Base URL: http://127.0.0.1:8080/v1
Alias:    bonsai2-27b
```

## Configuración estable

```text
context               262144
parallel slots              1
GPU layers                 99
KV cache                 q4_0
flash attention             on
MMProj                     CPU
image-min-tokens          1024
```

Chat template:

```text
templates/chat_template.jinja
```

## Hardware validado

```text
GPU:       NVIDIA GeForce RTX 5060 Ti
VRAM:      16311 MiB
OS:        Windows
Driver:    616.56
CUDA UMD:  13.4
```

## Validaciones funcionales

```text
API básica              PASS
reasoning_content       PASS
multi-system            PASS
tool calling            PASS
visión                   PASS
visión + tool calling    PASS
```

## Long context

### Retrieval

```text
prompt_tokens:      238743
completion_tokens:     326
total_tokens:       239069
cache:                   0
needles:               5/5
result:                PASS
```

Rendimiento:

```text
prompt throughput:      433.38 tok/s
generation throughput:   13.06 tok/s
wall time:               576.05 s
```

### Stress test

```text
prompt_tokens:      238876
completion_tokens:   12288
total_tokens:       251164
cache:                   0
finish_reason:       length
OOM:                     no
truncated:                0
```

Rendimiento:

```text
prompt throughput:      433.39 tok/s
generation throughput:   12.88 tok/s
total time:             1504.90 s
```

En el stress test con `ignore_eos=true`, los 12288 tokens de salida se consumieron en `reasoning_content`; la recuperación 5/5 se validó por separado en la prueba de 238743 tokens.

## Restricciones operativas

- No ejecutar Qwen/KVMem simultáneamente.
- Mantener `-np 1` con esta configuración.
- No cambiar contexto, KV, template o parámetros críticos sin repetir benchmarks.
