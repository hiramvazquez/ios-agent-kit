# La doc dice lo que hay

## Why

El 2026-09-11 se contrastó la documentación de la 1.10.0 con el código, y aparecieron tres cosas
que alguien seguiría mal. Las tres son anteriores a esa versión:

- **La instalación a mano de `docs/INSTALACION.md` no funciona.** Su `cp` saca la ruta del plugin
  de `claude plugin details ios-agent-kit | grep -o '/.*ios-agent-kit'`, y ese comando no imprime
  ninguna ruta (comprobado el 2026-09-11): el `grep` sale vacío y el `cp` apunta a
  `/plantillas/kit.conf.ejemplo`. Además, esa vía no copia la plantilla de `openspec/config.yaml`,
  así que quien la siga se queda sin las reglas de criterios y de archivado que sí pone `/kit-init`.
- **Las cifras de tokens de `docs/PIEZAS.md`, del 2026-09-07, ya no valen.** El mismo comando da hoy
  ~650 siempre activos (publicado: ~469), ~4,2k el juez (~1,6k) y ~1,9k el revisor (~900). La frase
  «entre cuarenta y ochenta veces» sale de la cifra vieja, y el mismo número está en el `Purpose` de
  la spec `coste-del-juicio`.
- **La plantilla y el flujo se contradicen.** `plantillas/openspec-config.yaml.ejemplo` manda pasar
  `/kit-acepta` antes de archivar, siempre; la tabla «Cuánto proceso pide cada cambio» de
  `docs/FLUJO.md` dice que en un cambio pequeño de alcance claro el juez solo hace falta si el
  alcance se movió al implementar. La regla de FLUJO salió de medir un cambio real, y el owner
  decidió el 2026-09-11 alinear la plantilla con ella.

## What Changes

- **`docs/INSTALACION.md`, instalación a mano:** las plantillas se copian del clon del marketplace,
  `~/.claude/plugins/marketplaces/hiram-kits/plantillas/`, y se copian las dos.
- **`docs/PIEZAS.md`, «Lo que cuesta tener el kit puesto»:** la tabla medida de nuevo con el mismo
  comando, y la frase del múltiplo recalculada con esa cifra, diciendo la fecha de cada una.
- **`openspec/specs/coste-del-juicio/spec.md`, solo su `Purpose`:** sin cifras. Un número en un
  texto que se archiva envejece solo, y este ya lo hizo; las cifras viven en `docs/PIEZAS.md`,
  fechadas.
- **`plantillas/openspec-config.yaml.ejemplo`, la regla de archivar:** `/kit-acepta` antes de
  archivar, salvo en un cambio pequeño de alcance claro cuyo alcance no se movió, como dice FLUJO.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

Ninguna. Ningún requisito cambia: el cambio corrige documentación para que diga lo que el código y
el flujo ya hacen, y por eso declara `skip_specs`. FLUJO pide delta porque describe cambios de
comportamiento; aquí no hay ninguno, y escribir uno para cumplir sería inventarlo. El `Purpose` de
`coste-del-juicio` no es un requisito, y se corrige en su sitio.

## Impact

- **Se editan:** `docs/INSTALACION.md`, `docs/PIEZAS.md`, `plantillas/openspec-config.yaml.ejemplo`
  y el `Purpose` de `openspec/specs/coste-del-juicio/spec.md`.
- **Proyectos que ya usan el kit:** su `openspec/config.yaml` es una copia y no cambia solo.

## FUERA de alcance

- **Los desfases cosméticos** que salieron en la misma revisión: «los seis pasos» y la lista de
  comandos sin `/kit-revisa` de FLUJO, dónde va la línea de ronda cuando no hay `tasks.md`, lo que
  el README no dice de `.claude/`, y cómo nombra `docs/PRIMER-CAMBIO.md` al revisor.
