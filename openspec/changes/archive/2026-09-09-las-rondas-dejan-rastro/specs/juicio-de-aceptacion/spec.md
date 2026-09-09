# juicio-de-aceptacion — delta

## ADDED Requirements

### Requirement: Cada ronda deja escrito su veredicto en el acuerdo

Tras cada invocación del revisor o del juez, quien la invoca SHALL anotar el resultado en el
acuerdo del cambio.

1. La anotación SHALL decir qué ronda es, qué veredicto dio y qué encontró.
2. La anotación de una ronda de **juez** SHALL decir además qué pasó con el comportamiento,
   medido por **lo que los arreglos hicieron** y no por lo que el juez pidió, y SHALL
   distinguir tres casos: que algún arreglo cambiara lo que una pieza hace; que ninguno lo
   cambiara; y que se pidiera moverlo y no se hiciera. El tope no cuenta lo mismo en los dos últimos —el tercero es un desacuerdo
   abierto y su propia regla dice que NO es una ronda limpia— y un sí/no los colapsa.
   Las pasadas de **revisor** no llevan este dato: el revisor no tiene tope.
2bis. Los dos bloques SHALL identificarse por quién los produjo, y solo los de juez SHALL
   numerarse como rondas. Mezclarlos hace que el tope cuente pasadas de revisor y se dispare
   antes de tiempo, que es el error que su prompt llama el caro.
3. SHALL escribirla **quien invoca**, NO el sub-agente.
4. El sitio SHALL ser `tasks.md`, o el final de `proposal.md` cuando el cambio no lleve lista
   de tareas.

Esto existe porque el tope del juicio se apoya en un registro que **nadie escribía**. Su propio
texto dice que el contador lo lleva `tasks.md` porque el juez es un sub-agente y cada
invocación empieza en blanco; lo que faltaba era que alguien lo escribiera.

Medido el 2026-09-09 en el primer uso del kit fuera de este repositorio: en `AppStarter`, el
bucle entero del cambio `descuento-visible-en-carrito` —pasadas de revisor y ronda de juez— no
dejó ni una línea en su acuerdo archivado. El detalle de qué encontró cada una se perdió con
él, que es la mitad del daño. Reproducible sobre cualquier cambio archivado:

```
grep -cE '^## Del |AMBER|ACEPTADO|ronda' openspec/changes/archive/<cambio>/tasks.md
```

Y no lo pedía nadie: ni los dos comandos que lanzan a esos agentes, ni los dos prompts. En este
repositorio se anotaba porque quien orquestaba lo hacía por su cuenta, no porque el kit lo
pidiera — y eso hizo pasar por normal lo que era una costumbre de una sola casa.

La 3 es la cláusula que protege algo, no una preferencia de reparto. Los prompts de `agents/`
les prohíben escribir a propósito: el del juez termina diciendo que editar el acuerdo para que
encaje con lo entregado «es exactamente el fraude que este agente existe para impedir», y el
del revisor que no ejecuta nada que cambie estado del repositorio. Darles permiso de escritura
en la carpeta que juzgan abriría esa superficie para resolver un problema que se resuelve sin
ella. Quien invoca ya escribe, y además es el único que sabe si la ronda le hizo tocar código.

La 2 y la 2bis son las que hacen que el registro sirva al tope y no solo al historial, y las
dos las trajo el juez de este cambio leyéndolo **como consumidor del dato**: la primera versión
mandaba anotar un sí/no y pedía el flag también al revisor. El sí/no colapsaba dos casos que su
regla separa, y el revisor no tiene tope que alimentar — el criterio era más ancho que la
necesidad. Es la única ronda en la que quien consume el dato puede decir si le sirve, y dijo
que no del todo.

**Límite declarado.** Nadie comprueba que se anote: es una instrucción en un prompt, y
`autocomprueba.sh` —que mira frontmatter, rutas y recuentos de piezas— no entra aquí. Un
orquestador que se la salte deja el tope como estaba. Y queda un segundo canal, medido y no
cerrado: quien invoca puede decirle al juez en qué ronda va dentro del propio mensaje, sin que
eso quede escrito ni sea auditable; la regla de que en caso de discrepancia manda el acuerdo ya
está escrita y no cambia aquí.

#### Scenario: Una ronda de juez que devuelve el cambio

- **WHEN** el juez devuelve un veredicto y quien lo invocó arregla lo señalado
- **THEN** el acuerdo gana un bloque con la ronda, el veredicto y los hallazgos
- **AND** dice si esos arreglos movieron el comportamiento

#### Scenario: Una pasada de revisor

- **WHEN** el revisor devuelve GREEN, AMBER o RED
- **THEN** el acuerdo gana un bloque con esa pasada y lo que encontró
- **AND** el bloque dice que es del revisor, y no se numera como ronda de juicio

#### Scenario: El juez pide mover el comportamiento y no se mueve

- **WHEN** el juez señala algo que haría tocar comportamiento y quien lo invocó no lo hace
- **THEN** la anotación lo dice como desacuerdo abierto
- **AND** esa ronda no cuenta como limpia para el tope

#### Scenario: Un cambio sin lista de tareas

- **WHEN** el cambio se acogió a saltarse `tasks.md` y pasa por el revisor o el juez
- **THEN** la anotación va al final de `proposal.md`

#### Scenario: El sub-agente no escribe

- **WHEN** termina una invocación del revisor o del juez
- **THEN** el sub-agente no ha modificado ningún fichero del acuerdo
- **AND** la anotación la ha escrito quien lo invocó
