---
description: Lanza el juez de aceptación sobre el cambio activo — ¿lo entregado es lo acordado?
---

Lanza el sub-agente `aceptacion` contra el cambio OpenSpec activo.

Su trabajo es una sola pregunta: **¿lo entregado es lo acordado?** Criterio por criterio,
con evidencia (`fichero:línea`), y uno de tres veredictos: ACEPTADO, DEVUELTO o
ACUERDO-ROTO.

No es el reviewer y no lo sustituye: un cambio puede estar impecable —arquitectura, tests,
lint— y no ser lo que se pidió. Eso solo se ve comparando el resultado con el acuerdo, al
final, con la cabeza fresca.

Pásale el cambio: `openspec list` para ver cuál está activo, y su carpeta en
`openspec/changes/<nombre>/`.

## Antes de archivar: ¿ha visto alguien lo que arreglaste?

Si arreglar lo que el juez señaló **movió el comportamiento**, ese código no lo ha visto ningún
revisor: el juez pregunta si es lo acordado, no si rompe algo. Pásalo por `/kit-revisa` antes de archivar.

**Y no lo decidas solo de memoria: normalmente está escrito.** Desde la 1.9.2 cada ronda se
anota con qué pasó con el comportamiento —abajo—, así que la pregunta «¿falta una pasada?» se
responde leyendo el
acuerdo: **si ALGUNA ronda posterior a la última pasada de revisor dice que sí, falta.** Y **si
no hay ninguna pasada anotada, todas las rondas son posteriores** — así que basta con que una
diga «sí».

**Y una ronda SIN etiqueta no dice «no»: cuenta como «sí», o pregunta.** La etiqueta llegó con
la 1.9.2 y la mayoría de los acuerdos archivados no la tiene, así que un cambio que venía en
vuelo, o un autor que anotó la ronda y omitió la línea, te dejan un registro **mudo** — y un
registro mudo leído como «no» archiva a ciegas justo lo que esto viene a impedir. Es el mismo
desempate que ya tienen las dos reglas hermanas, y empuja al mismo lado.

Ese último caso no es raro: hay acuerdos archivados con rondas de juez y ninguna pasada
anotada. Cuántos exactamente **no lo cuentes con un `grep` de cabeceras**: los bloques se han
escrito de varias formas —cabecera `## Del juez`, item numerado `**Del juez…**`, «De la segunda
revisión»— y un patrón que solo conozca una devuelve `0` sobre ficheros que sí los tienen, en
silencio y hacia el lado que archiva. Léelo tú.

«Posterior» se lee por dónde está el bloque en el fichero, no por su cabecera: **una pasada de
revisor y una ronda de juez del mismo día no se pueden ordenar por su contenido**, porque la del
revisor no se numera a propósito. (Dos rondas de juez sí: van numeradas.)

**Por eso, cuando anotes la ronda abajo, escríbela al final de lo que haya** — no agrupada con
las rondas anteriores, aunque quede más ordenado. Agrupar por tipo rompe el orden del que
depende todo esto, y es lo que hacen hoy varios acuerdos archivados.

Fíjate en «alguna», que es la palabra entera. La primera versión de esta regla decía «la
última ronda», y con eso no disparaba nunca: para archivar en regla la última es un ACEPTADO,
un ACEPTADO siempre es «no», y el camino normal —DEVUELTO que mueve código, arreglas, ACEPTADO,
archivas— pasaba limpio por delante. El agujero que esto cierra vive entero en ese camino.

Qué cuenta como mover el comportamiento lo dice la tabla del tope, en la sección «Tope» de
`agents/aceptacion.md`. Este comando no la repite: reenunciarla en otras palabras es como se
ensanchó una vez.

Lo que sí ve ese arreglo, para no inflar el hueco: al cambiar el árbol la firma de
`/kit-verifica` deja de valer, y la puerta de commit obliga a re-verificar **antes de
commitear** — así que build y tests lo acaban mirando, aunque no necesariamente antes de
archivar. Lo que
no lo mira es la pregunta del revisor, que es la que caza lo que los tests no — en `AppStarter`,
el 2026-09-09, una segunda pasada encontró así un defecto en una spec que al archivarse se
habría fundido en la canónica.

Y si el arreglo que venga después de esa pasada vuelve a mover el comportamiento, toca otra —
lo que acota la serie no es esta regla, es el presupuesto de rondas de `docs/FLUJO.md`. Al
agotarse, decide el owner.

**Límite declarado, y es peor que el de su regla hermana.** Aquella se apoya en
`rodaja.sh --revisada`, que es un script del kit; **el kit no tiene ningún hook que intercepte
el archivado**, así que esto vive entero en este prompt y en `docs/FLUJO.md`. Quien no lo siga
archiva igual y no salta nada.

