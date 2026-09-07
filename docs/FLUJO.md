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

Sub-agente con contexto fresco y solo el diff delante. Corrección, seguridad, o un
requisito explícito del encargo. Estilo y refactors oportunistas se mencionan en una línea
y **no bloquean**: un revisor que reporta preferencias enseña a quien lo lee a ignorarlo, y
entonces deja de servir para lo que sí importa.

Veredicto `GREEN` / `AMBER` / `RED`. Un RED sin reproducción no es un RED.

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
