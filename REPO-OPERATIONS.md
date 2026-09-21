# Operación del repositorio — Bonsai 2 27B

Este documento define cómo debe operar este repositorio una persona o un agente de IA.

El diseño actual usa **una sola rama operativa permanente: `main`**.

---

## 1. Arquitectura Git

### Proyecto oficial

```text
PrismML-Eng/Bonsai-demo
```

Remoto local:

```text
upstream
```

Uso:

```text
fetch: habilitado
push:  deshabilitado
```

No publicar cambios directamente en `upstream`.

### Fork personal

```text
Therenovatioai/Bonsai-demo
```

Remoto local:

```text
origin
```

Este es el destino normal de todos los `push`.

### Diagrama

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
       main
        │
        ├── código recibido de PrismML
        ├── configuración local
        ├── optimizaciones
        ├── documentación
        └── integraciones locales
```

---

## 2. Rama operativa

La rama permanente de trabajo es:

```text
main
```

No existe una rama `optimized` en el flujo normal.

Antes de trabajar:

```powershell
git branch --show-current
```

Salida esperada:

```text
main
```

Y:

```powershell
git status -sb
```

Debe mostrar un árbol limpio o cambios comprendidos por el operador.

---

## 3. Remotos esperados

Comprobar:

```powershell
git remote -v
```

Estado esperado:

```text
origin    https://github.com/Therenovatioai/Bonsai-demo
upstream  https://github.com/PrismML-Eng/Bonsai-demo.git
upstream  DISABLED (push)
```

Comprobar específicamente:

```powershell
git remote get-url origin
git remote get-url upstream
git remote get-url --push upstream
```

El remoto de push por defecto debe ser:

```text
origin
```

Comprobar:

```powershell
git config --get remote.pushDefault
```

---

## 4. Flujo normal de trabajo

Antes de modificar:

```powershell
Set-Location "$HOME\AI\Bonsai-demo"

git switch main
git status -sb
```

Después de realizar cambios:

```powershell
git add <archivos>
git commit -m "tipo: descripción"
git push origin main
```

No usar:

```powershell
git push upstream
```

El push de `upstream` está deshabilitado deliberadamente.

---

## 5. Cómo incorporar cambios nuevos de PrismML

El flujo normal prioriza **seguridad y baja complejidad**.

No se usa rebase como procedimiento estándar porque reescribe la historia local y obliga a realizar force-push.

### Paso 1 — obtener cambios oficiales

```powershell
Set-Location "$HOME\AI\Bonsai-demo"

git switch main
git status -sb
git fetch upstream
```

### Paso 2 — revisar qué cambió

```powershell
git log --oneline HEAD..upstream/main
```

Opcionalmente:

```powershell
git diff --stat HEAD..upstream/main
```

### Paso 3 — incorporar upstream

```powershell
git merge --no-edit upstream/main
```

Si no hay conflictos, Git incorporará los cambios oficiales manteniendo la historia local.

Si existen conflictos:

1. detenerse;
2. revisar cada archivo;
3. conservar deliberadamente las optimizaciones locales cuando sigan siendo válidas;
4. incorporar cambios upstream compatibles;
5. completar el merge;
6. repetir las validaciones del runtime.

No resolver conflictos automáticamente sin revisar su impacto.

### Paso 4 — validar Bonsai

No publicar inmediatamente después del merge.

Primero ejecutar las validaciones descritas en la sección siguiente.

### Paso 5 — publicar

Si las validaciones pasan:

```powershell
git push origin main
```

No se necesita `--force`.

---

## 6. Validación después de una actualización

Una actualización de PrismML no implica que el baseline optimizado siga siendo válido.

Arrancar:

```powershell
.\start-bonsai.ps1
```

Comprobar salud:

```powershell
Invoke-RestMethod http://127.0.0.1:8080/health
```

Consultar propiedades:

```powershell
$props = Invoke-RestMethod http://127.0.0.1:8080/props

$props.total_slots

$props.default_generation_settings.params |
    Select-Object temperature, top_k, top_p, min_p
```

Comprobar proceso real:

```powershell
Get-CimInstance Win32_Process |
    Where-Object { $_.Name -eq "llama-server.exe" } |
    Select-Object -ExpandProperty CommandLine
```

Invariantes esperados:

```text
context                 262144
parallel slots               1
threads                      8
threads-batch                8
GPU layers                  99
Flash Attention              on
KV K                      q4_0
KV V                      q4_0
KV mean-centering            on
MMProj                       GPU
image-min-tokens            1024
cache RAM                  4096 MiB
context checkpoints          32
idle-slot cache              on
min-p                        0
CORS                    localhost
```

Si una actualización cambia el runtime, repetir los benchmarks relevantes antes de declarar un nuevo baseline.

---

## 7. Concurrencia y solicitudes de clientes

La configuración estable usa:

```text
-np 1
```

Esto crea un único slot de inferencia.

Aunque OpenCode u otro cliente envíe varias solicitudes simultáneas:

- una solicitud ocupa el slot;
- las demás esperan;
- el modelo procesa la inferencia de forma secuencial.

Verificar:

```powershell
$props = Invoke-RestMethod http://127.0.0.1:8080/props
$props.total_slots
```

Salida esperada:

```text
1
```

Y:

```powershell
Invoke-RestMethod http://127.0.0.1:8080/slots |
    ConvertTo-Json -Depth 10
