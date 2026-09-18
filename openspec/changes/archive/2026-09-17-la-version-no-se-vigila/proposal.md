## Why

El kit compara tres versiones de sí mismo —la que corre, la instalada y la del clon del
marketplace—, consulta el remoto una vez al día y redacta un consejo distinto para cada
combinación. Son unas cien líneas entre `lib-kit.sh`, `verifica.sh`, `estado.sh`, dos specs
y sus casos de banco, y existen solo porque se publicaron catorce versiones en doce días y
había que avisar de cuál faltaba. Claude Code ya resuelve el problema: un marketplace con
auto-update activado refresca el plugin en disco después de arrancar, avisa, y
`/reload-plugins` lo carga sin cerrar la conversación. Lo que hacía falta no era un detector,
era activar una casilla.

## What Changes

- **Se retira la comparación de versiones**: `version_kit` y `version_json` de `lib-kit.sh`,
  el bloque de consulta al remoto y `DESFASE` de `verifica.sh`, el fichero
  `.agent-kit/.consulta-version`, y la sección de versión de `estado.sh` con sus cuatro ramas.
- **`/kit-estado` dice qué versión corre**, leída del `plugin.json` del plugin cargado. Una
  línea, sin consejo.
- **El informe de verificación deja de hablar de versiones.**
- **La documentación de actualizar cambia de instrucción**: activar auto-update para
  `hiram-kits` una vez desde `/plugin` › Marketplaces, y `/reload-plugins` cuando avise. La
  vía manual queda en una línea para quien no quiera auto-update.
- Los casos de banco que fijaban los consejos de versión desaparecen con ellos.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `estado-del-kit`: el requisito «La versión del kit se dice con el consejo que la arregla»
  se retira; lo sustituye «Dice qué versión del kit corre».
- `verificacion-firmada`: el requisito «El aviso de kit desfasado da el consejo que lo
  arregla» se retira.

## Fuera de alcance

- Activar el auto-update por el usuario: es una casilla de Claude Code, por marketplace, y la
  decide quien instala. El kit la documenta; no la toca.
- Detectar una conversación que sigue con una versión vieja. Con `/reload-plugins` ya no hace
  falta abrir otra, y el kit no tiene forma fiable de saberlo.
- El resto de `/kit-estado`.

## Criterios de aceptación

- [ ] `grep -n 'version_kit\|version_json\|consulta-version\|DESFASE\|CONSEJO_VERSION\|VER_CLON\|VER_INSTALADA' scripts/*.sh scripts/*.py` no encuentra nada.
- [ ] `bash scripts/estado.sh` en este repositorio imprime una línea `▶ Kit: <versión>` con la de `.claude-plugin/plugin.json`, y ninguna otra sobre versiones.
- [ ] `bash scripts/verifica.sh` no imprime «desfasado» ni consulta ningún remoto: con la red cortada (`GIT_TERMINAL_PROMPT=0` y un `HOME` temporal) tarda lo mismo y no crea `.agent-kit/.consulta-version`.
- [ ] `docs/INSTALACION.md` (sección «Actualizar») y `README.md` («Para mejorar el kit») dicen cómo activar auto-update y `/reload-plugins`, y no dicen «abre una conversación nueva».
- [ ] `grep -rn 'conversación nueva' README.md docs commands scripts openspec/specs` no encuentra nada.
- [ ] `scripts/verifica-salidas.sh` sigue en verde. No tenía casos de versión —corría con `HOME` en un temporal para esquivarlos—, así que lo único que cambia es ese comentario.
- [ ] `/kit-verifica` en verde.

## Impact

- `scripts/lib-kit.sh`, `scripts/verifica.sh`, `scripts/estado.sh`, `scripts/verifica-salidas.sh`: código fuera.
- `openspec/specs/estado-del-kit/spec.md`, `openspec/specs/verificacion-firmada/spec.md`: vía delta.
- `README.md`, `docs/INSTALACION.md`, `docs/PIEZAS.md`, `commands/kit-estado.md`: la instrucción nueva.
- Para quien usa el kit: activar auto-update una vez, o seguir actualizando a mano.
