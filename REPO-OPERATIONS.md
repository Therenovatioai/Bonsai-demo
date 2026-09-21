# Operación del repositorio — Bonsai 2 27B

Este documento define cómo debe operarse este repositorio por una persona o por un agente de IA.

El objetivo es conservar una separación clara entre:

1. el proyecto oficial de PrismML;
2. el fork personal;
3. la rama limpia que refleja upstream;
4. la rama optimizada de uso real;
5. los baselines históricos reproducibles.

---

## 1. Arquitectura Git

### Repositorio oficial

```text
PrismML-Eng/Bonsai-demo
```

Se configura localmente como:

```text
upstream
```

Uso:

```text
fetch: habilitado
push:  deshabilitado
```

No se deben publicar cambios directamente en `upstream`.

### Fork personal

```text
Therenovatioai/Bonsai-demo
```

Se configura localmente como:

```text
origin
```

Este es el destino normal de los `push`.

---

## 2. Ramas

### `main`

`main` debe mantenerse como una copia limpia de:

```text
upstream/main
```

No se realizan optimizaciones locales directamente sobre `main`.

Su función es:

- representar el estado oficial de PrismML;
- facilitar la comparación contra upstream;
- servir como nueva base cuando PrismML publica cambios;
- permitir rebase limpio de la rama optimizada.

### `optimized`

Es la rama de trabajo real de esta instalación.

Contiene:

- configuración local;
- `start-bonsai.ps1`;
- documentación local;
- KV calibration corpus;
- benchmarks;
- ajustes de CUDA/runtime;
- configuración de threads;
- prompt cache;
- integración futura con OpenCode.

El trabajo cotidiano debe realizarse sobre:

```text
optimized
```

Comprobar antes de trabajar:

```powershell
git branch --show-current
```

Salida esperada:

```text
optimized
```

---

## 3. Remotos esperados

Comprobar con:

```powershell
git remote -v
```

Estado esperado:

```text
origin    https://github.com/Therenovatioai/Bonsai-demo
upstream  https://github.com/PrismML-Eng/Bonsai-demo.git
```

El push de `upstream` debe estar deshabilitado:

```text
upstream  DISABLED (push)
```

Comprobar específicamente:

```powershell
git remote get-url origin
git remote get-url upstream
git remote get-url --push upstream
```

---

## 4. Flujo normal de trabajo

Antes de modificar el repo:

```powershell
Set-Location "$HOME\AI\Bonsai-demo"

git switch optimized
git status -sb
```

El árbol de trabajo debe estar limpio antes de una operación importante.

Después de realizar cambios:

```powershell
git add <archivos>
git commit -m "tipo: descripción"
git push origin optimized
```

No usar `git push upstream`.

---

## 5. Cómo actualizar desde PrismML

Cuando PrismML publique cambios nuevos, primero actualizar la rama limpia.

### Paso 1 — actualizar referencias oficiales

```powershell
Set-Location "$HOME\AI\Bonsai-demo"

git fetch upstream
```

### Paso 2 — actualizar `main`

```powershell
git switch main
git merge --ff-only upstream/main
git push origin main
```

El `--ff-only` evita crear merges accidentales en `main`.

Después:

```powershell
git rev-parse main
git rev-parse upstream/main
```

Ambos SHA deben coincidir.

### Paso 3 — reaplicar la versión optimizada

```powershell
git switch optimized
git rebase main
```

Si el rebase termina sin conflictos, ejecutar las validaciones necesarias del runtime.

### Paso 4 — publicar la rama optimizada actualizada

Debido a que un rebase reescribe los SHA de los commits:

```powershell
git push --force-with-lease origin optimized
```

Usar:

```text
--force-with-lease
```

y no:

```text
--force
```

porque `--force-with-lease` protege contra sobrescribir cambios remotos inesperados.

---

## 6. Qué validar después de actualizar upstream

Una actualización de PrismML no implica automáticamente que el runtime optimizado siga siendo válido.

Comprobar como mínimo:

```powershell
.\start-bonsai.ps1
```

Luego:

```powershell
Invoke-RestMethod http://127.0.0.1:8080/health
```

Y verificar:

```powershell
$props = Invoke-RestMethod http://127.0.0.1:8080/props

$props.total_slots
$props.default_generation_settings.params |
    Select-Object temperature, top_k, top_p, min_p

Get-CimInstance Win32_Process |
    Where-Object { $_.Name -eq "llama-server.exe" } |
    Select-Object -ExpandProperty CommandLine
```

Invariantes actuales esperados:

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

No crear un nuevo tag hasta validar el runtime.

---

## 7. Solicitudes concurrentes

La configuración estable usa:

```text
-np 1
```

Esto significa que `llama-server` expone un solo slot de inferencia.

Aunque un cliente como OpenCode envíe varias solicitudes simultáneamente:

- solo una puede ocupar el slot;
- las siguientes esperan;
- el modelo procesa las solicitudes de forma secuencial.

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

