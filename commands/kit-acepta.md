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
