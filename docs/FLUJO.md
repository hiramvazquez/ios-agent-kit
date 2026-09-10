# El flujo completo, de una tarea a un commit

Cómo encaja todo, contado de principio a fin sobre un caso concreto. Si tienes que
explicarle el kit a alguien, este es el documento.

Empezamos con una tarea de Jira, pero lo primero es decir lo que **no** hay: **el kit no
habla con Jira**. Nadie lee el ticket por ti. El flujo empieza cuando tú lo pegas en la
sesión. Si algún día quieres esa integración, es un MCP de Atlassian, no una pieza de esto.

---

## Dónde se trabaja

**Todo el flujo ocurre dentro de una sesión de Claude Code**, con comandos de barra:
`/opsx:propose`, `/opsx:apply`, `/kit-verifica`, `/kit-acepta`, `/opsx:archive`. No hay que
salir a la terminal en ningún paso del día a día.

La terminal solo aparece dos veces, y ninguna es parte del flujo: para **instalar** el
plugin y el CLI de OpenSpec la primera vez, y para **actualizar** el kit cuando cambie.
Está en [INSTALACION.md](INSTALACION.md).

## El reparto

| | responsabilidad |
|---|---|
| **Tú** | traduces el ticket, apruebas el acuerdo, decides lo que es decisión de producto |
| **OpenSpec** | guarda el acuerdo en el repo y lo valida |
| **El agente** | propone, implementa, verifica |
| **Dos jueces** | uno pregunta *¿rompe algo?*, otro *¿es lo acordado?* |
| **Tres hooks** | recuerdan, y uno bloquea |

---

## 0. El ticket

```
PROJ-482 — "Al volver de la ficha de producto, el listado se recarga entero
            y se pierde el scroll"
```

Abres Claude Code en la raíz del proyecto y lo pegas. Nada más.

---

## 1. Proponer — se acuerda, no se programa

```
/opsx:propose "PROJ-482: al volver de la ficha, el listado no debe recargarse ni perder el scroll"
```

El agente **tiene prohibido tocar código en este paso**. Lo dice la propia skill de
OpenSpec: el request autoriza planificación, aunque pida construir algo. Explora, pregunta
lo que no esté claro, y escribe en `openspec/changes/proj-482-listado-no-recarga/`:

| fichero | qué lleva |
|---|---|
| `proposal.md` | el porqué, el alcance, el **fuera de alcance** y los **criterios de aceptación** |
| `specs/<dominio>/spec.md` | el delta: qué se comporta distinto, en `SHALL` + escenarios `WHEN`/`THEN` |
| `tasks.md` | la checklist ejecutable |

Las reglas de tu `openspec/config.yaml` se le inyectan solas. Dos que importan:

- **Un criterio tiene que poder comprobarse mirando el resultado.** *"El listado va más
  fluido"* no pasa; *"`ProductsView` conserva su `ScrollPosition` al volver, y hay un test
  que lo fija"* sí.
- **Nombra ficheros concretos.** *"Las pantallas que recargan"* no dice cuáles, y por tanto
  nadie puede verificar que estén todas.

El formato del delta no es prosa libre. Si no lleva la forma que el CLI espera,
`openspec list --specs` dirá `requirements 0` y ni `validate` ni `archive` servirán de nada
— está en [PRIMER-CAMBIO.md](PRIMER-CAMBIO.md).

---

## 2. Lees el acuerdo ⬅ el momento importante

Son dos minutos y es donde se gana o se pierde todo. Estás corrigiendo un malentendido
**antes** de que cueste una tarde. Si el agente entendió otra cosa, aquí lo ves: está
escrito, en una página, sin código alrededor que lo disimule.

Si no te convence, se corrige el `proposal.md` y se vuelve a proponer. No hay nada que
revertir, porque no se ha escrito una línea de código todavía.

---

## 3. Implementar

```
/opsx:apply
```

Ejecuta las tareas marcando `[x]`. Mientras tanto, **en cada turno**, el hook
`UserPromptSubmit` le reinyecta el acuerdo: las tareas que quedan, el *fuera de alcance*, y
las reglas que ningún linter puede comprobar.