- **Las cifras de coste de las rondas.** No se pueden recomprobar, y `docs/PIEZAS.md` ya lo dice.
- **`AppStarter`:** su `openspec/config.yaml` todavía lleva la regla vieja de archivar, y su
  `AGENTS.md` describe el bucle sin `/kit-revisa`. Es otro repositorio.
- **Publicar.** Versión y push, cuando se decida.

## Criterios de aceptación

- [ ] Los comandos de la instalación a mano de `docs/INSTALACION.md` SHALL funcionar tal como están
      escritos —salvo el que abre el editor—: corridos en un repositorio git temporal, dejan
      `kit.conf` y `openspec/config.yaml` copiados de las plantillas, y ninguno usa
      `claude plugin details`.
- [ ] La tabla de «Lo que cuesta tener el kit puesto» SHALL coincidir con
      `claude plugin details ios-agent-kit` el día en que se mida, e ir fechada con ese día.
- [ ] La frase que compara cargar el juez con usarlo SHALL salir de la cifra de esa tabla y de las
      de las rondas, y decir la fecha de cada una.
- [ ] El `Purpose` de `openspec/specs/coste-del-juicio/spec.md` NO SHALL llevar cifras:
      `sed -n '/^## Purpose/,/^## Requirements/p' openspec/specs/coste-del-juicio/spec.md | grep -nE '[0-9]|cuarenta|ochenta'`
      no devuelve nada.
- [ ] `plantillas/openspec-config.yaml.ejemplo` SHALL decir lo mismo que la tabla «Cuánto proceso pide
      cada cambio» de `docs/FLUJO.md` sobre cuándo hace falta `/kit-acepta` antes de archivar, y SHALL
      seguir siendo YAML válido.
- [ ] `/kit-verifica` en verde con `LANG=` y con `LANG=en_US.UTF-8`.

## Presupuesto

Es un cambio pequeño de alcance claro, así que va por esa fila de `docs/FLUJO.md`: sin `tasks.md`,
**una pasada de revisor**, y juez solo si el alcance se mueve al implementar.

---

## Enmienda del 2026-09-12: las cifras no se re-miden, se quitan

Esta propuesta se escribió el 2026-09-11 y no se implementó ese día. Entre medias, la auditoría
del kit cambió tres de las cosas que aquí se dan por ciertas, así que el acuerdo se enmienda por
escrito antes de tocar nada — no se reescribe lo de arriba para que encaje.

**Qué ha caducado de lo que dice esta propuesta**, medido el 2026-09-12:

| lo que dice arriba | lo que hay hoy |
|---|---|
| «~4,2k el juez» | **~3,7k** — el cambio `el-prompt-dice-menos` le recortó el prompt |
| `/kit-revisa` ~860 (implícito en la tabla vieja) | **~1,4k** — le añadió una sección el cambio `el-hallazgo-no-se-multiplica` |
| «la tabla de `PIEZAS.md`, medida de nuevo» | esa sección **ya se editó** el 2026-09-11: la fila de los hooks y el bloque del digest son nuevos |

**Y el dato que decide la enmienda:** esa tabla de tokens ha caducado **tres veces en cinco
días**, y la última vez en **menos de un día** — la anotación que este mismo repositorio hizo el
2026-09-11 diciendo que `/kit-revisa` costaba ~1,1k ya era falsa al día siguiente. Volver a
medirla es comprarse la cuarta caducidad.

**Quién lo decide.** El punto 2 lo escribió el owner el 2026-09-11. Esta sustitución **se le
propuso por escrito en sesión el 2026-09-12** —con el dato de las tres caducidades— y **dio el
visto bueno** antes de que se tocara nada. Va dicho porque el resto de esta enmienda la redacta
quien implementa, y un cambio en el acuerdo de otro no se da por cerrado solo.

### Lo que cambia del acuerdo

