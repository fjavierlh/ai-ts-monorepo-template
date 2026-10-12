# Configuración opcional de SonarCloud

El workflow `.github/workflows/sonarcloud.yml` ejecuta el análisis CI de SonarCloud en `push` a `main`, pull requests y ejecuciones manuales. Es opt-in: no se ejecuta salvo que se habilite explícitamente y no forma parte de `pnpm check`, `pnpm check:ci` ni de los hooks locales.

## Requisitos en SonarCloud

1. Crea una organización de SonarCloud e importa el repositorio de GitHub como proyecto.
2. En el proyecto, abre **Administration → Analysis Method** y desactiva **Automatic Analysis**. El análisis automático no debe combinarse con análisis CI; SonarCloud puede fallar los análisis CI si ambos están habilitados.
3. En SonarCloud, abre **My Account → Security** y genera un token con permiso para ejecutar análisis en el proyecto. Si tu plan lo permite, puedes usar un token de organización con permisos limitados al proyecto. No lo guardes en el repositorio ni lo pases como argumento del scanner.

Consulta la documentación de SonarCloud sobre [Automatic Analysis](https://docs.sonarsource.com/sonarqube-cloud/analyzing-source-code/automatic-analysis) y [GitHub Actions](https://docs.sonarsource.com/sonarqube-cloud/analyzing-source-code/ci-based-analysis/github-actions-for-sonarcloud).

## Configuración en GitHub

En el repositorio, ve a **Settings → Secrets and variables → Actions** y configura:

1. En **Variables**, crea `SONARCLOUD_ENABLED` con el valor exacto `true`. Sin esta variable, el job se omite.
2. En **Secrets**, crea `SONAR_TOKEN` con el token generado en SonarCloud.
3. Si los identificadores de SonarCloud no coinciden con los valores por defecto, añade estas variables opcionales:
   - `SONAR_ORGANIZATION`: clave de la organización de SonarCloud. Por defecto se usa `github.repository_owner`.
   - `SONAR_PROJECT_KEY`: clave del proyecto. Por defecto se usa `<github.repository_owner>_<nombre-del-repositorio>`.

Por ejemplo, para `acme/storefront`, los valores derivados serían `acme` y `acme_storefront`. Si SonarCloud asignó claves distintas al importar el proyecto, define los overrides para que coincidan con las claves mostradas por SonarCloud.

También se pueden usar variables y secretos de organización si la política de la organización permite compartirlos con el repositorio. En ese caso, no hace falta duplicar los valores por repositorio.

El análisis se ejecuta en pull requests internos y se omite en pull requests desde forks, donde GitHub no expone el secreto. El workflow no espera el resultado del Quality Gate: los resultados se consultan en SonarCloud y no bloquean este job.

## Repositorios creados desde este template

GitHub copia los archivos del template, incluido el workflow y `sonar-project.properties`, pero no copia variables, secretos ni otros ajustes del repositorio. Por tanto, SonarCloud queda desactivado en el repositorio nuevo hasta que configures `SONARCLOUD_ENABLED=true` y `SONAR_TOKEN` (y los overrides si hacen falta).

## Cobertura

El repositorio aún no tiene un runner de tests ni genera informes LCOV. Por eso la propiedad `sonar.javascript.lcov.reportPaths` está comentada en `sonar-project.properties` y no se carga cobertura en SonarCloud. Cuando se incorpore un runner, habrá que apuntar esa propiedad al informe que genere.

## Resolución de problemas

- **El job aparece omitido:** comprueba que `SONARCLOUD_ENABLED` sea una variable de Actions y tenga exactamente el valor `true`.
- **Falla la autenticación:** revisa `SONAR_TOKEN`, que no esté caducado y que tenga permiso para ejecutar análisis en el proyecto.
- **No se encuentra la organización o el proyecto:** configura `SONAR_ORGANIZATION` y `SONAR_PROJECT_KEY` con las claves exactas de SonarCloud.
- **El análisis CI falla aunque las claves y el token sean correctos:** comprueba que **Automatic Analysis** esté desactivado.
