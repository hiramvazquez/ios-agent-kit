# El flujo completo, de una tarea a un commit

Cómo encaja todo, contado de principio a fin sobre un caso concreto. Si tienes que
explicarle el kit a alguien, este es el documento.

Empezamos con una tarea de Jira, pero lo primero es decir lo que **no** hay: el kit no habla
con Jira. Nadie lee el ticket por ti; el flujo empieza cuando tú lo pegas en la sesión.

## Dónde se trabaja

Todo el flujo ocurre dentro de una sesión de Claude Code, con comandos de barra. La terminal
solo aparece para instalar y actualizar el kit ([INSTALACION.md](INSTALACION.md)). Tú traduces
el ticket, apruebas el acuerdo y decides lo que es decisión de producto; OpenSpec guarda el
acuerdo y lo valida; el agente propone, implementa y verifica; dos jueces preguntan *¿rompe
algo?* y *¿es lo acordado?*; dos hooks recuerdan, y un hook de git bloquea.

## 0. El ticket

```
PROJ-482 — "Al volver de la ficha de producto, el listado se recarga entero
            y se pierde el scroll"
```

Abres Claude Code en la raíz del proyecto y lo pegas.

## 1. Proponer — se acuerda, no se programa

```
/opsx:propose "PROJ-482: al volver de la ficha, el listado no debe recargarse ni perder el scroll"
```

El agente tiene prohibido tocar código en este paso. Explora, pregunta lo que no esté claro,
y escribe en `openspec/changes/proj-482-listado-no-recarga/`:

| fichero | qué lleva |
|---|---|
| `proposal.md` | el porqué, el alcance, el **fuera de alcance** y los **criterios de aceptación** |
| `specs/<dominio>/spec.md` | el delta: qué se comporta distinto, en `SHALL` + escenarios `WHEN`/`THEN` |
| `tasks.md` | la checklist ejecutable |

Las reglas de tu `openspec/config.yaml` se le inyectan solas. Dos que importan:

- **Un criterio tiene que poder comprobarse mirando el resultado.** *«El listado va más
  fluido»* no pasa; *«`ProductsView` conserva su `ScrollPosition` al volver, y hay un test
  que lo fija»* sí.
- **Nombra ficheros concretos.** *«Las pantallas que recargan»* no dice cuáles, y por tanto
  nadie puede verificar que estén todas.

### El delta de spec, en el formato del CLI

Esto es lo que más cuesta la primera vez. No es prosa libre: si no lleva esta forma,
`openspec list --specs` dice `requirements 0` y ni `validate` ni `archive` sirven de nada.

```markdown
## ADDED Requirements

### Requirement: El listado conserva el scroll al volver de la ficha

`ProductsView` SHALL conservar su posición de scroll cuando el usuario vuelva de la ficha
de un producto, y SHALL NOT recargar el listado si los datos no han cambiado.

#### Scenario: Volver de la ficha

- **WHEN** el usuario hace pop de la ficha de un producto
- **THEN** el listado muestra la misma posición de scroll que tenía
- **AND** no se lanza ninguna carga de red
```

Encabezados y `SHALL` en inglés; el cuerpo, en tu idioma. Un bloque `## MODIFIED
Requirements` lleva el requisito **entero**, con todos los escenarios que sobreviven.
Comprueba con `openspec validate --all` antes de seguir.

## 2. Lees el acuerdo ⬅ el momento importante

Son dos minutos y es donde se gana o se pierde todo: estás corrigiendo un malentendido antes
de que cueste una tarde. Si no te convence, se corrige el `proposal.md` y se vuelve a
proponer. No hay nada que revertir.

## 3. Implementar

```
/opsx:apply
```

Ejecuta las tareas marcando `[x]`. En cada turno, el hook `UserPromptSubmit` le reinyecta el
acuerdo: las tareas que quedan, el fuera de alcance, y las reglas que ningún linter puede
comprobar. No se le pide que recuerde —cree que se acuerda, y no relee—: se le pone el texto
delante otra vez, corto. Dos reglas que ese recordatorio repite:

- **Antes de escribir una función, `/kit-duplicados`.** Es barato y evita el mismo cuerpo
  escrito tres veces en tres semanas distintas.
- **Si descubres que el acuerdo estaba mal, se corrige el acuerdo por escrito.** Lo
  prohibido es seguir en silencio porque «es obvio que hace falta».

## 4. Verificar

```
/kit-verifica
```

Corre lo que diga tu `kit.conf`, pasa el detector de duplicados, y firma el resultado contra
el `sha256` del árbol que acaba de verificar. La firma vive en `.agent-kit/verificacion.txt`,
fuera de git, y dice **con qué** se verificó —`toolchain: Swift 6.4 · Xcode 27.0`— y **qué no
cubre**, si tu `kit.conf` lo declara en `LIMITES`. Un verde no significa «esto pasa»,
significa «esto pasó aquí».

Los duplicados avisan, no bloquean: uno puede ser deliberado, y eso lo decide quien tiene el
cambio delante.

## 5. El reviewer — *¿esto rompe algo?*

```
/kit-revisa
```

Sub-agente con contexto fresco y solo el diff delante. Corrección, seguridad, o un requisito
explícito del encargo. Estilo y refactors oportunistas se mencionan en una línea y no
bloquean: un revisor que reporta preferencias enseña a quien lo lee a ignorarlo.

Veredicto `GREEN` / `AMBER` / `RED`. Un RED sin reproducción no es un RED. Con GREEN o AMBER se
marca el punto (`rodaja.sh --revisada`); con RED no, para que lo arreglado entre en la
revisión siguiente. Y una segunda condición para marcar: **si arreglar lo que el revisor
encontró cambió lo que hace el código que se entrega, ese arreglo no lo ha visto nadie.** Se
vuelve a pasar, y se marca entonces. Corregir pruebas o prosa no obliga.

### Se revisa al cerrar cada tarea, no al final

Revisar al final significa revisar el cambio **entero**, y volver a revisarlo entero en cada
vuelta: el coste es «tamaño de lo revisado × número de rondas», y así los dos factores están
al máximo. Y un hallazgo al final llega cuando el contexto ya se perdió y cuando devolver una
cosa devuelve las que venían detrás.

No hace falta proceso nuevo: `tasks.md` ya trocea el trabajo. `rodaja.sh` recuerda dónde
acabó la revisión anterior —con un objeto de `git stash create`, sin tocar tu índice— y te
enseña lo que hay desde ahí. La primera rodaja siempre es la más grande; si una pasa de 400
líneas, el script avisa de que se está revisando tarde.

Con un matiz: en SwiftPM la unidad que compila es el target, y una rodaja que no compila no
se puede verificar ni revisar. Creando código nuevo, la primera rodaja es «la feature entera
compilando»; modificando código existente sí se trocea fino. **La rodaja la define el
compilador, no `tasks.md`.**

## 6. El juez de aceptación — *¿es lo acordado?* · opcional

```
/kit-acepta
```

Es el único paso del flujo que no es obligatorio. Cuándo merece pagarlo lo dice el propio
comando, `/kit-acepta`. Cuesta una ronda entera, así que conviene decidirlo al empezar.

Lee el `proposal.md`, el delta y lo entregado, y va **criterio por criterio**, cada uno con
evidencia (`fichero:línea`):

| veredicto | qué significa |
|---|---|
| **ACEPTADO** | todos cumplidos, con evidencia |
| **DEVUELTO** | falta algo. Dice qué, y para |
| **ACUERDO-ROTO** | hay criterios incomprobables, o el diff hace cosas que ningún criterio pedía |

Busca tres cosas a propósito: el requisito que se evaporó (recorre **la lista**, no el
diff), el requisito a medias, y lo que nadie pidió.

