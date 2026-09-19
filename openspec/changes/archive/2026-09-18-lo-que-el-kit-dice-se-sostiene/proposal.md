# Lo que el kit dice se sostiene

## Why

Dos frases del kit que la prueba real del 2026-09-18 en AppStarter dejó anotadas, con su texto
literal. Ninguna rompe nada; las dos dicen algo que no es.

**`/kit-revisa` presupone un paso que nadie pidió, y lo remite a un fichero que no está.**
`commands/kit-revisa.md:25`: «Y cuenta las rondas contra el presupuesto que declaraste
(`docs/FLUJO.md`)». La tabla de rondas existe —`docs/FLUJO.md`, «rondas a presupuestar»—, pero
es doc para quien instala el kit: ningún comando manda declarar el presupuesto, así que el
agente llega a esa frase sin haberlo hecho («declaré 2 sobre la marcha»). Y `docs/FLUJO.md` es
una ruta del repo del kit: el comando corre en el proyecto del usuario, donde no existe.

No es la única cita así. Medido con un `grep` de rutas del kit en la prosa de `commands/`,
`agents/` y `skills/`: son **cinco**, todas en comandos —`kit-revisa.md:25` y `:41`
(`agents/aceptacion.md`), `kit-acepta.md:25` y `:63`, `kit-verifica.md:21` (`docs/PIEZAS.md`)—.
La doc sí viaja con el plugin instalado (`docs/` está en su caché); lo que falla es la ruta.
`autocomprueba.sh` ya vigila esto para los scripts —punto 5b— pero solo dentro de los bloques
de código.

**El detector de duplicados cuenta una cosa y dice otra.** `scripts/busca-duplicados.py:127`,
con `--tocados`: «✅ sin lógica repetida en 166 ficheros Swift que toque este cambio». El 166
es lo escaneado; «que toque este cambio» califica a la lógica repetida, pero se lee pegado a
los ficheros. En un cambio que no toca ni un `.swift` la frase afirma que toca 166.

## What Changes

- **Las cinco citas pasan a una ruta que existe donde corre el comando**:
  `${CLAUDE_PLUGIN_ROOT}/docs/…` y `${CLAUDE_PLUGIN_ROOT}/agents/…`. El punto 5 de
  `autocomprueba.sh` ya comprueba que toda ruta escrita así existe, así que quedan vigiladas
  sin tocar el script.
- **`/kit-revisa` pide el presupuesto donde se lanza la ronda**, antes de invocar al revisor,
  remitiendo a la tabla. La frase de después —contar las rondas— pasa a referirse a ese
  presupuesto, no a uno «que declaraste».
- **El mensaje limpio del detector se reordena**: con `--tocados`, «✅ sin lógica repetida que
  toque este cambio (166 ficheros Swift mirados).»; sin él, como hoy. La subcadena «sin lógica
  repetida», que es de lo que dependen `verifica.sh` y el banco, no cambia.

Sin deltas de spec: no cambia ningún comportamiento, y ninguna spec fija estos textos.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

Ninguna: `skip_specs`. `coste-del-juicio` exige que `docs/FLUJO.md` lleve la tabla, y la sigue
llevando.

## Fuera de alcance

- **Ampliar el punto 5b de `autocomprueba.sh` a la prosa.** Es lo que habría cazado las cinco
  citas, y es una comprobación nueva: va aparte y lo decide el owner. Aquí se arreglan las que
  hay y un `grep` deja escrito que no queda ninguna.
- **La tabla de rondas.** No se copia a los comandos ni se toca: vive en `docs/FLUJO.md` y los
  comandos enlazan.
- **`/kit-acepta`**, salvo sus dos citas. Ya manda decidir la ronda «al empezar».
- **El resto de mensajes de `busca-duplicados.py`**, incluido el de los grupos preexistentes.
- **Los hallazgos 4 y 6 del cuaderno de la prueba** —la cola de cada paso en el informe en
  verde, y anotar la firma en `tasks.md`—: no son del kit.

## Criterios de aceptación

- [ ] El `grep` de rutas del kit en la prosa de `commands/`, `agents/` y `skills/` —el de
      `tasks.md` 1.1— no devuelve ninguna sin `${CLAUDE_PLUGIN_ROOT}`. Devolvía cinco.
- [ ] Cargado desde el árbol de trabajo (`claude --plugin-dir .`), el texto de `/kit-revisa`
      que recibe el modelo trae la ruta de `FLUJO.md` expandida a un fichero que existe. Si
      en prosa no se expande, la cita va en un bloque de código, que es donde consta que sí.
- [ ] `commands/kit-revisa.md` pide declarar el presupuesto de rondas **antes** de la
      instrucción de lanzar al revisor, y ya no contiene «que declaraste».
- [ ] Con `--tocados` y sin hallazgos, la salida de `busca-duplicados.py` contiene «sin lógica
      repetida que toque este cambio» y no contiene «ficheros Swift que toque»; sin
      `--tocados` es la de hoy. Lo fija el caso de banco que ya ejercita `--tocados`.
- [ ] `bash scripts/autocomprueba.sh` en verde, `/kit-verifica` en verde, y una ronda de
      `/kit-revisa`.

## Impact

- `commands/kit-revisa.md`, `commands/kit-acepta.md`, `commands/kit-verifica.md`.
- `scripts/busca-duplicados.py` (una frase) y `scripts/verifica-duplicados.sh` (una condición
  más en un caso existente).
- Nada de `openspec/specs/`, ni `docs/`, ni los hooks.
- Visible para el usuario: el texto del informe de `/kit-verifica` en verde cambia de orden.
