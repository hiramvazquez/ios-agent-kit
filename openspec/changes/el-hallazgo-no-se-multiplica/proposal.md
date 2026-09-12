# El hallazgo no se multiplica

## Why

El kit ya tiene una regla contra el crecimiento —«La regla que impide que esto crezca», en el
README—, y habla de **detectores**: no escribir uno por cada cosa que se escapa. Es buena y no se
toca. Pero la deriva del 2026-09-11 no vino por ahí, y el kit no la tenía escrita:

- **Cada arreglo fabricó el hallazgo siguiente.** Firmar el árbol para cerrar `git commit -am`
  abrió el agujero del índice; firmar los dos abrió la colisión por concatenación. **Cinco
  hallazgos en dos rondas sobre un solo cambio, y dos de los cinco salieron del arreglo de la
  ronda anterior** — uno lo escribió el arreglo, el otro era una frase que el arreglo volvió
  falsa. El día entero: cuatro rondas y ocho hallazgos sobre tres cambios.
- **Cuesta.** Entre 130k y 260k tokens por ronda, y esa cifra **no se puede recomprobar**: sale
  de notificaciones de sub-agentes que no viven en el repositorio, igual que las de
  `coste-del-juicio`.
- **En prosa no converge**, porque cada corrección reescribe la norma que se está midiendo. Eso
  ya está en `docs/FLUJO.md` como presupuesto de rondas, y fue lo que cortó el bucle: el owner
  paró y dejó la deuda escrita.
- **Y lo contraintuitivo, que es lo que más falta hace decir:** lo que encogió el repo ese día no
  fue arreglar nada. Fue **borrar** 7.720 líneas que nadie leía y **no tocar** los bancos.

Lo que falta no es una regla nueva: es que la que hay se lea **cuando llega el hallazgo**, que es
el momento en que se decide entre arreglar la causa o añadir un fichero.

## What Changes

- **`scripts/inyecta-contexto.sh`**: las reglas innegociables del digest ganan una cuarta, en una
  línea. Es el único sitio que un agente lee sin falta, en cada turno.
- **`commands/kit-revisa.md` y `commands/kit-acepta.md`**: qué hacer con lo que devuelve el
  veredicto, en cuatro líneas. Es lo que se lee justo al recibirlo.
- **`README.md`**: la sección que ya existe gana el mecanismo observado y sus números. No se
  crea ningún documento: un fichero nuevo sobre no crear ficheros sería el propio error.

## Capabilities

### Modified Capabilities

- `contexto-inyectado`: el digest pasa de tres reglas innegociables a cuatro. Cambia lo que el
  hook emite en cada turno, así que se declara en vez de colarse como «solo prosa».

## Impact

- **Se editan:** `scripts/inyecta-contexto.sh`, `commands/kit-revisa.md`,
  `commands/kit-acepta.md`, `README.md`.
- **Proyectos que usan el kit:** reciben la regla en el digest en cuanto actualicen el plugin.
  No tienen que tocar nada.
- **Coste:** el digest crece **exactamente 89 caracteres** por turno —88 de la regla más el salto
  de línea—, o sea unos 22 tokens. Medido: 1.018 → 1.107 en este repositorio y 803 → 892 en uno
  mínimo. *Aquí ponía «unos 15 tokens», estimado a ojo y corto en un tercio; lo midió el revisor.
  Va corregido y no disimulado porque este es, precisamente, el cambio que nace de una cifra
  publicada que no cuadraba.*

## FUERA de alcance

- **La plantilla `plantillas/openspec-config.yaml.ejemplo`.** Llegaría a cada proyecto en su
  `/opsx:apply`, pero solo tras copiarla a mano en los que ya existen. El owner decidió el
  2026-09-11 dejarlo fuera de este cambio.
- **Crear un documento nuevo.** Ver arriba.
- **Los bancos y las specs vivas**, que siguen sin tocarse desde la auditoría.
- **`docs/FLUJO.md`**, que ya dice lo suyo sobre el presupuesto de rondas y no lo contradice.
- **Publicar.**

## Criterios de aceptación

- [ ] El digest SHALL llevar una cuarta regla innegociable que diga qué hacer con un hallazgo, y
      SHALL caber en una línea: el bloque de reglas no crece más de 100 caracteres.
- [ ] `/kit-revisa` y `/kit-acepta` SHALL decir qué hacer con el veredicto antes de arreglar:
      clasificar la causa, preferir restar, y que un hallazgo no justifica por sí solo un fichero
      nuevo.
- [ ] La sección del `README.md` SHALL seguir diciendo lo que ya decía sobre los detectores —no
      se sustituye— y SHALL añadir el mecanismo del arreglo que fabrica el hallazgo siguiente,
      con la medición del 2026-09-11 y su fecha.
- [ ] NO SHALL crearse ningún fichero nuevo fuera de `openspec/changes/`:
      `git status --porcelain` no muestra ficheros nuevos en `scripts/`, `docs/` ni `commands/`.
- [ ] El banco del hook SHALL fijar la cláusula 7 con **una línea** dentro de un caso que ya
      existe, y `/kit-verifica` SHALL salir en verde con `LANG=` y con `LANG=en_US.UTF-8`.

      *Este criterio decía «el banco SHALL seguir en verde **sin tocarlo**», y el revisor midió
      que con esa condición la cláusula 7 no la fijaba nada: apuntando el banco al hook anterior
      salía 29/29 en verde, así que borrar la línea del digest no habría puesto nada en rojo.
      Una cláusula que nada mide es una promesa vacía. Se renegocia por escrito el 2026-09-11, y
      el canje es explícito: una línea de aserción, no un fichero ni un banco nuevo.*

## Presupuesto

Prosa, y de la que se juzga a sí misma: fila 3 de `docs/FLUJO.md`. **Dos rondas, y preparado para
parar** — con la lección del día ya aprendida: si la segunda ronda solo devuelve redacción, se
para y se archiva con la deuda escrita.
