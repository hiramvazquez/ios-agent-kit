# estado-del-kit Specification

## Purpose

Poder preguntar «¿cómo estamos?» en cualquier momento y que conteste al instante, leyendo lo que el
kit ya escribe: sin compilar, sin red y sin tocar el árbol de trabajo. Lo que **no** pretende:
verificar ni bloquear nada; es una pregunta, no una puerta.

## Requirements

### Requirement: `/kit-estado` solo lee

`/kit-estado` SHALL responder sin ejecutar los pasos de verificación del proyecto, sin consultar la
red y sin escribir nada en el árbol de trabajo.

1. NO SHALL ejecutar las verificaciones de `kit.conf` ni ningún build o test.
2. NO SHALL crear, modificar ni borrar ningún fichero ni directorio del árbol de trabajo, tampoco
   dentro de `.agent-kit/`.
3. NO SHALL consultar ningún remoto.
4. SHALL salir con 0 siempre que haya podido mirar, aunque lo que cuente esté en rojo: es una
   pregunta, no una puerta.

**Límites declarados.** Carga el `kit.conf` del proyecto para saber dónde buscar duplicados, igual
que `/kit-duplicados`, y cargarlo ejecuta código del repositorio. Y git puede refrescar la caché de
su índice (`.git/index`) al calcular la huella de la firma: es el mismo cálculo que hacen la puerta
de commit en cada commit y el hook de contexto en cada turno, y evitarlo exigiría cambiar la huella.
Lo stageado no cambia.

#### Scenario: Un repositorio que nunca pidió el kit

- **WHEN** se invoca `/kit-estado` en un repositorio git sin `.agent-kit/`
- **THEN** responde
- **AND** el repositorio sigue sin `.agent-kit/` y `git status --porcelain` no cambia

#### Scenario: La última verificación salió en rojo

- **WHEN** se invoca sobre un repositorio cuya última verificación salió en rojo
- **THEN** lo dice
- **AND** sale con 0

### Requirement: Dice cuánto trabajo hay sin guardar

`/kit-estado` SHALL decir la rama, cuántos ficheros hay stageados, sin stagear y sin trackear, y
cuántos commits hay sin empujar y sin traer.

1. Los commits sin empujar y sin traer SHALL contarse contra la última copia conocida del remoto, y
   la salida SHALL decir que es respecto al último `fetch`.
2. Una rama sin rama remota asociada SHALL decirlo, en vez de contar cero.

#### Scenario: Una rama sin upstream

- **WHEN** la rama actual no sigue ninguna rama remota
- **THEN** dice que no tiene upstream
- **AND** no dice que haya cero commits sin empujar

### Requirement: Lista todos los cambios activos

`/kit-estado` SHALL listar todos los cambios OpenSpec activos, no solo el primero, y para cada uno
cuántas tareas lleva hechas de cuántas.

1. Un cambio sin lista de tareas NO SHALL llevar recuento: «0/0 hechas» se lee como «no queda
   nada por hacer».
2. Sin cambios activos SHALL decirlo, y en un repositorio sin `openspec/` SHALL decir que no usa
   OpenSpec.

#### Scenario: Dos cambios activos, uno sin lista de tareas

- **WHEN** hay dos cambios activos y solo uno tiene `tasks.md`
- **THEN** salen los dos
- **AND** solo el que tiene lista lleva recuento

### Requirement: El veredicto de firma es el de la puerta de commit

`/kit-estado` SHALL decir si la firma de verificación vale para el árbol actual con el mismo
veredicto que usa la puerta de commit, y SHALL añadir la fecha y el resultado de la última
verificación.

El mismo veredicto y no uno parecido: una firma de este árbol pero de una verificación en rojo no
vale para la puerta, y tampoco SHALL valer aquí.

#### Scenario: Firma de otro árbol

- **WHEN** la última verificación firmó un árbol distinto del actual
- **THEN** dice que la firma es de otro árbol
- **AND** dice cuándo fue esa verificación y con qué resultado

#### Scenario: Nada verificado

- **WHEN** nunca se ha verificado en este repositorio
- **THEN** dice que no hay nada verificado

### Requirement: Cuenta toda la lógica repetida

`/kit-estado` SHALL decir cuántos grupos de lógica repetida hay en las fuentes del proyecto —todos,
no solo los que toca el cambio en curso— y SHALL remitir a `/kit-duplicados` para verlos.

#### Scenario: Duplicados que ningún cambio toca

- **WHEN** el proyecto tiene grupos repetidos y el árbol no tiene cambios
- **THEN** los cuenta

### Requirement: Dice qué versión del kit corre

`/kit-estado` SHALL decir la versión del kit que ha cargado la conversación, leída del
manifiesto del plugin que ejecuta el comando, y NO SHALL compararla con nada ni dar consejo.

1. La línea SHALL salir siempre que el manifiesto sea legible; si no lo es, SHALL decirlo.
2. NO SHALL consultar la red ni leer ficheros internos de Claude Code para averiguar qué hay
   instalado.

#### Scenario: Se pregunta el estado

- **WHEN** se invoca `/kit-estado`
- **THEN** una línea dice la versión del kit que corre
- **AND** no hay ninguna otra línea sobre versiones

#### Scenario: El manifiesto no está

- **WHEN** el plugin no tiene un `plugin.json` legible junto a sus scripts
- **THEN** la línea dice que no encuentra el manifiesto
