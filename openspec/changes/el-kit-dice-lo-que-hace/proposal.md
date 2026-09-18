## Why

El kit tiene 888 líneas de código de producción y 3.561 de prosa (docs, specs, agentes y
comandos), más unas 1.200 líneas de comentario dentro de los scripts. Casi toda esa prosa es
**historia**: qué ponía antes, quién lo cazó, en qué fecha. Cada norma está escrita en varios
sitios (la de «stagea, verifica y commitea por separado» en nueve; la de cuándo invocar al juez
en cinco), así que un cambio de comportamiento toca entre 7 y 18 ficheros, y cada uno es un
sitio donde una revisión puede encontrar una frase que ya no cuadra. Medido en la auditoría
del 2026-09-17: ese abanico, más las normas que solo un modelo leyendo prosa puede comprobar,
son la causa del bucle «arreglo → hallazgo → arreglo» de los últimos doce días.

## What Changes

- **La historia sale del código y de las specs.** Los comentarios de `scripts/` y `kit.conf`
  dicen qué hace cada pieza y por qué ahora, sin fechas ni «hasta el día X esto era Y». Las
  specs conservan sus requisitos y escenarios; pierden los párrafos narrativos. La historia
  ya vive en el log de git y en `openspec/changes/archive/`.
- **Cada norma vive en un solo sitio.** Las demás menciones enlazan a él o desaparecen.
  Cuatro normas concretas se fijan como referencia: los tres comandos separados
  (`docs/PIEZAS.md`, sección de `verifica.sh`), cuándo se invoca el juez
  (`commands/kit-acepta.md`), el límite del acotado por prefijo (`scripts/lib-kit.sh` y
  `docs/PIEZAS.md`), y qué no frena la puerta (cabecera de `scripts/puerta-commit.sh`).
- **La documentación se colapsa a cuatro ficheros:** `README.md` corto, `docs/FLUJO.md`,
  `docs/PIEZAS.md` y `docs/INSTALACION.md`. `docs/PRIMER-CAMBIO.md` desaparece: es FLUJO con
  otro ejemplo. Sus tres piezas únicas —el formato del delta de spec, el veredicto real de
  ACUERDO-ROTO y «un cambio que no toca código»— pasan a FLUJO.
- **Se retiran las normas que solo un modelo puede comprobar sobre prosa:** «ningún documento
  SHALL prometer más garantía que el código», «toda mención de la garantía SHALL llevar su
  límite al lado», «las cifras SHALL vivir solo en X y nadie SHALL presentarlas como media»,
  «ningún documento SHALL decir que el kit cuenta rondas». Quedan las normas de
  comportamiento que sostenían.
- **Se retiran las cifras de coste que no se pueden recomprobar** (tokens por ronda de juez).
  Queda el orden de magnitud y el comando `claude plugin details` para lo que sí se puede medir.
- **Reglas de proceso para este repositorio** en `openspec/config.yaml`: el juez de aceptación
  no se invoca sobre el kit —aquí no hay compilador ni tests, solo prosa, y la prosa no
  converge—; el revisor da una ronda y decide el owner; un caso de banco nace solo por un
  fallo que llegó a un proyecto real, nunca por ronda.
- Sin cambio de comportamiento en ningún script: los 116 casos de banco siguen en verde y el
  digest de cada turno sale byte a byte igual.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `contexto-inyectado`: dos requisitos pierden sus cláusulas relativas a «igual que antes de
  este cambio», que no son norma permanente.
- `coste-del-juicio`: el requisito de coste deja de fijar cifras y dónde viven; el de la
  rodaja y el del archivado pierden las cláusulas que legislan sobre cómo se redacta.
- `deteccion-de-duplicados`: el requisito del suelo de ruido pierde la cláusula «este cambio
  NO SHALL mover ninguno», que era del cambio que lo escribió.
- `doc-de-paquetes`: el requisito del acotado por prefijo pierde las dos cláusulas sobre lo
  que ningún documento puede prometer; el límite queda declarado en dos sitios nombrados.

## Fuera de alcance

- Cambiar lo que hace cualquier script. Este cambio solo toca comentarios, prosa y specs.
- La puerta de commit (`scripts/puerta-commit.sh`, `analiza-invocacion.py`,
  `verifica-puerta.sh`, spec `puerta-de-commit`): es el cambio `la-puerta-es-de-git`.
- El aviso de versión desfasada (`version_kit`, la consulta al remoto, spec `estado-del-kit`
  en su requisito de versión): es el cambio `la-version-no-se-vigila`.
- Los prompts de `agents/`: solo se les quitan frases con fecha o con referencia a versiones
  anteriores. Sus instrucciones no cambian.
- Reescribir los bancos. Siguen igual; solo pierden comentario histórico.

## Criterios de aceptación

- [ ] `grep -c '2026-09-' scripts/*.sh scripts/*.py kit.conf plantillas/* README.md docs/*.md commands/*.md agents/*.md` da 0 en todos. En `openspec/specs/*/spec.md` solo queda fecha en `deteccion-de-duplicados`, en la tabla que sostiene el suelo de 3 líneas.
- [ ] Ningún script de `scripts/` tiene más líneas de comentario que de código: `for f in scripts/*.sh scripts/*.py; do c=$(grep -cE '^\s*#' $f); k=$(grep -vcE '^\s*(#|$)' $f); [ $c -le $k ] || echo $f; done` no imprime nada.
- [ ] `README.md` + `docs/*.md` suman menos de 800 líneas (hoy 1.390): `cat README.md docs/*.md | wc -l`.
- [ ] `docs/PRIMER-CAMBIO.md` no existe, y `docs/FLUJO.md` contiene «## ADDED Requirements», «ACUERDO-ROTO» y «no toca código».
- [ ] La norma de los tres comandos separados está escrita una vez: `grep -rlE 'comandos separados|comando aparte|tres comandos' README.md docs commands scripts plantillas openspec/specs` lista solo `docs/PIEZAS.md`, `scripts/verifica.sh` (el mensaje que imprime) y `scripts/puerta-commit.sh` (el mensaje de bloqueo).
- [ ] Cuándo se invoca el juez está escrito una vez: `grep -rlE 'nadie vaya a leer el acuerdo' README.md docs commands agents plantillas` lista solo `commands/kit-acepta.md`.
- [ ] La salida de `bash scripts/inyecta-contexto.sh </dev/null` sobre este repositorio es byte a byte la misma que antes del cambio.
- [ ] `openspec/config.yaml` contiene las tres reglas de proceso del repositorio (juez, una ronda, bancos).
- [ ] `openspec validate --all` sale limpio.
- [ ] `/kit-verifica` en verde.

## Impact

- `scripts/*.sh`, `scripts/*.py`, `kit.conf`, `plantillas/*`: solo comentarios.
- `README.md`, `docs/FLUJO.md`, `docs/PIEZAS.md`, `docs/INSTALACION.md`: reescritos más cortos. `docs/PRIMER-CAMBIO.md`: borrado.
- `commands/*.md`, `agents/*.md`: frases con historia fuera; las instrucciones quedan.
- `openspec/specs/*/spec.md`: prosa narrativa fuera en todas salvo `puerta-de-commit`; requisitos modificados vía delta en las cuatro capacidades listadas.
- `openspec/config.yaml`: tres reglas de proceso.
- Para quien tiene el kit instalado: nada cambia en lo que hace. Cambia lo que lee.