- **El punto 2 del `What Changes` se sustituye.** Donde decía «la tabla medida de nuevo con el
  mismo comando», ahora dice: **se quita la tabla de tokens por pieza** y queda el comando que
  la produce. No es un recorte de estilo: esa misma sección ya manda correr el comando dos
  líneas más arriba, así que la tabla se contradecía con su propio texto. Se conserva el bloque
  del digest, porque ese número **no lo da ningún comando del CLI** y por eso sí hay que
  escribirlo, fechado y con su forma de recontarlo.
- **Se añade a ese punto la frase del múltiplo** de «Lo que cuesta una ronda de juicio», que hoy
  dice «entre cuarenta y ochenta veces» a partir de la cifra vieja. No se recalcula: se quita el
  cociente. Su numerador lo da un comando y su denominador **no se puede recomprobar**, así que
  cualquier múltiplo exacto nace caducado.
- **Los puntos 1, 3 y 4 siguen vigentes tal cual**, y los tres están comprobados hoy: el `cp` de
  `INSTALACION.md` sigue sacando la ruta de un comando que no imprime ninguna; el `Purpose` de
  `coste-del-juicio` conserva las cifras; y la plantilla sigue exigiendo `/kit-acepta` siempre
  mientras `FLUJO.md` dice que en un cambio pequeño de alcance claro no hace falta.

### Criterios que sustituyen a los de arriba

- [ ] `docs/PIEZAS.md` NO SHALL llevar una tabla de tokens por pieza; SHALL llevar el comando que
      los da. Comprobable: `grep -c 'tokens\*\* por sesión' docs/PIEZAS.md` devuelve 0.
- [ ] La frase que compara cargar el juez con usarlo NO SHALL llevar un **cociente exacto** —ni
      un número ni un rango cerrado como «entre cuarenta y ochenta veces»—, y SHALL decir por
      qué no lo lleva. SÍ PUEDE dar el orden de magnitud, que es lo que aguanta el margen de los
      dos factores.

      *Escrito así tras la revisión del 2026-09-12, que preguntó cuál de las dos lecturas vale:
      «uno o dos órdenes de magnitud» es un múltiplo en palabras, así que por la letra del
      criterio anterior no cumplía. Se elige la intención —ningún cociente que caduque— y se
      escribe, en vez de dejar que cada lector decida. Lo respalda su medición: hoy son ~18× a
      ~34×, y el «cuarenta y ochenta» publicado no estaba viejo, estaba **falso**.*
- [ ] El bloque del digest SHALL seguir donde está, con su fecha y su comando.

- [ ] Ningún documento SHALL remitir a la tabla que se quita. `README.md` y `docs/INSTALACION.md`
      SHALL apuntar a lo que `docs/PIEZAS.md` sí escribe —el coste del digest y el de una ronda—
      y no a una «medición fechada» de lo que ahora da el comando.

      *`README.md` entra aquí como quinto fichero del Impact, y va escrito en vez de colarse:
      quitar la tabla dejó dos punteros prometiéndola, que es el defecto que da nombre a este
      cambio cometido al arreglarlo. Lo encontró la revisión del 2026-09-12.*
- [ ] La excepción de la plantilla SHALL llevar el umbral que da FLUJO —menos de unos 5 ficheros
      y sin tocar varias capas—, porque el proyecto que copia la plantilla **no tiene** ese
      documento y para él ese texto es todo lo que hay.

Los criterios 1, 4, 5 y 6 de arriba —instalación a mano, `Purpose` sin cifras, plantilla alineada
con FLUJO, y `/kit-verifica` en los dos idiomas— **siguen tal cual**.

### El presupuesto no cambia, y esto es una decisión

La enmienda **no amplía el alcance**: son los mismos cuatro ficheros, y la solución del punto 2
encoge en vez de crecer. Por eso sigue siendo **una pasada de revisor** y no dispara el «juez
siempre» que `docs/FLUJO.md` reserva para el alcance que *crece* a mitad. Va escrito porque es
justo la clase de decisión que, tomada en silencio, se parece demasiado a saltarse el proceso.
