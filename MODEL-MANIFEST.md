# Model Manifest — Bonsai 2 27B

**Estado:** Optimized Stable  
**Fecha:** 2026-09-21  
**Tag:** `v1.1-optimized`

## Modelo

| Campo | Valor |
|---|---|
| Modelo | `Ternary-Bonsai-2-27B-PQ2_0.gguf` |
| Parámetros | 26,895,998,464 |
| Formato | GGUF V3 |
| Quantización | PQ2_0 — 2.13 bpw |
| MMProj | `Ternary-Bonsai-2-27B-mmproj-Q8_0.gguf` |
| KV bias | `Ternary-Bonsai-2-27B-kv-bias.gguf` |
| Contexto entrenado | 262144 |
| Contexto operativo | 262144 |

## Runtime

```text
Prism release: prism-b10709-9a9394a
llama.cpp:      build 10709 / commit 9a9394a89
CUDA build:     13.3
```

## API

```text
Host:     127.0.0.1
Port:     8080
Base URL: http://127.0.0.1:8080/v1
Alias:    bonsai2-27b
CORS:     localhost
```

## Configuración estable

```text
context                   262144
parallel slots                  1
GPU layers                     99

threads                         8
threads-batch                   8
priority                  default

KV cache K                   q4_0
KV cache V                   q4_0
KV mean-centering                on

flash attention                  on
CUDA Graphs                      on

MMProj                          GPU
image-min-tokens               1024

cache RAM                     4096 MiB
context checkpoints             32
idle-slot cache                  on

temperature                    1.0
top-p                          0.95
top-k                            20
min-p                           0.0
```

## Hardware validado

```text
GPU:       NVIDIA GeForce RTX 5060 Ti
VRAM:      16311 MiB
CPU:       Intel Core Ultra 7 265F
RAM:       31.65 GiB
OS:        Windows 11 Home Single Language
Build:     26200
Driver:    616.56
CUDA UMD:  13.4
Power:     Balanced
```

## Validaciones funcionales

```text
API                      PASS
reasoning_content        PASS
multi-system             PASS
tool calling             PASS
visión                   PASS
visión + tool calling    PASS
KV mean-centering        PASS
prompt cache             PASS
context 262K             PASS
CUDA Graphs              PASS
```

## Long-context retrieval

```text
prompt_tokens:      238743
completion_tokens:     326
total_tokens:       239069
needles:               5/5
result:                PASS
```

## Maximum-capacity stress

```text
prompt_tokens:      238876
completion_tokens:   12288
total_tokens:       251164
finish_reason:       length
OOM:                     no
truncated:                0
```

## Prompt cache

```text
Cold:
prompt tokens       54662
prefill             ~72.1 s

Cached new turn:
tokens evaluated       21
prefill              ~0.37 s

No-cache control:
prompt tokens       54663
prefill             ~72.8 s
```

## Restricciones

- No ejecutar Qwen/KVMem simultáneamente.
- Mantener `-np 1`.
- Mantener Q4 KV para conservar el contexto de 262K.
- Mantener Flash Attention.
- Mantener CUDA Graphs habilitado.
- Mantener el KV mean-centering bias asociado a este modelo.
- No reutilizar el KV bias con otro modelo.

