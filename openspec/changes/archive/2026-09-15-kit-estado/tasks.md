## 1. Lo compartido, a `lib-kit.sh`, sin cambiar el digest

- [x] 1.1 Guardar la salida actual de `inyecta-contexto.sh` sobre este repositorio y sobre un repositorio temporal con un cambio activo con tareas pendientes; son la referencia de 1.4
- [x] 1.2 `cambio_activo` deja también `ACTIVOS` con todas las rutas, una por línea y en el mismo orden; verificar con dos cambios en un repositorio temporal que `ACTIVO` y `ACTIVOS_N` no cambian y `ACTIVOS` trae los dos
- [x] 1.3 Mover el recuento de tareas del hook a `recuento_tareas` en `lib-kit.sh`, con su nota del `grep -c … || true`, y que el hook la use; verificar que sin `tasks.md` deja las variables vacías
- [x] 1.4 Comprobar que el digest sale byte a byte igual que en 1.1 y que `bash scripts/verifica-contexto.sh` sale en verde; `/kit-revisa` sobre esta rodaja

## 2. Versiones con el consejo que las arregla

- [x] 2.1 `version_kit` en `lib-kit.sh`, con la lectura de `installed_plugins.json` y la tabla de consejos de la spec `estado-del-kit`
- [x] 2.2 `verifica.sh` usa `version_kit` y conserva encima su consulta diaria al remoto; su `mkdir -p .agent-kit` pasa a después del `case` de modos; verificar que `bash scripts/verifica-salidas.sh` sale en verde
- [x] 2.3 Con un `HOME` temporal y una copia del kit con otra versión, medir los tres casos (todo igual, instalada distinta de la que corre, clon distinto de la instalada) y el de instalada ilegible, y que el informe de `verifica.sh` dé el consejo de la spec; `/kit-revisa` sobre esta rodaja

## 3. `/kit-estado`

- [x] 3.1 `scripts/estado.sh`, con la cabecera que declara sus límites (texto del detector, `kit.conf` que se carga, sin red, sin banco); verificar que `bash -n` y `shellcheck --severity=warning` salen limpios
- [x] 3.2 `commands/kit-estado.md`, que invoca el script por `${CLAUDE_PLUGIN_ROOT}`; verificar que `bash scripts/autocomprueba.sh` sale en verde
- [x] 3.3 Medir los criterios de la propuesta: menos de 1 s y nada escrito en AppStarter en tres corridas; nada creado en un repositorio temporal sin `.agent-kit/`; dos cambios activos, uno sin `tasks.md`; el mismo veredicto que `verifica.sh --comprueba` en los cuatro casos; rama sin upstream; fuera de un repositorio git; el mismo consejo que el informe en los casos de 2.3; `/kit-revisa` sobre esta rodaja

## 4. Documentación y cierre

- [x] 4.1 `README.md` (lista de `commands/` y bloque «Para mejorar el kit»), `docs/PIEZAS.md` (tabla de comandos) y `docs/INSTALACION.md` (sección «Actualizar»): `/kit-estado` aparece donde se listan los comandos, y actualizar dice conversación nueva; verificar con `grep -n 'kit-estado\|conversación nueva' README.md docs/PIEZAS.md docs/INSTALACION.md`
- [x] 4.2 `/kit-verifica` en verde con `LANG=` y con `LANG=en_US.UTF-8`; `/kit-revisa` sobre la última rodaja
- [x] 4.3 `/kit-acepta` contra este acuerdo antes de archivar

- Ronda 1 del juez: ACEPTADO · comportamiento: no