Esa es la respuesta al problema de que un agente "se olvida" de una skill a las dos horas:
no se le pide que recuerde —cree que se acuerda, y no relee—, se le pone el texto delante
otra vez, corto.

Dos reglas que ese recordatorio repite:

- **Antes de escribir una función, `/kit-duplicados`.** Es barato y evita lo que dio origen
  a esta pieza: el mismo cuerpo escrito tres veces en tres semanas distintas.
- **Si descubres que el acuerdo estaba mal, se corrige el acuerdo por escrito.** Lo
  prohibido es seguir en silencio porque «es obvio que hace falta».

---

## 4. Verificar

```
/kit-verifica
```

Corre lo que diga tu `kit.conf`, pasa el detector de duplicados, y **firma el resultado
contra el `sha256` del diff staged**. La firma vive en `.agent-kit/verificacion.txt`, fuera
de git.

Los duplicados **avisan, no bloquean**: uno puede ser deliberado, y eso lo decide quien
tiene el cambio delante.

---

## 5. El reviewer — *¿esto rompe algo?*

```
/kit-revisa
```

Sub-agente con contexto fresco y solo el diff delante. Corrección, seguridad, o un
requisito explícito del encargo. Estilo y refactors oportunistas se mencionan en una línea
y **no bloquean**: un revisor que reporta preferencias enseña a quien lo lee a ignorarlo, y
entonces deja de servir para lo que sí importa.

Veredicto `GREEN` / `AMBER` / `RED`. Un RED sin reproducción no es un RED. Con GREEN o AMBER
se marca el punto (`rodaja.sh --revisada`); con RED no, para que lo arreglado entre en la
revisión siguiente en vez de darse por bueno.

**Y hay una segunda condición para marcar, que es la que más se olvida: si arreglar lo que el
revisor encontró movió el comportamiento, ese código no lo ha visto nadie.** Marcar significa
«desde aquí no se vuelve a revisar», así que hacerlo después de cambiar código convierte la
marca en una afirmación sobre un árbol que ya no es el revisado — el mismo error que la puerta de commit y la
firma de verificación existen para cerrar. Se vuelve a pasar, y se marca entonces.

Qué cuenta como mover el comportamiento lo dice **la tabla del tope**, en
`agents/aceptacion.md` — este documento no la repite, porque reenunciarla en otras palabras
es como se ensanchó una vez. Y en la duda, cuenta como comportamiento: una pasada de más cuesta
menos que marcar sobre algo que nadie ha visto.

Salió de un caso real, y no del kit: el 2026-09-09, en un cambio de `AppStarter`, quien
implementaba se dio cuenta solo y volvió a pasarlo. La segunda pasada encontró más, y una
bloqueaba — la spec se contradecía consigo misma, y al archivar esa contradicción se
habría fundido en la canónica, donde quien la implementara habría reintroducido el defecto que
la primera pasada acababa de cerrar.

**Anota la pasada en el acuerdo** —en `tasks.md`, o al final del `proposal.md`— con su veredicto
y lo que encontró. **Encabézala como del revisor, escríbela al final de lo que haya y en el mismo fichero donde
estén los demás, y no la numeres como ronda**: las rondas que el
juez cuenta son las suyas, y si se mezclan contará pasadas de revisor y su tope puede dispararse
antes de tiempo.

### Se revisa al cerrar cada tarea, no al final

Esto es lo que más cambia respecto a lo que uno haría por instinto, y salió de medirlo.

Revisar al final significa revisar el cambio **entero**, y volver a revisarlo entero en cada
vuelta: el coste es «tamaño de lo revisado × número de rondas», y así los dos factores están
al máximo. En un cambio real fueron 700 líneas pasando nueve veces entre revisor y juez,
cuando los bugs vivían en tres tareas concretas.

Y el coste no es lo peor. Un hallazgo al final llega cuando el contexto ya se perdió, cuando
el arreglo toca código escrito encima, y cuando devolver una cosa devuelve las que venían
detrás.

