---
description: Dónde está la documentación de los paquetes de los que depende este proyecto.
allowed-tools: Bash
---

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-paquetes.sh"
```

Un SPM propio bien documentado es **invisible desde el proyecto que lo consume**. Se declara
por URL, así que sus fuentes acaban en `.build/checkouts/` o en
`DerivedData/…/SourcePackages/checkouts/`: rutas ignoradas por git, que no existen hasta que
alguien compila, y que todo el mundo trata como ruido de build.

El síntoma es fácil de reconocer: el `AGENTS.md` del proyecto remite a «el artículo `Lint` de
`Documentation.docc` de AppFoundation» y esa ruta **no existe** desde la raíz del repo. La
doc está escrita y nadie la lee — no por desobediencia, por geografía.

Esto imprime las rutas resueltas de hoy. **Léelas antes de usar los tipos de un paquete**,
sobre todo antes de escribir una capa nueva: las reglas de arquitectura que hacen fallar el
build (qué puede importar qué, qué no puede cruzar una frontera) están ahí, no en el
proyecto.

No las copies a ningún fichero del repo: cambian al subir la versión del paquete. Vuelve a
preguntar.
