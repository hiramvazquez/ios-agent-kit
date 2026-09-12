# La historia vive en el log

## Why

Punto 3 de la auditoría del 2026-09-11, que es el que de verdad mueve el tamaño del repo:

- **El 48 % de los scripts de producción es comentario**: 738 de 1.528 líneas. En `lib-kit.sh`
  son 114 de 142 (80 %) y en `kit.conf` 128 de 162 (79 %). Lo que sobra no es la explicación del
  porqué —esa hace falta y se queda— sino **el relato**: la fecha en que se midió, quién lo
  cazó, qué decía la versión anterior de ese mismo comentario, cuántas veces caducó una nota.
  Eso ya está en `git log`, con su diff al lado, que es donde se busca cuando hace falta.
- **El árbol arrastra 7.282 líneas en `openspec/changes/archive/`** —15 cambios, 59 ficheros— que
  **ninguna pieza del kit lee**: ni un script, ni un comando, ni un hook. Git las guarda igual.

Un comentario que cuenta su propia historia envejece como cualquier otra prosa, y este repo ya
tiene el caso escrito: notas que se contradijeron el mismo día en que se escribieron.

## What Changes

- **Los nueve ficheros de producción** —`inyecta-contexto.sh`, `puerta-commit.sh`, `verifica.sh`,
  `rodaja.sh`, `lib-kit.sh`, `doc-paquetes.sh`, `analiza-invocacion.py`, `busca-duplicados.py` y
  `kit.conf`— conservan **qué hace cada cosa y por qué**, y sueltan el relato de cómo se llegó
  ahí.
- **El archivo de cambios sale del árbol.** Se queda `.gitkeep`, para que `openspec archive`
  siga teniendo dónde escribir. Lo archivado se recupera con `git log` y `git show`.

## Lo que NO se toca, porque una cláusula lo exige

Estos comentarios no son historia: son parte del acuerdo, y borrarlos sería romperlo mientras se
«limpia». Van uno a uno para que se puedan comprobar:

| dónde | qué se conserva | cláusula |
|---|---|---|
| `lib-kit.sh` | el límite del acotado por prefijo (`spm` recibe lo de `spm-pro`) | `contexto-inyectado` 6 · `doc-de-paquetes` |
| `lib-kit.sh`, todos | que ningún comentario prometa una garantía de acotado que el código no da | `doc-de-paquetes` |
| `puerta-commit.sh`, `analiza-invocacion.py` | cada salida que deja pasar sin comprobar, diciendo si falla abierto o cerrado y por qué | `puerta-de-commit` 4 |
| `puerta-commit.sh` | la cabecera con las formas de invocación que cubre y las que no | `puerta-de-commit`, escenario del límite que se estrecha |
| `busca-duplicados.py` | los dos suelos, cada uno con su razón, y el de líneas con su medición | `deteccion-de-duplicados` 1 |
| `doc-paquetes.sh` | lo que la cabecera promete cubrir | `doc-de-paquetes` |
| `verifica.sh` | los códigos de salida y qué distingue «no pude mirar» de «está mal» | `verificacion-firmada` |

## Impact

- **Se editan:** los nueve ficheros de arriba. **Se borran:** los 15 cambios archivados.
- **Proyectos que usan el kit:** nada. No cambia ningún comportamiento.

## FUERA de alcance

- **Los bancos de pruebas** (`scripts/verifica-*.sh`, `lib-banco.sh`) y `autocomprueba.sh`.
  Decisión del owner el 2026-09-11, y con motivo: son los que cazaron los cinco hallazgos de ese
  día. Recortarlos sin una medición que demuestre que sobran es quitarse la red.
- **Las specs vivas.** Recortarlas no es limpiar prosa: es retirar cláusulas de un acuerdo, y eso
  pide deltas `REMOVED` y una decisión de producto aparte.
- **`docs/` y `README.md`.** Tienen su propia repetición, y van en otro cambio si se decide.
- **Publicar.**

## Criterios de aceptación

- [ ] Las siete declaraciones de la tabla de arriba SHALL seguir en su fichero, cada una
      comprobada por un `grep` citado en el informe de esta implementación.
- [ ] Los scripts de producción SHALL bajar de las 1.528 líneas del 2026-09-11, y su proporción
      de comentario SHALL bajar del 48 %.
- [ ] `git ls-files openspec/changes/archive` SHALL devolver solo `.gitkeep`.
- [ ] Ningún comentario del kit SHALL prometer una garantía de acotado que el código no da.
- [ ] Los bancos NO SHALL cambiar: `git diff --stat` sobre `scripts/verifica-*.sh`,
      `scripts/lib-banco.sh` y `scripts/autocomprueba.sh` SHALL salir vacío.
- [ ] `/kit-verifica` en verde con `LANG=` y con `LANG=en_US.UTF-8` — los bancos, intactos, son
      la prueba de que el recorte no cambió comportamiento.

## Presupuesto

Prosa y borrado, sin código que cambie: **una pasada de revisor**. El riesgo real no es romper
nada —los bancos lo cazarían— sino borrar una declaración que una cláusula exige, y para eso
están los `grep` del primer criterio.