Y que quede claro por qué no lo hay, porque **no es que no se pueda**: `/opsx:archive` corre el
CLI por la herramienta Bash, y el kit ya intercepta ahí `git commit` con su puerta. Lo que lo
impide es una política escrita: `hooks/hooks.json` dice «tres hooks y ninguno más… si algún día
hay un cuarto, tiene que traer escrito el fallo que lo motiva». Este todavía no lo tiene — el
fallo está observado pero nadie ha medido que la instrucción no baste. El día que se mida, la
puerta cabe.

## Anota la ronda, y di si movió el comportamiento

**Cuando hayas terminado con lo que dijo** —no al volver: hasta que no arreglas, el dato que
falta no existe— escribe en el acuerdo, en `tasks.md` o al final del `proposal.md` si este
cambio no lleva lista de tareas: qué ronda fue, qué veredicto dio, qué encontró, y **qué pasó
con el comportamiento**.

Ese último no es un sí/no. **El eje es lo que tus arreglos HICIERON**, no lo que el juez pidió:
su tope cuenta «rondas cuyos arreglos no cambian lo que ninguna pieza HACE». Escribe cuál de
los tres:

- **sí** — algún arreglo cambió lo que alguna pieza hace, lo pidiera él o no
- **no** — ninguno lo cambió: se corrigió prosa, un comentario, un ejemplo, o una cláusula que
  describía mal lo que ya se hacía
- **no, se pidió y se discrepó** — te pidió mover comportamiento y no lo hiciste. Es un
  desacuerdo abierto y NO es una ronda limpia; dilo como tal

**Y no lo decidas a ojo: la tabla que lo dice está en `agents/aceptacion.md`, sección «Tope».**
Cinco filas, y la que más se falla es que cambiar lo que un prompt o una norma MANDAN hacer sí
cuenta, mientras corregir una cláusula que describía mal lo que ya se hacía no. En la duda,
cuenta como comportamiento — el error caro de ese tope es dispararse pronto.

Cuidado con el sesgo por defecto: la primera vez que se usó este formato, quien lo estrenó
etiquetó «sí» tres de ocho puntos que la tabla da por «no». Si todo se marca «sí», el tope no
se dispara nunca y esto es papeleo.

Con un **ACEPTADO** normalmente no hay nada que arreglar y la ronda es «no». Pero si te dejó
observaciones que **sí** arreglaste y ese arreglo movió el comportamiento, la ronda es «sí» como
cualquier otra: lo que decide es lo que hiciste, no la etiqueta del veredicto.

Y en la ronda donde el juez alcanza su tope **no hay veredicto**: su prompt le manda escribir,
en vez de uno, cuál de sus tres salidas aplica. Anota esa salida en su lugar — es justo la
ronda que más falta hace tener registrada.

No es opcional y es lo que más cuesta acordarse: **el tope cuenta rondas cuyos arreglos no
cambian lo que ninguna pieza hace**, y él no puede saberlo desde dentro de su invocación. Sin ese registro el tope
queda frágil —puede enterarse por lo que le digas en el mensaje, un canal que no queda escrito
ni se puede auditar— y lo que de verdad para el bucle pasa a ser quien mire la factura, que es
justo aquello de lo que el tope existe para no depender. Lo sabes tú, que arreglaste.

**Lo escribes TÚ, no el juez.** Su prompt termina diciendo que editar el acuerdo para que
encaje con lo entregado «es exactamente el fraude que este agente existe para impedir». Darle
permiso de escritura en la carpeta que juzga abriría esa puerta para resolver algo que se
resuelve sin ella.

Por qué hace falta decirlo: el 2026-09-09, en el primer uso del kit fuera de su repositorio, un
el bucle entero de un cambio de `AppStarter` —pasadas de revisor y ronda de juez— no dejó ni
una línea en su acuerdo archivado. Nadie lo pedía. Reproducible sobre cualquier cambio
archivado:

```bash
grep -cE '^## Del |AMBER|ACEPTADO|ronda' openspec/changes/archive/<cambio>/tasks.md
```

Una forma mínima que sirve —el formato no importa, lo que va dentro sí—:

```markdown
## Del juez (DEVUELTO, 2026-09-09) — ronda 2

- [x] N. **Qué señaló**, y qué se hizo.
      Comportamiento: sí | no | no, se pidió y se discrepó.
```

La cabecera dice **del juez** y **ronda N** a propósito: las pasadas del revisor se anotan
aparte y no se numeran como rondas. Si se mezclan, el tope contará pasadas de revisor y se
disparará antes de tiempo — el error que su propio prompt llama el caro.
