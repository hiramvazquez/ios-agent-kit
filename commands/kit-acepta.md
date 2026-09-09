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

Con un **ACEPTADO** no hay nada que arreglar: la ronda es «no», y el bucle termina ahí de todas
formas.

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
      Comportamiento: sí | no, no lo pidió | no, se pidió y se discrepó.
```

La cabecera dice **del juez** y **ronda N** a propósito: las pasadas del revisor se anotan
aparte y no se numeran como rondas. Si se mezclan, el tope contará pasadas de revisor y se
disparará antes de tiempo — el error que su propio prompt llama el caro.