No hace falta proceso nuevo: `tasks.md` ya trocea el trabajo. `rodaja.sh` solo recuerda
dónde acabó la revisión anterior —con un objeto de `git stash create`, sin tocar tu índice
ni obligarte a commitear cada tarea— y te enseña lo que hay desde ahí, junto con las tareas
cerradas desde entonces.

La primera rodaja siempre es la más grande. Si una pasa de 400 líneas, el script lo dice:
no rechaza la revisión, avisa de que se está revisando tarde.

**Con un matiz que salió de probarlo sobre una feature nueva:** en SwiftPM la unidad que
compila es el target, y una rodaja que no compila no se puede verificar ni revisar. Creando
código, la primera rodaja es «la feature entera compilando» —850 líneas en la prueba real—
porque el modelo no enlaza sin la firma del servicio y el target no compila hasta que están
el ViewModel y la Vista. La rodaja la define el compilador, no `tasks.md`. Modificando
código existente sí se trocea fino; creándolo, no.

---

## 6. El juez de aceptación — *¿es lo acordado?*

```
/kit-acepta
```

Lee el `proposal.md`, el delta y el diff completo, y va **criterio por criterio**, cada uno
con evidencia (`fichero:línea`):

| veredicto | qué significa |
|---|---|
| **ACEPTADO** | todos cumplidos, con evidencia |
| **DEVUELTO** | falta algo. Dice qué, y para |
| **ACUERDO-ROTO** | hay criterios incomprobables, o el diff hace cosas que ningún criterio pedía |

Busca tres cosas **a propósito**, porque si no se buscan se escapan:

1. **El requisito que se evaporó.** Recorre **la lista**, no el diff: el diff enseña lo que
   se hizo, solo la lista enseña lo que falta. Es el modo de fallo más común — el agente
   empieza por lo difícil, lo resuelve bien, y lo fácil del final se queda sin hacer porque
   «ya parecía terminado».
2. **El requisito a medias.** Hecho para el camino feliz y no para el error, o en una de
   las tres pantallas que lo pedían.
3. **Lo que nadie pidió.** Código que no responde a ningún criterio.

**Anota la ronda en el acuerdo**, encabezada como del juez, **al final de lo que haya y en el
mismo fichero donde estén los demás** —el orden dentro del fichero es lo único que dice qué vino
antes—, y —al contrario que la del revisor— **numerada**: son las que su tope cuenta,
y de ahí las lee porque él empieza en blanco cada vez. Con un dato más: qué pasó con el
comportamiento —se movió, no se movió, o él pidió moverlo y no se hizo—. Ese es el que su tope
consume, y no puede saberlo desde dentro de su invocación: lo sabes tú, que arreglaste.

### Por qué no basta con el reviewer

La primera vez que se usó, devolvió **ACUERDO-ROTO** a un cambio que compilaba, pasaba 144
tests y tenía el linter de arquitectura en verde: había hecho justo lo que su propio *fuera
de alcance* prohibía. Y era **necesario** hacerlo — pero ese es exactamente el momento de
volver al acuerdo y renegociarlo por escrito, no de seguir porque es obvio.

Ni el compilador, ni los tests, ni el reviewer lo veían. El compilador no opina de alcance;
los tests pasaban; y el reviewer habría dicho GREEN, porque el diff **en sí** era correcto.

---

## 7. Archivar

```
/opsx:archive
```

Funde el delta en `openspec/specs/<dominio>/spec.md` y mueve la carpeta a
`openspec/changes/archive/<fecha>-<nombre>/`. **No archiva con DEVUELTO ni con
ACUERDO-ROTO**; con ACUERDO-ROTO se corrige el acuerdo primero, por escrito.

