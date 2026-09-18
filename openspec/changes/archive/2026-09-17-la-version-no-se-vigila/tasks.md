## 1. Restar código

- [x] 1.1 `scripts/lib-kit.sh`: borrar `version_kit` y `version_json`. Verificación: `grep -n 'version_kit\|version_json' scripts/lib-kit.sh` vacío (`version_swift` es otra función y se queda) y `shellcheck --severity=warning` limpio. Hecho: `version_kit` y `version_json` fuera; `lib-kit.sh` en 142 líneas; shellcheck limpio
- [x] 1.2 `scripts/verifica.sh`: borrar la llamada a `version_kit`, el bloque de consulta al remoto, `DESFASE` y sus dos líneas de informe. Verificación: `bash scripts/verifica.sh` en verde y no aparece `.agent-kit/.consulta-version` en un repositorio temporal. Hecho: sin consulta al remoto ni `DESFASE`; en un repositorio temporal con `HOME` aislado el informe no menciona «desfasado» y `.agent-kit/` solo tiene el marker y el hook
- [x] 1.3 `scripts/estado.sh`: la sección de versión pasa a leer `plugin.json` con un `sed` y a imprimir una línea. Verificación: `bash scripts/estado.sh | grep '▶ Kit'` da una línea con la versión de `.claude-plugin/plugin.json`. Hecho: `▶ Kit: 1.14.0` leído de `plugin.json`; sin más líneas de versión
- [x] 1.4 `scripts/verifica-salidas.sh`: no tenía casos de consejo de versión (corría con `HOME` temporal para esquivarlos); solo cambia el comentario que lo explicaba. Verificación: banco en verde, 52 casos

## 2. Decirlo

- [x] 2.1 `docs/INSTALACION.md` («Actualizar»), `README.md` («Para mejorar el kit»), `docs/PIEZAS.md` y `commands/kit-estado.md`: auto-update desde `/plugin` › Marketplaces y `/reload-plugins`; vía manual en una línea; fuera «abre una conversación nueva». Verificación: los dos `grep` de los criterios de aceptación. Hecho: INSTALACION («Actualizar» con auto-update y `/reload-plugins`), README («Para mejorar el kit»), `kit-estado.md` sin la viñeta de la conversación nueva; los dos `grep` en verde salvo las dos specs vivas que este archivado retira
- [x] 2.2 Borrar `.agent-kit/.consulta-version` de este repositorio. Verificación: `ls -a .agent-kit/`. Hecho
## 3. Cierre

- [x] 3.1 Correr los criterios de aceptación del `proposal.md` y anotar el resultado. Hecho: los siete criterios comprobados; el de `verifica-salidas.sh` con el recuento sin cambio (52), como se renegoció por escrito
- [x] 3.2 `/kit-revisa`, una ronda; decide el owner. Ronda 1 del revisor: GREEN · comportamiento: no. Cuatro observaciones sin bloqueo; se corrigió el texto de verificación de la tarea 1.1, que no era ejecutable
- [x] 3.3 `/kit-verifica` en verde
