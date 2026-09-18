## 1. Restar código

- [ ] 1.1 `scripts/lib-kit.sh`: borrar `version_kit` y `version_json`. Verificación: `grep -n version_ scripts/lib-kit.sh` vacío y `shellcheck --severity=warning` limpio
- [ ] 1.2 `scripts/verifica.sh`: borrar la llamada a `version_kit`, el bloque de consulta al remoto, `DESFASE` y sus dos líneas de informe. Verificación: `bash scripts/verifica.sh` en verde y no aparece `.agent-kit/.consulta-version` en un repositorio temporal
- [ ] 1.3 `scripts/estado.sh`: la sección de versión pasa a leer `plugin.json` con un `sed` y a imprimir una línea. Verificación: `bash scripts/estado.sh | grep '▶ Kit'` da una línea con la versión de `.claude-plugin/plugin.json`
- [ ] 1.4 `scripts/verifica-salidas.sh`: retirar los casos de consejo de versión. Verificación: banco en verde y su recuento anotado aquí

## 2. Decirlo

- [ ] 2.1 `docs/INSTALACION.md` («Actualizar»), `README.md` («Para mejorar el kit»), `docs/PIEZAS.md` y `commands/kit-estado.md`: auto-update desde `/plugin` › Marketplaces y `/reload-plugins`; vía manual en una línea; fuera «abre una conversación nueva». Verificación: los dos `grep` de los criterios de aceptación
- [ ] 2.2 Borrar `.agent-kit/.consulta-version` de este repositorio. Verificación: `ls -a .agent-kit/`

## 3. Cierre

- [ ] 3.1 Correr los criterios de aceptación del `proposal.md` y anotar el resultado
- [ ] 3.2 `/kit-revisa`, una ronda; decide el owner
- [ ] 3.3 `/kit-verifica` en verde