**Y hay una condición más, hermana de la del paso 5: si arreglar lo que el juez señaló movió el
comportamiento, ese código no lo ha visto ningún revisor** — el juez pregunta si es lo acordado,
no si rompe algo. Pásalo antes de archivar. La respuesta a «¿falta una pasada?» no se recuerda
ni se lee a ojo: la da `scripts/pasada-pendiente.sh`, y son tres —falta, no falta, o **no se
puede leer**—. La tercera es el producto: cuando el registro **que sabe leer** no alcanza para
decidir lo dice, en vez de suponer que no falta, que es hacia donde se equivocaba la versión en
prosa de esta misma regla. Fuera de eso hay tres casos distintos, y conviene no juntarlos: una
cabecera con la forma y el vocabulario buenos que no sepa clasificar **sí la ve y sí avisa**; una
forma que no reconoce y un título que no nombre al juez ni al revisor **no los ve y no avisa**.
Es un límite declarado, y está entero en la cabecera del script y en el requisito; aquí no se
repite. Lo único que este documento le pide al que escribe es que los bloques vayan **al final y
en un solo fichero**, sin agruparlos por tipo: «posterior» lo decide su orden en el fichero.
Repartirlos entre `tasks.md` y `proposal.md` el script lo detecta y contesta que no se puede
leer; agruparlos por tipo no lo detecta nadie, y es lo que hacen varios acuerdos archivados.

Qué cuenta como mover el comportamiento lo dice la tabla del tope, en `agents/aceptacion.md`;
este documento no la repite.

Build y tests lo acabarán viendo —la firma se invalida y la puerta de commit obliga a
re-verificar en el paso 8, no aquí—; lo que no lo ve
es la pregunta del revisor, que es la que caza lo que los tests no.

**Que falte una pasada te lo dice un script; que no archives sin ella, no.** El del paso 5 se
niega a marcar la rodaja; este solo contesta, y contesta a quien lo llame: **el kit no tiene
ningún hook que intercepte el archivado**. Quien no lo siga archiva igual.

Y no es que no se pueda: `/opsx:archive` corre por la herramienta Bash, que es justo donde la
puerta de commit intercepta `git commit`. Lo que lo impide es una política escrita —
`hooks/hooks.json` dice «tres hooks y ninguno más; un cuarto tiene que traer escrito el fallo
que lo motiva»— y este no lo trae todavía.

Tu spec viva acaba de crecer. Dentro de seis meses, cuando alguien pregunte *"¿esto se
recarga al volver o no?"*, la respuesta está escrita, con la razón al lado.

---

## 8. Commit y cierre del ticket

Al intentar `git commit`, el hook de `PreToolUse` comprueba la firma. Si el árbol cambió
desde que verificaste, **bloquea** y dice por qué.

Por eso stagear, verificar y commitear van en **tres comandos separados**: encadenar
`git add && git commit` cambia el diff entre la firma y el commit.

En el PR va el código **y** el cambio de `openspec/`. Quien lo revise lee el `proposal.md` y
sabe qué se acordó sin tener que reconstruirlo del diff. Cierras PROJ-482.

---

## Lo que corre de fondo sin que nadie lo pida

| hook | cuándo | qué hace |
|---|---|---|
| `UserPromptSubmit` | cada turno | reinyecta el acuerdo y las tareas pendientes |
| `SessionStart(compact)` | tras compactar | lo mismo — es justo cuando se pierden las reglas |
| `PreToolUse` | antes de cada Bash | bloquea `git commit` sin firma válida |

Los tres corren fuera del contexto del modelo: no cuestan tokens.

## Cuánto proceso pide cada cambio

No todo cambio necesita los seis pasos, y forzarlos es la forma más rápida de que la gente
deje de usar esto. La regla salió de medir un cambio de cuatro líneas con el flujo entero:

| tamaño del cambio | qué escribes | ¿juez? |
|---|---|---|
| menos de ~5 ficheros, alcance claro | **proposal + delta**. Salta `tasks.md` | solo si el alcance se movió al implementar |
| varios ficheros, o toca varias capas | proposal + delta + tasks | sí |
| el alcance creció a mitad | lo que ya tuvieras, **más la enmienda por escrito** | **sí, siempre** |

