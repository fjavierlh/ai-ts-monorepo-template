# Plan: análisis estático del monorepo

## Objetivo

Incorporar análisis estático que ayude a las personas y a los agentes a detectar y corregir problemas, con feedback rápido en local y análisis más profundos en CI. Las herramientas se añadirán gradualmente, en sesiones separadas, y cada fase deberá dejar el repositorio en un estado funcional.

## Decisiones

- El repositorio será un template reutilizable; las herramientas que requieran servicios o infraestructura serán opcionales y no bloquearán el flujo por defecto.
- El monorepo tendrá `apps/backend`, `apps/frontend` y `packages/commons`.
- Backend y frontend usarán TypeScript. El framework de backend y el framework/metaframework de frontend aún están por decidir.
- Mantener TypeScript en `6.x` hasta que `typescript-eslint` sea compatible con la API de TypeScript 7; evaluar la actualización por separado.
- Usar la versión soportada actual de ESLint (`10.x`); incorporar plugins específicos del frontend solo cuando declaren compatibilidad con la major adoptada.
- Usar Vitest como runner de tests del monorepo; `pnpm test` los ejecuta y `pnpm check` los incluye. La cobertura LCOV se incorporará por separado.
- `packages/commons` contendrá `openapi.yaml` y los tipos/DTOs compartidos. Se incluirán generación de tipos desde OpenAPI y una comprobación de que el código generado no está desactualizado.
- Para las reglas de Sonar se usará `eslint-plugin-sonarjs` localmente; SonarCloud será opcional en CI.
- Las herramientas se incorporarán de una en una en sesiones posteriores, no todas juntas.

## Capas de ejecución

| Capa             | Alcance previsto                                                         | Objetivo                                      |
| ---------------- | ------------------------------------------------------------------------ | --------------------------------------------- |
| `pre-commit`     | Archivos staged, autofix de formato/lint y detección de secretos         | Feedback rápido y bloqueo de errores claros   |
| `pre-push`       | Comprobaciones del proyecto, como tipos, dependencias y arquitectura     | Detectar problemas que necesitan más contexto |
| CI de PR         | SAST, validación de contratos y análisis opcionales de calidad/seguridad | Análisis profundo y reportes compartibles     |
| Nightly u opt-in | Análisis costosos, como mutation testing                                 | Evitar ralentizar el trabajo diario           |

El alcance exacto de cada hook se decidirá al implementar las fases, midiendo el tiempo de ejecución. No se ejecutará un análisis de proyecto completo en cada commit si hace lento el ciclo de trabajo.

## Fases propuestas

### Fase 0 — Fundaciones del monorepo

- Crear el workspace de pnpm para `apps/*` y `packages/*` y la estructura inicial de módulos.
- Definir configuración TypeScript compartida y la estrategia de compilación/typecheck por paquete.
- Incorporar Turborepo para orquestación y cache de tareas, si encaja con la estructura final.
- Añadir ESLint 10 con flat config y `typescript-eslint`, junto con `eslint-config-prettier`.
- Definir scripts comunes (`lint`, `typecheck`, `check`) y configurar `lint-staged` para ejecutar autofix sobre archivos staged.
- Documentar los comandos y convenciones para agentes en `AGENTS.md`.

### Fase 1 — Typecheck

- Ejecutar `tsc --noEmit` para los paquetes pertinentes.
- Integrarlo en los scripts del workspace y cachearlo mediante el runner si se adopta Turborepo.

### Fase 2 — Reglas Sonar locales

- Añadir `eslint-plugin-sonarjs` a ESLint.
- Mantener estas reglas disponibles en local sin requerir servidor externo.

### Fase 3 — Fronteras y ciclos de dependencias

- Configurar dependency-cruiser para comprobar las dependencias entre módulos y detectar ciclos.
- Reglas iniciales: `commons` no depende de código interno de las apps; backend y frontend pueden depender de `commons`, pero no entre sí.
- Adaptar los patrones de imports a la estructura real cuando se creen los paquetes.

### Fase 4 — Código y dependencias sin uso

- Incorporar Knip para detectar archivos, exports y dependencias no utilizados, configurado para el workspace.

### Fase 5 — Consistencia de dependencias

- Incorporar Syncpack para comprobar la consistencia de versiones entre paquetes, integrado en `pnpm check`.

### Fase 6 — Detección de secretos

- Incorporar Gitleaks mediante la imagen oficial de Docker, para analizar cambios staged en el hook de commit sin escanear innecesariamente el historial. Si Docker no está disponible, avisar y omitir el análisis.

### Fase 7 — Contrato OpenAPI en `commons`

- **7.1 — Lint de la especificación (completado)**
  - Añadir `packages/commons/openapi.yaml` con OpenAPI `3.1.0`.
  - Usar Spectral (`@stoplight/spectral-cli`) con `spectral:oas` para validar el contrato.
  - Exponerlo como `pnpm check:api` e integrarlo en `pnpm check`. Solo los errores bloquean; los warnings se muestran sin fallar.
- **7.2 — Generación de tipos compartidos (completado)**
  - Generar los tipos desde la especificación con `openapi-typescript` mediante `pnpm generate:api`.
  - Versionar la salida generada en `packages/commons/src/generated/openapi.d.ts` y exportarla desde `packages/commons/src/index.ts`.
