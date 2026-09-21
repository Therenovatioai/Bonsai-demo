# Bonsai 2 27B

Runtime local estable de **Bonsai 2 27B** sobre llama.cpp, preparado para uso mediante API OpenAI-compatible.

## Estado

- Modelo: `Ternary-Bonsai-2-27B-PQ2_0.gguf`
- Visión: `Ternary-Bonsai-2-27B-mmproj-Q8_0.gguf`
- API: `http://127.0.0.1:8080/v1`
- Contexto: `262144`
- KV cache: `q4_0`
- Tool calling: validado
- Reasoning: validado mediante `reasoning_content`
- Visión + tools: validado
- Contexto largo: validado
- Stress test: **238876 input + 12288 output = 251164 tokens**, sin OOM

## Guía rápida

### Arrancar

```powershell
cd "$HOME\AI\Bonsai-demo"
.\start-bonsai.ps1
```

### Verificar

```powershell
Invoke-RestMethod http://127.0.0.1:8080/health
```

Respuesta esperada:

```text
status
------
ok
```

### Usar desde una aplicación compatible con OpenAI

```text
Base URL: http://127.0.0.1:8080/v1
Model:    bonsai2-27b
```

Endpoint principal:

```text
POST /v1/chat/completions
```

## Archivos locales importantes

```text
start-bonsai.ps1
templates/chat_template.jinja
MODEL-MANIFEST.md
```

El template local permite múltiples mensajes `system/developer`.

## Nota operativa

No ejecutar Bonsai y Qwen/KVMem simultáneamente.

La configuración estable usa:

```text
context:          262144
parallel slots:        1
KV:                 q4_0
MMProj:              CPU
GPU layers:            99
```

Baseline estable: `v1.0-stable`.
