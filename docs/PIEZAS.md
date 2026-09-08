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
| `/kit-revisa` | lanza el revisor sobre la **rodaja** pendiente, no sobre el cambio entero |
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

**Límite declarado:** `verifica.sh` **ejecuta** tu `kit.conf` (lo carga con `.`), porque esa
es la forma de que cada proyecto declare sus propios pasos. Verificar es, por tanto, correr
código del repositorio en el que estás. En los tuyos da igual; el día que corras
`/kit-verifica` sobre un repositorio clonado de fuera, `kit.conf` es código que no has leído.
Trátalo como tal.

**Códigos de salida:** `0` verde · `1` hay pasos en rojo · `3` **no pude mirar** (no hay
`kit.conf`, o no define `verificaciones()`). El 3 es deliberado: "no pude mirar" no es lo
mismo que "está mal", y confundirlos hace que un gate roto parezca un proyecto roto.

El rojo es `1` sea cual sea el número de pasos fallidos, y eso también es deliberado: aquí
ponía que el código de salida era **el número de pasos en rojo**, y entonces exactamente
tres fallos eran indistinguibles de «no pude mirar». El recuento vive en el informe y en la
línea `resultado:` de la firma, que es donde se lee.

### `busca-duplicados.py` — el mismo cuerpo en dos sitios

Extrae cada `func`/`var` con cuerpo, lo normaliza (fuera comentarios y espacios) y agrupa
por huella. Dos cuerpos idénticos en **ficheros distintos** son un duplicado; en el mismo
fichero, no (sobrecargas legítimas). Y un fichero real cuenta **una vez**, aunque se llegue
a él por dos rutas: seguir un symlink y leerlo dos veces producía 21 de los 28 grupos del
informe de `spm-pro`.

Ignora cuerpos de menos de 3 líneas o 60 caracteres normalizados: por debajo de eso,
coincidir es normal. Ese 3 sobrevivió a un intento de subirlo: con 4 se quitaba un
falso positivo —dos dobles de test de `AppStarter`— y se perdían `pascalCase()` y
`displayPath()`, copiados de verdad entre un target y un plugin; con 5 se perdían además
`loadingView()`, `errorView()`, `emptyView()` y un `load()` copiado entre dos snippets. «N líneas» cuenta saltos de línea del cuerpo,
que son N−1 sentencias. Lo fijan tres casos del banco, y el ruido
conocido que queda se asume.

Aparte, agrupa las `extension` del **mismo tipo** declaradas en 3+ ficheros — que es la
forma que toma el problema **antes** de que los cuerpos sean idénticos.

**Por qué existe:** ningún linter lo ve, porque cada copia es correcta por separado. Y
ninguna review lo caza, porque el revisor mira **un** diff y las copias nacieron en semanas
distintas. El caso que lo motivó: tres `extension Date` en tres view models.

**No hace:** detección semántica. Dos funciones que hacen lo mismo escritas distinto no se
parecen para él.

**Mide el TEXTO del cuerpo**, y hay que saberlo antes de escribir un criterio de aceptación
sobre él. La huella es el `sha1` del cuerpo con los comentarios y los espacios fuera: si
cambia un token, cambia la huella. Comprobado sobre el mismo `switch`:

| cuerpo | huella |
|---|---|
| con `"Sin conexión"` | `4c99aae25e` |
| con `ErrorCopy.Offline.title` | `b2e55c1316` |

Las dos salen de este cuerpo, cambiando solo el literal de la primera rama, y se recalculan
con la misma fórmula que usa el detector — `sha1` del cuerpo sin comentarios y con los
espacios colapsados, diez caracteres:

```swift
switch error {
case .offline: return "Sin conexión"
case .server: return "Error del servidor"
default: return "Algo ha ido mal"
}
```

Lo que **no** cambia es el GRUPO, que es lo que se reporta: si extraes la constante en las
dos copias, las dos cambian igual, siguen siendo idénticas entre sí, y el informe las sigue
listando. Por eso un criterio del tipo «el informe dejará de listar X» tras extraer
constantes es inalcanzable por construcción —se escribió uno así en el estreno del kit—: del
informe solo desaparece lo que deja de existir como cuerpo repetido.

Aquí ponía que sustituir un literal por una constante «no cambia la huella». La conclusión
que sacaba era correcta y el mecanismo que enseñaba no, y alguien iba a razonar desde el
mecanismo.

### `inyecta-contexto.sh` — contra la deriva

**Cuándo:** en cada turno (`UserPromptSubmit`) y tras cada compactación.

Inyecta tres cosas y ninguna más: las reglas que ningún linter puede comprobar, el cambio
OpenSpec activo con sus tareas pendientes y su «fuera de alcance», y si la firma de
verificación corresponde al árbol actual.

**Por qué así:** contra la deriva no sirve obligar a releer una skill — el modelo cree que
se acuerda y no relee. Sirve que el texto esté delante **otra vez**, y que sea **corto**: un
digest que se lee, no un documento que se ignora.

**Lo que cuesta, medido el 2026-09-08** (`/usr/bin/time` sobre tres corridas, DerivedData de
2,6 GB): el recorrido que busca las dependencias tarda **0,39 s en frío y 0,08 s en caliente**,
y solo se hace **una vez al día** — el resto de turnos leen el caché. Corre antes de que salga
tu prompt, así que ese cuarto de segundo lo pagas tú una vez cada mañana. Se declara porque
el coste de la puerta sí estaba medido y el de este hook no, y un coste que nadie mide acaba
siendo el que sorprende.

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

**Medición del 2026-09-07**, con `claude plugin details ios-agent-kit`. Va fechada a
propósito: es una foto, no una ley, y cambia en cuanto se añade o se recorta una pieza.
Cuando necesites el número de hoy, corre el comando en vez de leer esta tabla.

| | |
|---|---|
| Siempre activo | **~469 tokens** por sesión |
| `aceptacion` al invocarlo | ~1,6k |
| `reviewer` al invocarlo | ~900 |
| Los `/kit-*` al invocarlos | ~260–870 cada uno |
| Los tres hooks | 0 — corren fuera del contexto del modelo |