- **7.3 — Consistencia de tipos generados (completado)**
  - Añadir una comprobación que falle si el resultado generado no coincide con el código versionado.
  - Exponerla como `pnpm check:api:generated` e integrarla en `pnpm check` sin modificar archivos.
- **7.4 — Cambios incompatibles en CI (completado)**
  - Usar oasdiff para detectar cambios incompatibles comparando con el SHA base del pull request; omitir la comparación con un aviso si el spec aún no existe en la base.
  - Bloquear cambios de nivel `ERR` y mostrar los de nivel `WARN` sin bloquear.
  - Desactivar la publicación del diff en el servicio externo (`review: false`); oasdiff se distribuye como binario/imagen y no como paquete npm.

### Fase 8 — Análisis específico del frontend

Tras elegir React y, en su caso, un metaframework:

- Evaluar `eslint-plugin-react`, `eslint-plugin-react-hooks` y `eslint-plugin-jsx-a11y` según las versiones y convenciones del stack elegido; incorporarlos solo si son compatibles con la major de ESLint adoptada.
- Evaluar `size-limit` para controlar el tamaño de los bundles.
- Añadir reglas específicas de límites entre código de servidor y cliente si se adopta TanStack Start u otro stack SSR.

### Fase 9 — Análisis específico del backend

- Tras elegir framework, evaluar sus plugins y reglas específicas.
- Mantener aplicables las reglas genéricas de TypeScript mientras el framework siga pendiente.

### Fase 10 — SAST con Semgrep en CI

- **Ejecución inicial (completada):** ejecutar Semgrep Community Edition en un workflow de CI independiente con reglas genéricas para TypeScript/JavaScript y `security-audit`; desactivar métricas y publicar el reporte SARIF como artefacto.
- **Integración con GitHub Code Scanning (completada, opt-in):** un job separado publica el SARIF cuando la variable de repositorio `SEMGREP_CODE_SCANNING=true` está configurada y Code Scanning está disponible; se omite en pull requests desde forks.
- Los hallazgos son informativos y no bloquean CI inicialmente (opción A). Incorporar más adelante el modo estricto (`--error`, opción B) tras revisar el ruido de las reglas.

### Fase 11 — SonarCloud opcional

- **Integración CI opt-in (completada):** añadir un workflow separado para SonarCloud, desactivado por defecto y fuera de `pnpm check` y los hooks; omitirlo en pull requests desde forks.
- Derivar organización y clave del proyecto del repositorio GitHub, permitiendo overrides por variables; documentar la configuración y que los secretos/variables no se heredan al crear un repositorio desde el template.
- **Runner de tests (completado):** adoptar Vitest en los workspaces; `pnpm test` lo ejecuta y `pnpm check` lo incluye.
- **Cobertura (completado):** añadir `pnpm test:coverage` optativo para generar un resumen de cobertura por workspace y un LCOV único con rutas relativas a la raíz; SonarCloud excluye los archivos de test de la cobertura.

### Fase 12 — Análisis opcional de supply chain e IaC

- **Vulnerabilidades de dependencias (completado):** añadir `pnpm check:audit`, comando opt-in que analiza `pnpm-lock.yaml` con OSV-Scanner mediante Docker. Si Docker no está disponible, avisa y omite el análisis; no se integra en `pnpm check` ni en los hooks.
- Evaluar Trivy para dependencias, IaC, secretos o contenedores, según lo que incorpore el repositorio.
- Evaluar CodeQL si la plataforma y el tipo de repositorio lo justifican.
- Mantener estas integraciones opt-in cuando dependan de plataforma, credenciales o infraestructura.

### Fase 13 — Salida orientada a agentes

- **Entrada inicial para CI (completada):** añadir `pnpm check:ci` como punto de entrada estable para las comprobaciones bloqueantes del proyecto; por ahora delega en `pnpm check`. Semgrep, oasdiff y los análisis opt-in permanecen separados.
- Consolidar comandos como `pnpm check` para feedback local rápido y ampliar `pnpm check:ci` con análisis adicionales cuando corresponda.
- **Reportes legibles por máquinas (completado, local opt-in):** `pnpm check:report` ejecuta `pnpm check` y genera reportes JSON de ESLint, Knip y Spectral en `reports/`, directorio ignorado por Git. Los reportes son best-effort; el código de salida sigue siendo el de `pnpm check`.
- Mantener códigos de salida correctos; añadir formatos JSON/SARIF para otras herramientas cuando estén disponibles.
- **Documentación para agentes (completado):** documentar en `AGENTS.md` qué comando ejecutar y cómo interpretar los reportes y el código de salida.
- Considerar un resumen JSON estable y un servidor MCP solo si el uso real demuestra que aportan valor.

### Fase 14 — Herramientas opcionales de mayor coste

- Evaluar jscpd para duplicación, Stryker para mutation testing, type-coverage para cobertura de tipos y API Extractor para controlar la superficie pública de `commons`.
- Ejecutarlas solo si las necesidades del proyecto lo justifican, posiblemente en CI nocturna.

## Orden y dependencias

Orden sugerido: **Fase 0 → Fases 1–6 → Fases 7–9 → Fases 10–12 → Fase 13 → Fase 14**.

Las fases 8 y 9 quedan pendientes de elegir los frameworks. Las fases que introduzcan infraestructura o configuración específica de plataforma se implementarán como opcionales. El plan se revisará conforme se concreten el layout, las aplicaciones y sus necesidades reales.