Lo que **nunca** se salta es el **«Fuera de alcance»** y el **delta de spec**, aunque el
cambio sea de una línea. En el cambio de cuatro líneas que sirvió para medir esto, el
«Fuera de alcance» decía *«regenerar imágenes de referencia: el texto no cambia, así que no
deben cambiar»* — y esa frase es la que convirtió «cambia cuatro fixtures» en «cambia cuatro
fixtures y demuestra que ni un píxel se movió». El reflejo ante un snapshot que se queja es
regrabarlo, y regrabar ahí habría destruido en silencio la única señal que el cambio existía
para proteger.

`tasks.md`, en cambio, fue el único artefacto que hubo que enmendar dos veces sin aportar
nada que el proposal no dijera ya. Para un cambio pequeño es un documento cuyo único efecto
posible es quedarse desincronizado.

**Y no escribas números de línea en la prosa.** Caducan durante la propia implementación que
los cita: en ese mismo cambio, añadir un `import` los desplazó y llegaron falsos al juicio.
`grep` los encuentra siempre; el markdown los conserva mal para siempre.

---

## Cuántas rondas merece esto

La tabla de arriba decide qué artefactos escribes. Esta decide **cuántas vueltas de revisor y
juez pagas**, que es donde de verdad se va el coste — y no es lo mismo.

**Presupuéstalas antes de invocar a nadie**, según lo que vayas a poner bajo juicio:

| lo que se pone bajo juicio | rondas a presupuestar |
|---|---|
| código con tests que pasan o fallan | **1–2** |
| código sin tests, o cuyo efecto se ve leyendo | 2–3 |
| prosa: un prompt, una spec, una norma | **2, y prepárate para parar** |
| **las dos cosas** — código y una norma nueva | **manda la prosa**: presupuesta como si fuera solo eso |

**Cuidado con la última fila, que es fácil aplicarla a todo y entonces no sirve de nada.** No
dispara porque el cambio *tenga* delta de spec —el flujo nunca deja saltárselo, así que eso lo
cumplen todos—. Dispara cuando la prosa es **lo que se juzga**, no la vara con la que se mide:

- El delta describe cómo se comporta el código y el juez mide el código contra él → **filas 1
  y 2**. Es el caso normal, y es donde el presupuesto de 1–2 tiene sentido.
- El cambio **reescribe un prompt, una norma o una spec**, y eso es el producto entregado →
  **fila 3**. Aquí no hay tests que cierren nada: la cierra alguien leyendo, y por eso no
  converge sola.

Los cuatro cambios que midieron esta tabla caen todos en el segundo caso, que es lo que hay que
tener en cuenta al leer las cifras de abajo.

**El eje es qué se juzga, no cuánto ocupa**, y eso está medido — con una muestra pequeña que
conviene mirar antes de creerla. El 2026-09-08 hubo diecisiete rondas de juez en este
repositorio; de nueve quedó registrada la cifra, y son esas nueve las que dan **67k–124k tokens
por ronda**.

Comparando dos cambios de esa tanda: el de veinticinco ficheros costó **124,3k y 100,0k** por
ronda; el de un fichero y una sección, **67,7k y 80,0k**. De media, 112,1k contra 73,9k: una vez
y media, **+52 %**. Veinticinco veces más grande y la mitad más de coste por vuelta — **el
tamaño escala muy por debajo de lo lineal**, así que quien manda en la factura es el número de
rondas.

(Las cuatro cifras van con decimal a propósito: con ellas redondeadas a `124/100/68/80` la
media pequeña sale 74k y el ratio 1,51, y quien rehiciera la cuenta encontraría números que no
cuadran con estos. Un juez lo intentó y le pasó.)

Ojo con leer eso de más: un 52 % no es nada. Lo que dice el dato es que **acotar el alcance
rinde mucho menos que acotar las rondas**, no que el tamaño dé igual. La fórmula que este mismo
documento usa más arriba —«tamaño de lo revisado × número de rondas»— sigue siendo la buena;
lo que se aprende aquí es que su primer factor crece despacio y el segundo no.

Y son dos cambios, cuatro rondas: según cómo se emparejen, el ratio va de 1,25 a 1,83. La
dirección es clara; el número, no.

