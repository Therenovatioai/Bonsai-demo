# Bonsai 2 27B — Optimization Results

Hardware: NVIDIA RTX 5060 Ti 16 GB  
Runtime: PrismML llama.cpp build 10709  
Model: Bonsai 2 27B PQ2_0  
Fecha de cierre de optimización: 2026-09-21

## Build

```text
10683 -> 10709
```

Sin regresión material de rendimiento.

## KV cache

```text
FP16 KV
pp512  974.38 tok/s
tg128   47.63 tok/s

Q4 KV
pp512  961.34 tok/s
tg128   46.97 tok/s
```

Decisión: mantener Q4_0 por ahorro de memoria y soporte de contexto completo de 262K.

Mean-centering bias: habilitado y validado.

## Batch / ubatch

Configuración final:

```text
batch  = 2048
ubatch = 512
```

## CUDA Graphs

```text
Graphs ON
pp4096 953.15
tg512   47.14

Graphs OFF
pp4096 958.85
tg512   36.16
```

Decisión: CUDA Graphs ON.

## Blackwell / CUDA

```text
CUDA ARCHS incluye 1200/1210
USE_GRAPHS = 1
BLACKWELL_NATIVE_FP4 = 1
65/65 layers offloaded to CUDA
Flash Attention enabled
VMM enabled
```

No se consideró necesaria una compilación custom específica para sm_120.

## CPU / scheduler

`llama-bench`:

| Threads | pp4096 | tg512 |
|---:|---:|---:|
| 8 | 952.55 | 47.18 |
| 12 | 954.80 | 47.19 |
| 16 | 946.01 | 46.79 |
| 20 | 938.92 | 46.89 |

`llama-server` real:

```text
20/20 + prio 0
prefill 919.42
decode   43.86

8/8 + prio 0
prefill 922.62
decode   44.30

8/8 + prio 2
prefill 914.26
decode   43.98
```

Configuración final:

```text
threads       8
threads-batch 8
priority      default
power plan    Balanced
```

## Vision

```text
peak observed VRAM ~15306 MiB
vision             PASS
OCR/text           PASS
```

MMProj permanece en GPU.

## Prompt cache

```text
Cold:
prompt tokens 54662
prefill       ~72.1 s

Cached new turn:
tokens evaluated 21
prefill          ~0.37 s

No-cache control:
prompt tokens 54663
prefill       ~72.8 s
```

Prefix reuse validado.

## Context curve

| Contexto | Prefill tok/s | Decode tok/s |
|---:|---:|---:|
| 4K | 916.74 | 42.71 |
| 16K | 897.25 | 38.35 |
| 33K | 829.84 | 33.29 |
| 66K | 722.49 | 26.43 |
| 133K | 573.06 | 18.74 |
| 199K | 472.88 | 14.57 |
| 241K | 427.80 | 12.79 |

El contexto completo de `262144` se conserva deliberadamente disponible.

## Configuración final

```text
Prism build           10709
CUDA build            13.3
context               262144
parallel slots             1
threads                    8
threads-batch              8
batch                   2048
ubatch                   512
GPU layers                99
Flash Attention           on
CUDA Graphs               on
KV K                    q4_0
KV V                    q4_0
KV mean-centering         on
MMProj                    GPU
image-min-tokens         1024
cache RAM                4096 MiB
context checkpoints        32
idle-slot cache            on
Windows power         Balanced
```
