# El prompt dice menos, y el kit dice lo que cuesta

## Why

De la auditoría del 2026-09-11, tres cosas que se pagan en tokens sin dar nada a cambio:

- **El prompt del juez cuesta ~4,2k tokens cada vez que se invoca** (`claude plugin details
  ios-agent-kit`, medido el 2026-09-11). De su texto, el bloque «Los números del acuerdo» son
  1.835 caracteres —el 18 %— que ninguna cláusula SHALL fija y que dicen en párrafos lo que cabe
  en cuatro líneas. «Entrada» es otro 23 %, con la historia de por qué se escribió cada aviso.
- **`/kit-revisa` paga el diff de la rodaja dos veces.** El comando manda ejecutar `rodaja.sh`
  en la conversación principal —donde el diff se queda para siempre— y después el revisor lo
  ejecuta otra vez dentro de su propio contexto, que es el único sitio donde hace falta.
- **La documentación afirma en cuatro sitios que los hooks no cuestan tokens**, y es falso para
  los dos que inyectan contexto. `claude plugin details` dice «harness-only» porque mide lo que
  ocupa *declarar* el hook, no lo que su salida mete en el contexto del modelo. Medido: el
  digest son ~720 caracteres y entra **una vez por turno**; las copias anteriores no desaparecen
  hasta que se compacta.

## What Changes

- **`agents/aceptacion.md`**: el bloque de los censos se queda con la regla y suelta la historia;
  «Entrada» conserva literal lo que las specs exigen —la raíz del plugin, la ruta literal en cada
  comando, que con NADA ENTREGADO se para, y que lo entregado es una ventana temporal y no un
  filtro— y suelta el relato de cómo se descubrió cada una.
- **`commands/kit-revisa.md`**: lanza el sub-agente directamente. La rodaja la ejecuta quien la
  va a leer. Se conserva intacta la regla de cuándo se marca y cuándo no.
- **`README.md`, `docs/FLUJO.md`, `docs/PIEZAS.md`, `docs/INSTALACION.md`**: los tres hooks corren
  fuera del modelo, pero dos devuelven texto que entra en el contexto en cada turno. Se dice, con
  el número medido y su fecha.

## Capabilities

### Modified Capabilities

Ninguna. No cambia ninguna cláusula: `juicio-de-aceptacion` exige que el juez cite los scripts
por la raíz del plugin, que escriba la ruta literal en cada comando y que no juzgue una entrada
vacía —las tres se conservan—, y `coste-del-juicio` fija cuándo se marca una rodaja, que tampoco
se toca. Lo que se va es prosa que no manda nada.

## Impact

- **Se editan:** `agents/aceptacion.md`, `commands/kit-revisa.md`, `README.md`, `docs/FLUJO.md`,
  `docs/PIEZAS.md`, `docs/INSTALACION.md`.
- **Proyectos que usan el kit:** nada que hacer. El prompt viaja en el plugin.

## FUERA de alcance

- **El tope del juez y el registro de rondas.** Son el 22 % del prompt y están fijados por SHALL
  en `juicio-de-aceptacion` (6 cláusulas, 11 escenarios). Tocarlos es una decisión de producto
  —cambia cómo se corta el bucle de rondas— y el owner decidió el 2026-09-11 dejarlos como están.
- **Que el digest no se reinyecte entero cada turno.** Va en su propio cambio: toca el hook, que
  acaba de pasar por revisión en otro.
- **El chequeo de versión de `verifica.sh`** y el recorte de los comentarios-historia de los
  scripts. Son del punto 3 de la auditoría.
- **Publicar.**

## Criterios de aceptación

- [ ] El prompt del juez SHALL bajar de los **9.934 caracteres** que medía el 2026-09-11
      (`wc -c agents/aceptacion.md`), sin perder ninguna regla que una spec exija.

      *El criterio decía primero que bajara el «on-invoke» de `claude plugin details`, y es
      inalcanzable mientras el cambio no se publique: ese comando mide el plugin INSTALADO, no
      el árbol de trabajo. Corregido por escrito el 2026-09-11 para medir lo que sí se puede
      medir hoy; la cifra del comando se anota al publicar, como dice el criterio de abajo.*
- [ ] Al publicar, `claude plugin details ios-agent-kit` SHALL dar un «on-invoke» de `aceptacion`
      menor que los ~4,2k del 2026-09-11, y la cifra nueva SHALL quedar anotada con su fecha.
- [ ] `agents/aceptacion.md` SHALL seguir diciendo, sin perder nada de lo que una spec exige: que
      los scripts se invocan por `${CLAUDE_PLUGIN_ROOT}`, que la ruta del cambio se escribe
      literal en cada comando, que con NADA ENTREGADO se para, y que lo entregado es una ventana
      temporal y no un filtro por rutas.
- [ ] El tope de tres salidas y el recuento de rondas SHALL quedar como están hoy: un `git diff`
      sobre esas dos secciones no devuelve nada.
- [ ] `commands/kit-revisa.md` NO SHALL mandar ejecutar `rodaja.sh` fuera del sub-agente, y SHALL
      seguir diciendo cuándo se marca la rodaja y cuándo no.
- [ ] Ningún documento SHALL decir que los hooks no cuestan tokens sin distinguir los dos que
      inyectan contexto.
- [ ] `/kit-verifica` en verde.

## Presupuesto

Prosa que es lo que se entrega: fila 3 de `docs/FLUJO.md`. **Dos rondas, y preparado para parar.**
Y con lo aprendido en el cambio anterior: aquí no hay código que cambie de comportamiento, así
que una pasada de revisor sobre el recorte basta.
