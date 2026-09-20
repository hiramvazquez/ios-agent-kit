# Las piezas, una por una

Qué hace cada cosa, cuándo se dispara, y **qué no hace**. Esto último importa tanto como lo
primero: una pieza que promete más de lo que da es peor que no tenerla.

## Agentes

### `aceptacion` — ¿es lo acordado?

**Cuándo:** al final de un cambio, con `/kit-acepta`. No es obligatorio; cuándo merece pagarlo
lo dice el propio comando.

Lee el `proposal.md`, el delta de spec y lo entregado, y dictamina **criterio por criterio**
con evidencia (`fichero:línea`). Tres cosas que busca a propósito porque si no se escapan: el
requisito que se evaporó (recorre **la lista**, no el diff), el requisito a medias, y lo que
nadie pidió. Tiene un tope: dos rondas seguidas cuyos arreglos no cambian lo que el código
hace, y para, porque en prosa cada arreglo reescribe la norma y eso no converge solo.

**No hace:** estilo, arquitectura, ni calidad de código. Para eso está el reviewer. Y no
edita nada: si pudiera tocar el `proposal.md`, el fraude sería trivial.

### `reviewer` — ¿esto rompe algo?

**Cuándo:** al cerrar cada tarea, con `/kit-revisa`, y siempre antes de archivar.

Corrección, seguridad, o un requisito explícito del encargo. **Nada más.** Preferencias de
estilo y defensas para casos imposibles se mencionan en una línea como opcionales y no
bloquean: un revisor que reporta preferencias entrena a quien lo lee a ignorarlo.

Método: no lee el diff de arriba abajo, que solo encuentra erratas. Para cada cosa que el
cambio afirma, busca el caso concreto en el que la afirmación es falsa. Y para cada test
nuevo: *¿pasaría igual con el código roto?*

Veredicto `GREEN` / `AMBER` / `RED`. **RED exige reproducción**, o no es RED.

## Comandos

| comando | qué hace |
|---|---|
| `/kit-init` | prepara el proyecto: OpenSpec, `kit.conf`, reglas, `.gitignore` |
| `/kit-verifica` | build, tests y duplicados, firmado contra el árbol que se verificó, con el toolchain que lo corrió y los límites que declare el proyecto |
| `/kit-duplicados` | busca lógica repetida, a demanda — **todos** los grupos, también los preexistentes |
| `/kit-doc` | dónde está la doc de los paquetes de los que dependes (rutas resueltas) |
| `/kit-revisa` | lanza el revisor sobre la **rodaja** pendiente, no sobre el cambio entero |
| `/kit-acepta` | lanza el juez de aceptación, y dice cuándo merece la pena |
| `/kit-estado` | cómo estamos: lo que queda sin guardar, los cambios activos, la firma, los duplicados y la versión del kit. Al instante y sin compilar |

## Scripts

### `verifica.sh` — la firma

Corre lo que diga tu `kit.conf` y escribe `.agent-kit/verificacion.txt` con el `sha256` de una
**foto del árbol de trabajo**, la que hace git con `write-tree` sobre un índice propio. Así
entra lo que git sabe y un script no: submódulos, enlaces simbólicos, permisos y cualquier
nombre de fichero. Fuera, `openspec/` y `.agent-kit/`. El índice del caché vive en
`~/.cache/ios-agent-kit/`, fuera de tu repositorio, y cuesta unas décimas de segundo por foto.
Si el árbol no se puede fotografiar —un fichero sin permiso de lectura, un filtro de
`.gitattributes` sin instalar— **no se firma nada** y la verificación sale con «no pude mirar». Tres modos: verificar y
firmar, `--informe` (imprime sin volver a correr) y `--comprueba` (¿la firma es de este árbol,
de una verificación verde, y el índice no lleva otra cosa?).

**La firma dice su alcance.** La cabecera lleva `toolchain:` —el compilador del PATH, el Xcode
seleccionado, y un aviso si el del PATH no es el de Xcode— y `limites:`, según si tu
`kit.conf` define `LIMITES`. Los límites salen en el informe y en `/kit-estado`; el toolchain
sale además en `--comprueba` y en el digest de cada turno: «verificado» significa «esto pasó
aquí», no «esto pasa».