```

Debe existir únicamente:

```text
id: 0
```

No aumentar `-np` sin repetir pruebas de VRAM, contexto y prompt cache.

---

## 8. Tags y baselines

Los tags publicados son snapshots históricos.

Actualmente:

```text
v1.0-stable
v1.1-optimized
```

Regla:

**un tag publicado no se mueve.**

Si un nuevo estado pasa todas las validaciones:

```powershell
git tag -a v1.2-optimized -m "Optimized Bonsai 2 27B baseline"
git push origin v1.2-optimized
```

Antes de crear un tag:

```powershell
git status -sb
git log -5 --oneline --decorate
```

El working tree debe estar limpio.

---

## 9. Ramas de respaldo

Pueden existir ramas locales como:

```text
backup/pre-10709-optimization
backup/pre-fork-layout
backup/pre-main-unification
```

No son ramas operativas.

No hacer trabajo normal sobre ellas.

Su función es servir como puntos de recuperación.

Pueden mantenerse mientras sea útil conservar esos estados históricos.

---

## 10. Recuperación

Antes de cualquier operación destructiva:

```powershell
git status
git log --graph --decorate --oneline --all -20
git reflog -20
```

### Volver al baseline v1.1

Solo si se desea descartar deliberadamente todos los cambios posteriores:

```powershell
git switch main
git reset --hard v1.1-optimized
```

No ejecutar este comando si hay trabajo local sin guardar.

### Comparar con un backup

Ejemplo:

```powershell
git diff backup/pre-main-unification..main
```

---

## 11. Seguridad de remotos

El push al proyecto oficial está bloqueado localmente:

```powershell
git remote set-url --push upstream DISABLED
```

Esto es intencional.

Comprobar:

```powershell
git remote -v
```

El repositorio por defecto de GitHub CLI debe ser:

```text
Therenovatioai/Bonsai-demo
```

Comprobar:

```powershell
gh repo set-default --view
```

---

## 12. Pull requests hacia PrismML

No abrir un Pull Request de todo `main` hacia PrismML.

`main` contiene configuración y decisiones específicas de esta instalación.

Si una mejora concreta puede beneficiar a PrismML:

1. crear una rama temporal desde el upstream apropiado;
2. aislar únicamente la mejora genérica;
3. eliminar dependencias específicas de la workstation;
4. añadir pruebas y documentación;
5. abrir un PR específico.

Ejemplo conceptual:

```powershell
git fetch upstream
git switch -c contribution/<nombre> upstream/main
```

Después de terminar la contribución, volver a:

```powershell
git switch main
```

---

## 13. Archivos que describen el baseline

```text
README-LOCAL.md
MODEL-MANIFEST.md
OPTIMIZATION-RESULTS.md
REPO-OPERATIONS.md
start-bonsai.ps1
kv-calibration-corpus.txt
templates/chat_template.jinja
results/bonsai2-5060ti-context-curve-10709.csv
```

### `README-LOCAL.md`

Resumen operativo.

### `MODEL-MANIFEST.md`

Estado técnico reproducible.

### `OPTIMIZATION-RESULTS.md`

Benchmarks y decisiones.

### `REPO-OPERATIONS.md`

Operación Git, actualización, recuperación y mantenimiento.

### `start-bonsai.ps1`

Punto de entrada estable del runtime.

---

## 14. Checklist para una persona o agente

Antes de modificar:

```text
[ ] Estoy en main
[ ] Entiendo el estado de git status
[ ] origin apunta a Therenovatioai/Bonsai-demo
[ ] upstream apunta a PrismML-Eng/Bonsai-demo
[ ] upstream tiene push deshabilitado
```

Antes de incorporar PrismML:

```text
[ ] main está limpio
[ ] ejecuté git fetch upstream
[ ] revisé HEAD..upstream/main
[ ] incorporo con git merge upstream/main
```

Antes de publicar después de una actualización:

```text
[ ] runtime arranca
[ ] /health devuelve ok
[ ] contexto = 262144
[ ] total_slots = 1
[ ] KV Q4 + mean-centering siguen activos
[ ] MMProj sigue en GPU
[ ] prompt cache sigue configurado
[ ] no observé regresiones relevantes
[ ] documentación sigue siendo correcta
```

Antes de crear un nuevo baseline:

```text
[ ] working tree limpio
[ ] runtime validado
[ ] benchmarks necesarios completados
[ ] documentación actualizada
[ ] commit final creado
[ ] tag nuevo creado
[ ] tag publicado en origin
```

---

## 15. Estado operativo actual

Repositorio oficial:

```text
PrismML-Eng/Bonsai-demo
```

Fork:

```text
Therenovatioai/Bonsai-demo
```

Rama operativa:

```text
main
```

Baseline histórico vigente del runtime:

```text
v1.1-optimized
```

Commit del baseline:

```text
74ffb8dcad57125c6165d3e5339bb48c97735f42
```

`main` puede contener documentación u otros commits posteriores al tag sin que el tag se mueva.

La fuente operativa de esta instalación es siempre:

```text
origin/main
```