**Anota la ronda en una línea** al final de `tasks.md`: número, veredicto, y si tus arreglos
cambiaron lo que hace el código. Es el contador de su tope, porque él empieza en blanco en
cada invocación; la forma está en `/kit-acepta`.

### Por qué no basta con el reviewer

Este es un veredicto real, sobre un cambio que subía dos paquetes y adoptaba la cancelación
del trabajo en vuelo al desmontar una pantalla:

> El cambio **compila, pasa 144 tests y hace lo que hacía falta**. Y aun así rompió su
> propio acuerdo en dos sitios:
>
> 1. **Hizo lo que su «Fuera de alcance» prohibía.** Subir el `from:` de los tres
>    manifiestos no estaba autorizado. Y no fue capricho: era necesario —el resolutor de
>    Xcode se quedaba en la versión vieja—, pero eso es justamente el momento de volver al
>    acuerdo y renegociarlo por escrito.
> 2. **Un criterio escrito de forma incomprobable.** «Las pantallas que lanzan trabajo
>    largo» no dice cuáles.
>
> Ninguno de los dos fallos lo habría visto nada de lo que ya había: el compilador no opina
> de alcance, los 144 tests pasan, el linter de arquitectura está verde, y un reviewer
> mirando el diff habría dicho GREEN — porque el diff, en sí, es correcto.

El cambio no se revirtió: **se corrigió el acuerdo**, que era lo que estaba mal, y por
escrito. Esa es la dirección legítima. La prohibida es la contraria — retocar el acuerdo en
silencio para que encaje con lo entregado.

## 7. Archivar

```
/opsx:archive
```

Funde el delta en `openspec/specs/<dominio>/spec.md` y mueve la carpeta a
`openspec/changes/archive/<fecha>-<nombre>/`.

Si pasaste el juez, su veredicto manda: **no se archiva con ACUERDO-ROTO** —se corrige el
acuerdo primero, por escrito— **ni con un DEVUELTO del producto**, una pieza que no hace lo
acordado. Con un DEVUELTO que no es del producto y el presupuesto de rondas agotado, decides
tú: puedes archivar, y la deuda queda escrita en el acuerdo.

Y si arreglar lo que el juez señaló cambió lo que hace el código, pásalo por el revisor antes
de archivar: el juez pregunta si es lo acordado, no si rompe algo. Nada lo comprueba: el kit
ha decidido no poner un hook en el archivado, así que lo sabe quien arregló.

Tu spec viva acaba de crecer. Dentro de seis meses, cuando alguien pregunte *«¿esto se
recarga al volver o no?»*, la respuesta está escrita, con la razón al lado.

## 8. Commit y cierre del ticket