**Se firma el árbol, y el índice se comprueba aparte.** Son dos preguntas distintas: «¿es
este el árbol que se probó?» la responde el sha; «¿lleva el índice algo que no es ese árbol?»
la responde una lista de rutas —las stageadas cuyo contenido no es el del árbol—. Las dos
hacen falta: sin la primera, editar después de firmar pasa desapercibido; sin la segunda,
stagear algo y devolver el fichero a su contenido anterior deja la huella igual mientras
`git commit` a secas se lleva el índice.

**Y al firmar instala la puerta de commit** (abajo), para que la firma se exija de verdad.

**La norma que hay que saberse:** lo que invalida la firma es tocar el árbol —editar, crear o
borrar—, no stagear.
Stagear lo que ya se verificó no la invalida —acercar el índice al árbol solo puede hacer que
el commit lleve **más** de lo probado—, así que hacerle caso al aviso de árbol sucio ya no
cuesta otra verificación, y `git commit -am` pasa mientras no hayas editado nada después de
firmar. Lo que sí bloquea: tocar el árbol tras firmar —crear un fichero nuevo incluido, que
antes se colaba— y tener stageado un contenido distinto del árbol. Esto último el informe lo avisa al firmar, como índice divergente, y la puerta lo
rechaza nombrando las rutas. Lo que queda abierto, y el informe avisa como árbol sucio, es lo
contrario: commitear **menos** de lo verificado.

**`openspec/` queda fuera de la huella**, porque es el acuerdo y no lo que se compila, y el
flujo escribe ahí justo después de verificar: marcar la última tarea, anotar la ronda,
archivar. Nada de eso invalida la firma, así que se commitea todo junto sin volver a
verificar. La firma sigue siendo del diff contra `HEAD`, así que deja de valer cuando un
commit se lleva el código firmado: después, un commit que solo toque `openspec/` pide otra
verificación, como antes.
**Límite declarado:** lo que vive en `openspec/` no queda firmado; si tu `kit.conf` verifica
algo de ahí —un `openspec validate`—, un cambio posterior en ese directorio no lo invalida.

**Límite declarado:** `verifica.sh` **ejecuta** tu `kit.conf` (lo carga con `.`). Verificar
es correr código del repositorio en el que estás; sobre un repositorio clonado de fuera,
`kit.conf` es código que no has leído.

**Códigos de salida:** `0` verde · `1` hay pasos en rojo, sea cual sea cuántos · `3` **no
pude mirar** (no hay `kit.conf`, o no define `verificaciones()`). Confundir los dos últimos
hace que un gate roto parezca un proyecto roto. El recuento de pasos vive en el informe y en
la línea `resultado:` de la firma.

### La puerta de commit — un hook de git

**Cuándo:** en cada `git commit` del repositorio, lo lance quien lo lance. Es un hook
`pre-commit` de git, no un hook de Claude Code: lo escribe `verifica.sh` cada vez que firma
—también cuando sale en rojo—, en `.git/hooks/pre-commit`, con las mismas definiciones de
huella y de divergencia que usa la firma. Comprueba lo que comprueba `--comprueba`: firma del
árbol que se va a commitear, resultado verde, y un índice que no lleve otra cosa. Si no, el
commit no se crea y el mensaje dice qué hacer, nombrando las rutas cuando el problema es el
índice.

Por eso no importa desde dónde ni cómo se escriba el comando —`git -C`, un `cd ~/…`, un
`bash -c`, otra terminal—: git lo ejecuta en el repositorio del commit y no hay nada que
adivinar.

**Si tu repositorio ya tiene un `pre-commit`** que no es del kit, o usa `core.hooksPath`, la
verificación no lo toca: deja el hook del kit en `.agent-kit/pre-commit` y el informe dice la
línea que hay que añadir al tuyo (`bash .agent-kit/pre-commit`). `/kit-estado` dice en qué
situación está.

