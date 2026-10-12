# Guía para agentes

## Estructura

- `apps/backend`: aplicación backend.
- `apps/frontend`: aplicación frontend.
- `packages/commons`: código compartido.
- Cada workspace mantiene su propio `package.json` y `tsconfig.json`; la configuración TypeScript común está en `tsconfig.base.json`.
- Los frameworks de las aplicaciones aún están por decidir. No añadas dependencias o convenciones específicas de un framework sin una decisión explícita.

## Comandos

- `pnpm lint`: ejecuta ESLint en el repositorio.
- `pnpm test`: ejecuta los tests Vitest de cada workspace; también forma parte de `pnpm check`.
- `pnpm typecheck`: ejecuta el typecheck de todos los workspaces.
- `pnpm depcruise`: comprueba ciclos, imports no resolubles y fronteras entre módulos.
- `pnpm check:api`: valida `packages/commons/openapi.yaml` con Spectral; los errores bloquean y los warnings se muestran sin fallar.
- `pnpm check:api:generated`: falla si los tipos OpenAPI versionados no coinciden con el contrato actual, sin modificar archivos.
- `pnpm generate:api`: genera los tipos TypeScript desde `packages/commons/openapi.yaml` en `packages/commons/src/generated`; regenera después de cambiar el contrato.
- `pnpm check:report`: ejecuta `pnpm check` y genera reportes JSON de ESLint, Knip y Spectral en `reports/` para consumo por herramientas; los reportes son auxiliares y no se versionan. El código de salida de `pnpm check` es el resultado definitivo; la generación de reportes es best-effort.
- `pnpm check:ci`: ejecuta las comprobaciones bloqueantes del proyecto mediante `pnpm check`; es el punto de entrada usado por CI.
- `pnpm check:audit`: analiza `pnpm-lock.yaml` con OSV-Scanner para detectar vulnerabilidades conocidas. Es optativo, requiere Docker y acceso a OSV.dev; si Docker no está disponible, muestra un aviso y omite el análisis. No forma parte de `pnpm check` ni de los hooks.
- `pnpm check`: ejecuta lint, typecheck, tests, dependency-cruiser, Knip, Syncpack y las comprobaciones del contrato OpenAPI; úsalo antes de finalizar cambios.
- CI ejecuta `pnpm check:ci` en pull requests y al hacer push a `main`; en pull requests también compara el contrato OpenAPI con su SHA base usando oasdiff, y omite esa comparación con un aviso si el spec aún no existe en la base. `pnpm check:secrets` sigue siendo un análisis local del hook de commit que requiere Docker.
- El workflow `.github/workflows/semgrep.yml` publica el SARIF de Semgrep como artefacto. Para publicarlo también en GitHub Code Scanning, configura la variable de repositorio `SEMGREP_CODE_SCANNING` con el valor `true` en **Settings → Secrets and variables → Actions → Variables**. Requiere que Code Scanning esté disponible en el repositorio; se omite en pull requests desde forks. Los hallazgos son informativos y no bloquean CI.
- SonarCloud es opt-in y no forma parte de `pnpm check` ni `pnpm check:ci`; requiere `SONARCLOUD_ENABLED=true` y el secreto `SONAR_TOKEN`. La organización y la clave de proyecto se derivan del repositorio por defecto. Consulta [docs/sonarcloud.md](docs/sonarcloud.md) para configurarlo; las variables y secretos no se copian al crear un repositorio desde este template.
- `pnpm check:secrets`: analiza los cambios staged con Gitleaks en la imagen oficial de Docker; requiere Docker y omite el análisis con un aviso si Docker no está disponible. Se ejecuta automáticamente en `pre-commit` y puede omitirse con `git commit --no-verify`.
- `pnpm --filter <workspace> typecheck`: limita el typecheck a un workspace, por ejemplo `pnpm --filter @repo/backend typecheck`.
- `pnpm exec lint-staged`: aplica las tareas configuradas a los archivos staged.

### Interpretación de reportes

- Usa el resultado y la salida de `pnpm check` como fuente de verdad; la existencia o el contenido de un reporte no cambia su código de salida y un reporte puede estar incompleto si falla su generador.
- `reports/eslint.json` contiene problemas de lint; `reports/knip.json`, archivos, exports o dependencias sin uso; `reports/spectral.json`, hallazgos sobre el contrato OpenAPI. En Spectral, los errores bloquean `pnpm check` y los warnings son informativos.
- Los reportes sirven como detalle legible por herramientas para investigar los hallazgos, no se versionan y se regeneran con `pnpm check:report`.

Usa la versión de Node indicada en `package.json` y el gestor de paquetes fijado en `packageManager` (`pnpm`).

## Convenciones

- Mantén los cambios dentro del workspace correspondiente y reutiliza las configuraciones compartidas.
- Los workspaces TypeScript deben conservar un script `typecheck` que ejecute `tsc --noEmit`.
- No introduzcas herramientas que dependan de servicios externos en el flujo básico; cualquier integración de ese tipo debe ser opcional.