Al intentar `git commit`, la puerta —un hook `pre-commit` de git que `/kit-verifica` dejó
instalado en el repositorio— comprueba la firma. Si algo fuera de `openspec/` cambió desde
que verificaste, bloquea y dice por qué, desde cualquier terminal y con cualquier forma de
escribir el comando. Archivar entre la verificación y el commit no obliga a verificar otra
vez: commitea el código y el acuerdo juntos.
Stagear, verificar y commitear van por separado, y la razón está en
[PIEZAS.md](PIEZAS.md#verificash--la-firma).

En el PR va el código **y** el cambio de `openspec/`. Quien lo revise lee el `proposal.md` y
sabe qué se acordó sin tener que reconstruirlo del diff. Cierras PROJ-482.

## Un cambio que no toca código

Pasa más de lo que parece y es correcto. Ejemplo real: decidir si un login en vuelo debe
sobrevivir a su pantalla. La decisión fue **mantener el comportamiento actual**, así que no
hubo diff de código, solo un escenario nuevo en la spec con la razón al lado. Antes, ese
login se cancelaba por accidente, porque nadie miró el default de la dependencia. Después se
cancela por decisión. El comportamiento es idéntico; lo que cambia es que deja de ser una
casualidad.

## Lo que corre de fondo sin que nadie lo pida

| hook | cuándo | qué hace |
|---|---|---|
| `UserPromptSubmit` | cada turno | reinyecta el acuerdo y las tareas pendientes |
| `SessionStart(compact)` | tras compactar | lo mismo — es justo cuando se pierden las reglas |
| `pre-commit` de git | en cada `git commit` | lo bloquea sin firma válida. No es de Claude Code: lo instala `/kit-verifica` en `.git/hooks/` |

Su código corre fuera del contexto del modelo; lo que cuesta es lo que devuelven, y está
en [PIEZAS.md](PIEZAS.md#coste).

## Cuánto proceso pide cada cambio

No todo cambio necesita los seis pasos, y forzarlos es la forma más rápida de que la gente
deje de usar esto:

| tamaño del cambio | qué escribes | ¿conviene el juez? |
|---|---|---|
| menos de ~5 ficheros, alcance claro | **proposal + delta**. Salta `tasks.md` | no suele aportar: el revisor llega |
| varios ficheros, o toca varias capas | proposal + delta + tasks | sí, aquí es donde paga |
| el alcance creció a mitad | lo que ya tuvieras, **más la enmienda por escrito** | sí, y por eso mismo |

Ninguna fila obliga: la columna dice cuándo aporta, no qué hay que hacer. Lo que **nunca** se
salta es el **«Fuera de alcance»** y el **delta de spec**, aunque el cambio sea de una línea.
Y no escribas números de línea en la prosa: caducan durante la propia implementación que los
cita. `grep` los encuentra siempre.

## Cuántas rondas merece esto

La tabla de arriba decide qué artefactos escribes. Esta decide **cuántas vueltas de revisor
pagas** —y de juez, si decides invocarlo—, que es donde de verdad se va el coste.
Presupuéstalas antes de invocar a nadie, según lo que vayas a poner bajo juicio:

| lo que se pone bajo juicio | rondas a presupuestar |
|---|---|
| código con tests que pasan o fallan | **1–2** |
| código sin tests, o cuyo efecto se ve leyendo | 2–3 |
| prosa: un prompt, una spec, una norma | **2, y prepárate para parar** |
| **las dos cosas** — código y una norma nueva | **manda la prosa**: presupuesta como si fuera solo eso |

La última fila no dispara porque el cambio *tenga* delta de spec —eso lo cumplen todos—.
Dispara cuando la prosa es **lo que se juzga**: el cambio reescribe un prompt, una norma o una
spec, y eso es el producto entregado. Ahí no hay tests que cierren nada, y cada arreglo
reescribe la norma: por eso no converge sola. El tamaño del cambio mueve el coste de una
ronda mucho menos que el número de rondas, así que **acotar las rondas rinde más que acotar
el alcance**.

### Qué hacer cuando se agote

**Para y decide tú.** Puedes pagar otra vuelta, partir el cambio, o archivar con la deuda
escrita en el acuerdo si lo que queda no es del producto (paso 7). Lo que no vale es seguir
por inercia. El tope del juez es lo mismo por el otro lado: él lo detecta desde dentro —dos
rondas sin cambiar lo que el código hace— y el presupuesto lo declaras tú antes. Las rondas
no las cuenta el kit: las cuentas tú contra el presupuesto.

## Los tres sitios donde decide un humano

Aprobar el acuerdo (paso 2); las decisiones de producto, que el agente deja escritas como
cambio activo y `openspec list` enseña; y los duplicados: extraer, o dejarlo con una razón.

## Lo que este flujo NO hace

No impide que el modelo alucine; no obliga a nadie a leer una skill (pone el texto delante,
no fuerza la lectura); y no defiende contra quien se lo quiera saltar (`--no-verify`, otra
terminal). Lo que sí hace: frena el **error de proceso** —el modelo no miente, se olvida— y
convierte la deriva en algo visible y comprobable.