**Si el repositorio deja de tener `kit.conf`, el hook se abre:** ya no usa el kit, y un hook
que sobrevive a desinstalarlo no puede convertirse en un muro. Para retirarlo del todo, borra
`.git/hooks/pre-commit` y `.agent-kit/`.

**Límite declarado:** frena el **olvido**, no a quien se lo quiera saltar. `--no-verify`, un
git que no lea los hooks del repositorio, y los commits que git crea sin pasar por
`pre-commit` —merge, revert, cherry-pick, rebase— se la saltan, y eso no se puede cerrar desde
dentro de la misma máquina.

### `inyecta-contexto.sh` — contra la deriva

**Cuándo:** en cada turno (`UserPromptSubmit`) y tras cada compactación.

**Son los dos únicos hooks de Claude Code del kit**, y los dos llaman a este script. Cada uno
existe porque resuelve un fallo observado, no por simetría. Un tercero tiene que traer escrito
el fallo que lo motiva.

Inyecta cinco cosas y ninguna más: de qué repositorio habla —el plugin se instala para el
usuario, no para un proyecto, así que no es un dato gratis—, las reglas que ningún linter
puede comprobar, el cambio OpenSpec activo con sus tareas pendientes y su «fuera de alcance»,
qué dependencias traen reglas propias, y si la firma de verificación corresponde al árbol
actual. La de las dependencias solo aparece si las hay.

**Con varios cambios activos no afirma el acuerdo de ninguno:** los nombra con su recuento de
tareas y dice que el acuerdo de la sesión es el del cambio en el que se trabaja. No recibe nada
que le diga cuál es, y las tareas o el «fuera de alcance» de otro cambio, puestos delante en
cada turno, se leen como propios.

**Por qué así:** contra la deriva no sirve obligar a releer una skill: el modelo cree que se
acuerda y no relee. Sirve que el texto esté delante **otra vez**, y que sea **corto**.

**Las dependencias que anuncia son las de tu repositorio**, no las de la máquina. Se acotan
por el nombre de la carpeta del repo contra el `<Proyecto>-<hash>` de DerivedData. Es una
heurística con un límite que no es seguro: si tu `.xcodeproj` se llama distinto de la carpeta
que lo contiene, el hook calla en vez de anunciarte las de otro; pero un proyecto que se llame
como el tuyo más un guion (`spm` y `spm-pro`) todavía se cuela. La lista completa vive junto a
la función, en `scripts/lib-kit.sh`.

**Lo que cuesta:** el recorrido que busca las dependencias se hace una vez al día y tarda una
fracción de segundo; el resto de turnos leen el caché, que vive en `~/.cache/ios-agent-kit`,
fuera de tu repositorio.

### `rodaja.sh` — qué queda por revisar

Guarda dónde acabó la última revisión —un objeto de `git stash create`, sin tocar índice ni
working tree— y enseña lo que ha cambiado desde ahí **en el cambio que se revisa**, con sus
tareas cerradas desde entonces. El cambio se le pasa por su ruta (`rodaja.sh
openspec/changes/<nombre>`); sin ruta usa el único activo, y con varios los nombra y para.

La rodaja no empieza antes del principio de ese cambio —una marca más vieja no se usa— y no
vuelca `openspec/changes/`, que es planificación. El principio se conoce cuando la propuesta ya
está commiteada; mientras no lo esté, la rodaja va desde la marca. Con `--entregado <cambio>` da el cambio entero,
planificación y ficheros nuevos sin trackear incluidos, que es lo que necesita el juez:
`git diff main...HEAD` está vacío cuando se le invoca, porque el commit es posterior al juicio.

**Límites declarados:** un fichero sin trackear aparece entero en cada rodaja hasta que se
stagee; se repite trabajo, no se pierde. Y lo commiteado antes de que el cambio empezara no
entra en su rodaja, lo haya revisado alguien o no.

### `busca-duplicados.py` — el mismo cuerpo en dos sitios

