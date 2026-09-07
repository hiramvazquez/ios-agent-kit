# Las piezas, una por una

Qué hace cada cosa, cuándo se dispara, y **qué NO hace**. Esto último importa tanto como lo
primero: una pieza que promete más de lo que da es peor que no tenerla.

---

## Agentes

### `aceptacion` — ¿es lo acordado?

**Cuándo:** al final de un cambio, antes de archivar. Con `/kit-acepta`.

Lee el `proposal.md`, el delta de spec y el diff completo, y dictamina **criterio por
criterio** con evidencia (`fichero:línea`). Tres cosas que busca a propósito porque si no se
escapan:

1. **El requisito que se evaporó** — nadie lo tocó y nadie lo mencionó. Es el modo de fallo
   más común: el agente empieza por lo difícil, lo resuelve bien, y lo fácil del final se
   queda sin hacer porque «ya parecía terminado». Por eso recorre **la lista**, no el diff:
   el diff enseña lo que se hizo; solo la lista enseña lo que falta.
2. **El requisito a medias** — hecho para el camino feliz y no para el error, o en una de
   las tres pantallas que lo pedían.
3. **Lo que nadie pidió** — código que no responde a ningún criterio. Mira el «Fuera de
   alcance» y busca justo eso.

**No hace:** estilo, arquitectura, ni calidad de código. Para eso está el reviewer. Y no
edita nada — si pudiera tocar el `proposal.md`, el fraude sería trivial.

### `reviewer` — ¿esto rompe algo?

**Cuándo:** antes de commitear código de producto.

Corrección, seguridad, o un requisito explícito del encargo. **Nada más.** Preferencias de
estilo y defensas para casos imposibles se mencionan en una línea como opcionales y no
bloquean: un revisor que reporta preferencias entrena a quien lo lee a ignorarlo.

Método: no lee el diff de arriba abajo —eso encuentra erratas—. Para cada cosa que el
cambio afirma, busca el caso concreto en el que la afirmación es falsa. Y para cada test
nuevo: *¿pasaría igual con el código roto?*

Veredicto `GREEN` / `AMBER` / `RED`. **RED exige reproducción**, o no es RED.

---

## Comandos

| comando | qué hace |
|---|---|
| `/kit-init` | prepara el proyecto: OpenSpec, `kit.conf`, reglas, `.gitignore` |
| `/kit-verifica` | build, tests y duplicados, firmado contra el diff staged |
| `/kit-duplicados` | busca lógica repetida, a demanda — **todos** los grupos, también los preexistentes |
| `/kit-doc` | dónde está la doc de los paquetes de los que dependes (rutas resueltas) |
| `/kit-acepta` | lanza el juez de aceptación |

---

## Scripts

### `verifica.sh` — la firma

Corre lo que diga tu `kit.conf` y escribe `.agent-kit/verificacion.txt` con el `sha256` del
diff staged. Tres modos: verificar y firmar, `--informe` (imprime sin volver a correr) y
`--comprueba` (¿la firma es de este diff?).

**Por qué existe:** sin él, «los tests pasan» es una afirmación del modelo sobre un árbol
que pudo cambiar después de correrlos. Es error de proceso, no mala fe, y es el que menos
rastro deja.

**Códigos de salida:** `0` verde · `N` número de pasos en rojo · `3` **no pude mirar** (no
hay `kit.conf`, o no define `verificaciones()`). El 3 es deliberado: "no pude mirar" no es
lo mismo que "está mal", y confundirlos hace que un gate roto parezca un proyecto roto.

### `busca-duplicados.py` — el mismo cuerpo en dos sitios

Extrae cada `func`/`var` con cuerpo, lo normaliza (fuera comentarios y espacios) y agrupa
por huella. Dos cuerpos idénticos en **ficheros distintos** son un duplicado; en el mismo
fichero, no (sobrecargas legítimas). Ignora cuerpos de menos de 3 líneas o 60 caracteres
normalizados: por debajo de eso, coincidir es normal.

Aparte, agrupa las `extension` del **mismo tipo** declaradas en 3+ ficheros — que es la
forma que toma el problema **antes** de que los cuerpos sean idénticos.

**Por qué existe:** ningún linter lo ve, porque cada copia es correcta por separado. Y
ninguna review lo caza, porque el revisor mira **un** diff y las copias nacieron en semanas
distintas. El caso que lo motivó: tres `extension Date` en tres view models.

**No hace:** detección semántica. Dos funciones que hacen lo mismo escritas distinto no se
parecen para él.

**Y mide ESTRUCTURA, no contenido** — esto hay que saberlo antes de escribir un criterio de
aceptación sobre él. Sustituir un literal por una constante (`"Sin conexión"` →
`ErrorCopy.Offline.title`) **no cambia la huella**: los dos cuerpos siguen siendo el mismo
`switch`. Un criterio del tipo «el informe dejará de listar X» tras extraer constantes es
inalcanzable por construcción, y se escribió uno así en el estreno del kit. Solo desaparece
del informe lo que deja de existir como cuerpo repetido.

### `inyecta-contexto.sh` — contra la deriva

**Cuándo:** en cada turno (`UserPromptSubmit`) y tras cada compactación.

Inyecta tres cosas y ninguna más: las reglas que ningún linter puede comprobar, el cambio
OpenSpec activo con sus tareas pendientes y su «fuera de alcance», y si la firma de
verificación corresponde al árbol actual.

**Por qué así:** contra la deriva no sirve obligar a releer una skill — el modelo cree que
se acuerda y no relee. Sirve que el texto esté delante **otra vez**, y que sea **corto**: un
digest que se lee, no un documento que se ignora.

### `puerta-commit.sh` — el único que bloquea

**Cuándo:** `PreToolUse` sobre Bash. Si el comando contiene `git commit`, exige firma válida.

`PreToolUse` es el único evento de Claude Code capaz de bloquear. Por eso es el único hook
que bloquea aquí: no por diseño elegante, por lo que la herramienta permite.

**Límite declarado, y prefiero decirlo yo:** frena el **olvido**, no a quien se lo quiera
saltar. Con `--no-verify`, desde otra terminal, o invocando git de otra forma, se rodea. Eso
no se puede cerrar desde dentro de la misma máquina, y fingir lo contrario es peor que no
tenerlo.

---

## Skill

### `swift-swiftui`

Las reglas de [SwiftAgents](https://github.com/twostraws/SwiftAgents) de Paul Hudson,
**con las que exigen iOS 26 marcadas aparte** — el original apunta a 26+, y copiarlo tal cual
en un proyecto que despliega en 17 empuja al agente hacia APIs que no compilan.

Es una **barandilla para el código que se escriba a partir de ahora**, no una lista de deuda:
medido sobre los 88 ficheros Swift del proyecto donde se probó, cero infracciones. Eso no
fue porque el modelo se acordara — fue porque el compilador, SwiftLint y el linter de
arquitectura no le dejaron pasar. **La regla que se cumple sola es la que está mecanizada.**

---

## Coste

`claude plugin details ios-agent-kit`:

| | |
|---|---|
| Siempre activo | **~469 tokens** por sesión |
| `aceptacion` al invocarlo | ~1,6k |
| `reviewer` al invocarlo | ~900 |
| Los `/kit-*` al invocarlos | ~260–870 cada uno |
| Los tres hooks | 0 — corren fuera del contexto del modelo |