**Y las filas de código no tienen ni una medición detrás.** Los cuatro cambios medidos ponían
prosa normativa bajo juicio, así que la fila 3 se apoya en n=1 y las filas 1 y 2 en **n=0**: son
una expectativa razonada —los tests cierran lo que la lectura no— y nada más. El número que
falta es el de una ronda sobre Swift con tests, y hasta que exista, esas dos filas son una
apuesta con la que empezar, no un dato.

La fila de la prosa es la que muerde, y también está medida: un cambio de unas 300 líneas se
llevó **seis rondas** sin converger, y de las nueve frases que se corrigieron, **cinco estaban
en texto escrito por el arreglo de la ronda anterior**. Cuando el artefacto juzgado es prosa
normativa, cada arreglo vuelve a redactar la norma, y redactarla es lo que fabrica el hallazgo
siguiente. No es que el juez encuentre más: es que el autor produce más.

### Qué hacer cuando se agote

**Para y decide tú.** Puedes pagar otra vuelta con lo que ya sabes, archivar con la deuda
anotada, o partir el cambio. Lo que no vale es seguir por inercia: a la tercera vuelta sin que
el producto se mueva, lo que se está comprando ya no es rigor.

Esto y el **tope del juez** son el mismo mecanismo por los dos lados: el tope lo detecta desde
dentro y al final —dos rondas sin mover el comportamiento— y el presupuesto lo declaras tú
desde fuera y antes. Los dos paran igual y los dos te entregan la misma decisión. Si el juez
llega a su tope antes de que agotes el presupuesto, manda el tope.

**Límite declarado, porque estas cifras se van a leer como ley y no lo son.** Empezando por lo
que peor se ve: **no se pueden recomprobar.** Salen de las notificaciones que dejaron los
sub-agentes de aquel día, que no viven en el repositorio, así que aquí no hay ningún comando que
correr — al revés que la tabla de coste de las piezas, que sí te manda correr uno. Si alguien
las necesita ciertas, tiene que volver a medirlas.

Y se midieron en un solo día, sobre un solo repositorio y sobre un solo tipo de artefacto: el
propio kit, cuyo producto es en buena parte prosa. Es el caso que peor converge, así que **son un techo, no una
media**. Sobre código Swift con tests deberían bajar, y eso **no está medido**: cuando lo midas,
esta tabla se corrige con el dato.

Y no las cuenta nadie por ti. Rastro sí queda —cada pasada y cada ronda se anotan en el
acuerdo, y de ahí las lee el juez—, pero **contarlas y compararlas con el presupuesto lo haces
tú**: no hay contador de rondas ni de tokens en el kit. Si no lo declaras al empezar, te quedas
exactamente como antes de que esta tabla existiera.

## Los tres sitios donde decide un humano

1. **Aprobar el acuerdo** (paso 2). Dos minutos, y evita la tarde perdida.
2. **Las decisiones de producto.** El agente no las toma: las deja escritas como cambio
   activo, y `openspec list` te las enseña cada vez que preguntas qué hay abierto.
3. **Los duplicados**: extraer, o dejarlo con una razón.

## Qué queda en el repo cuando termina

```
openspec/specs/<dominio>/spec.md               ← la verdad actual, un requisito más
openspec/changes/archive/2026-09-07-proj-482/  ← el acuerdo, las tareas y el veredicto
```

Y en el código, el diff. Nada de andamiaje: los agentes, hooks y scripts viven en el
plugin, fuera de tu repo.

---

## Lo que este flujo NO hace

Conviene decirlo cuando se lo expliques a alguien, porque prometer de más es la forma más
rápida de que dejen de usarlo:

- **No impide que el modelo alucine.**
- **No obliga a nadie a leer una skill.** Pone el texto delante; no hay forma de forzar una
  lectura.
- **No defiende contra quien se lo quiera saltar** (`--no-verify`, otra terminal, un git
  invocado de otra forma). Eso no se puede cerrar desde dentro de la misma máquina.

Lo que sí hace: frena el **error de proceso** —el modelo no miente, se olvida— y convierte
la deriva en algo **visible y comprobable** en vez de invisible. Es menos de lo que promete
un sistema de gobernanza, y bastante más de lo que hay sin él.