Extrae cada `func`/`var` con cuerpo, lo normaliza (fuera comentarios y espacios) y agrupa
por huella. Dos cuerpos idénticos en **ficheros distintos** son un duplicado; en el mismo
fichero, no (sobrecargas legítimas). Un fichero real cuenta una vez aunque se llegue a él por
dos rutas: un symlink no es una copia. Ignora cuerpos de menos de 3 líneas o 60 caracteres
normalizados; por debajo de eso, coincidir es normal. Aparte, agrupa las `extension` del mismo
tipo declaradas en 3+ ficheros, que es la forma que toma el problema antes de que los cuerpos
sean idénticos.

**No hace:** detección semántica. Dos funciones que hacen lo mismo escritas distinto no se
parecen para él.

**Mide el texto del cuerpo**, y hay que saberlo antes de escribir un criterio de aceptación
sobre él: si extraes una constante en las dos copias, las dos cambian igual, siguen siendo
idénticas entre sí, y el informe las sigue listando. Del informe solo desaparece lo que deja
de existir como cuerpo repetido.

### `doc-paquetes.sh` — dónde está la doc de tus dependencias

Un SPM propio bien documentado es invisible desde el proyecto que lo consume: sus fuentes
acaban en `.build/checkouts/` o en `DerivedData/…/SourcePackages/checkouts/`, rutas que git
ignora. Esto imprime las rutas resueltas hoy, separando los paquetes que traen `AGENTS.md`
de los que solo tienen doc de usuario. No resume nada: da direcciones, y avisa de que caducan
al subir la versión del paquete. Acota DerivedData con la misma heurística que el hook.

### `estado.sh` — cómo estamos

Junta en una pantalla lo que otras piezas ya deciden: el trabajo sin guardar, los cambios
activos con sus tareas, el veredicto de la firma (el mismo que la puerta), si la puerta está
instalada, los duplicados de todo el proyecto y la versión del kit. Solo lee; sale con 0
aunque algo esté en rojo.

### `autocomprueba.sh` — antes de publicar el kit

Comprueba lo que solo se ve al instalar: que los manifiestos parseen, que `plugin.json` no
declare rutas por defecto, que los hooks apunten a scripts que existen, y que comandos y
agentes invoquen los scripts del kit por la raíz del plugin. Es para quien mejora el kit, no
para quien lo usa.

## Skill

### `swift-swiftui`

Las reglas de [SwiftAgents](https://github.com/twostraws/SwiftAgents) de Paul Hudson,
**con las que exigen iOS 26 marcadas aparte**: el original apunta a 26+, y copiarlo tal cual
en un proyecto que despliega en 17 empuja al agente hacia APIs que no compilan. Es una
barandilla para el código que se escriba a partir de ahora, no una lista de deuda. **La regla
que se cumple sola es la que está mecanizada**: el compilador, SwiftLint y el linter de
arquitectura hacen más que cualquier skill.

## Coste

**Lo que cuesta tener el kit puesto** lo da un comando, con la versión que tengas instalada:

```bash
claude plugin details ios-agent-kit
```

Lo que ocupa siempre activo y lo que cuesta cargar cada agente o comando sale de ahí. Lo que
ningún comando dice: el código de los hooks no cuesta nada, porque corre fuera del contexto
del modelo, pero el digest que inyecta uno de ellos entra en cada turno y no se descuenta
hasta compactar. Crece con el acuerdo que describe —el bloque «fuera de alcance», las tareas
pendientes— y ronda el millar de caracteres. Se recuenta así:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/inyecta-contexto.sh" </dev/null \
  | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"]))'
```

**Lo que cuesta una ronda de juicio** es otra cosa: cargar el prompt del juez es barato;
usarlo cuesta **uno o dos órdenes de magnitud más**, porque lo que se paga es la ronda entera
—leer el acuerdo, correr los scripts, medir contra el repositorio y escribir el dictamen—. Y
el tamaño del cambio la mueve mucho menos que el número de rondas: por eso
[FLUJO.md](FLUJO.md#cuántas-rondas-merece-esto) te pide presupuestarlas antes de empezar. No
hay cifra aquí porque la que hubo no se podía recomprobar; mide la tuya en las notificaciones
del sub-agente.