No aumentar `-np` sin repetir pruebas de memoria, cache y concurrencia.

---

## 8. Tags y baselines

Los tags representan estados históricos reproducibles.

Actualmente:

```text
v1.0-stable
v1.1-optimized
```

Regla:

**un tag publicado no se mueve.**

No reutilizar:

```text
v1.1-optimized
```

para un estado nuevo.

Cuando una futura actualización sea validada:

```powershell
git tag -a v1.2-optimized -m "Optimized Bonsai 2 27B baseline"
git push origin v1.2-optimized
```

Antes de crear el tag comprobar:

```powershell
git status -sb
git log -5 --oneline --decorate
```

El working tree debe estar limpio.

---

## 9. Backups locales

Actualmente existen ramas de respaldo, entre ellas:

```text
backup/pre-fork-layout
backup/pre-10709-optimization
```

No forman parte del flujo normal.

Su función es permitir recuperación manual si una operación de Git daña la rama principal de trabajo.

No eliminarlas mientras siga siendo útil conservar esos puntos de recuperación.

---

## 10. Recuperación básica

### Si `optimized` queda en un estado incorrecto

Primero no ejecutar comandos destructivos adicionales.

Inspeccionar:

```powershell
git status
git log --graph --decorate --oneline --all -20
git reflog -20
```

La rama de respaldo del layout actual apunta al baseline `v1.1-optimized`:

```text
backup/pre-fork-layout
```

Para comparar:

```powershell
git diff backup/pre-fork-layout..optimized
```

### Recuperar exactamente `v1.1-optimized`

Solo cuando se quiera descartar deliberadamente el estado posterior:

```powershell
git switch optimized
git reset --hard v1.1-optimized
```

No ejecutar este comando si existen cambios locales que deban conservarse.

---

## 11. Seguridad de remotos

La configuración local deshabilita los pushes al proyecto oficial:

```powershell
git remote set-url --push upstream DISABLED
```

Esto es intencional.

Comprobar:

```powershell
git remote -v
```

Debe verse:

```text
upstream  DISABLED (push)
```

El remoto preferido para push es:

```text
origin
```

Comprobar:

```powershell
git config --get remote.pushDefault
```

Salida esperada:

```text
origin
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

## 12. Pull requests

La rama `optimized` es una distribución/configuración local.

No abrir automáticamente un Pull Request de `optimized` hacia PrismML.

Si una mejora concreta resulta genérica y útil para upstream:

1. aislarla en un commit o rama separada;
2. eliminar dependencias específicas del equipo local;
3. añadir pruebas/documentación;
4. abrir un PR específico hacia PrismML.

No utilizar toda la rama `optimized` como PR upstream.

---

## 13. Qué archivos describen el baseline local

Archivos principales:

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

Responsabilidades:

### `README-LOCAL.md`

Resumen operativo de la instalación.

### `MODEL-MANIFEST.md`

Estado técnico reproducible del modelo y runtime.

### `OPTIMIZATION-RESULTS.md`

Resultados de benchmarks y decisiones de optimización.

### `REPO-OPERATIONS.md`

Procedimiento Git y mantenimiento del fork.

### `start-bonsai.ps1`

Punto de entrada estable del runtime local.

---

## 14. Checklist para una persona o agente

Antes de modificar:

```text
[ ] Estoy en la rama optimized
[ ] git status está limpio o entiendo los cambios presentes
[ ] origin apunta al fork personal
[ ] upstream apunta a PrismML
[ ] no voy a hacer push a upstream
```

Antes de actualizar PrismML:

```text
[ ] fetch upstream
[ ] main se actualiza con --ff-only
[ ] main coincide con upstream/main
[ ] optimized se rebasa sobre main
```

Antes de publicar optimized después de rebase:

```text
[ ] runtime arranca
[ ] /health devuelve ok
[ ] contexto sigue en 262144
[ ] total_slots sigue en 1
[ ] KV Q4 + mean-centering siguen activos
[ ] MMProj sigue en GPU
[ ] prompt cache sigue configurado
[ ] no hay regresiones relevantes
[ ] push usa --force-with-lease
```

Antes de crear un nuevo baseline:

```text
[ ] documentación actualizada
[ ] working tree limpio
[ ] benchmarks necesarios completados
[ ] commit final creado
[ ] tag nuevo, nunca reutilizado
[ ] tag publicado en origin
```

---

## 15. Estado actual conocido

A fecha del baseline `v1.1-optimized`:

```text
upstream:
PrismML-Eng/Bonsai-demo

origin:
Therenovatioai/Bonsai-demo

rama oficial espejo:
main

rama de trabajo:
optimized

baseline:
v1.1-optimized

baseline commit:
74ffb8dcad57125c6165d3e5339bb48c97735f42
```

La rama `optimized` debe considerarse la fuente operativa de esta instalación.
