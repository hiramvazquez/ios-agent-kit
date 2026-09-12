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

## Qué hacer con el veredicto, antes de tocar nada

Igual que con el revisor: busca **la causa** antes de reaccionar, **prefiere restar** a añadir, y
recuerda que un hallazgo no justifica por sí solo un fichero nuevo. Con el juez hay además una
trampa propia: es fácil «cumplir» un criterio reescribiéndolo. Si el criterio está mal escrito,
se corrige **por escrito y diciéndolo** —eso es renegociar—; lo que no vale es ajustarlo en
silencio para que encaje con lo entregado.

## Anota la ronda, en una línea

Cuando hayas terminado con lo que dijo, añade una línea al final de `tasks.md` —o del
`proposal.md`, si el cambio no lleva lista de tareas—:

```markdown
- Ronda 2 del juez: DEVUELTO · comportamiento: sí
```

**El comportamiento es lo que hicieron tus arreglos**, no lo que pidió el juez: **sí** si alguno
cambió lo que hace el código que se entrega; **no** si solo tocaste pruebas o prosa; **se pidió y
no se hizo** si te pidió cambiar el código y no lo cambiaste, que es un desacuerdo abierto. Es el
único dato que necesita su tope: él empieza en blanco en cada invocación y cuenta las rondas desde
ahí.

**La escribes tú, no el juez.** Editar el acuerdo que juzga es justo lo que su prompt le prohíbe.

Lo que encontró, si quieres guardarlo, va debajo y sin formato. Las pasadas del revisor no hace
falta anotarlas.

## Antes de archivar

Si arreglar lo que el juez señaló **cambió lo que hace el código que se entrega**, ese arreglo no
lo ha visto ningún revisor: el juez pregunta si es lo acordado, no si rompe algo. Pásalo por
`/kit-revisa` antes de archivar. Corregir pruebas o prosa no obliga.

Nada lo comprueba, y es una decisión, no una imposibilidad: el kit no pone un hook en el archivado
mientras nadie haya medido que esta instrucción no basta. Build y tests lo acaban viendo —la puerta
de commit obliga a re-verificar—; la pregunta del revisor, no.

Qué hacer si se agota el presupuesto de rondas con un DEVUELTO que no es del producto está en
`docs/FLUJO.md`, paso 7.
