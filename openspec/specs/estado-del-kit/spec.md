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

### Requirement: La versión del kit se dice con el consejo que la arregla

`/kit-estado` SHALL comparar tres versiones del kit —la que corre en esta conversación, la
instalada y la del clon local del marketplace— y, cuando no coinciden, SHALL dar el consejo que
corresponde:

1. Si la instalada no es la que corre y el clon del marketplace trae la misma que la instalada,
   SHALL decir que hay que abrir una conversación nueva, y que una reanudada puede seguir con la
   versión con la que empezó. NO SHALL aconsejar `claude plugin update`, que ya no cambia nada.
2. Si el clon del marketplace trae una versión distinta de la instalada, SHALL aconsejar
   `claude plugin update` y, después, una conversación nueva, **también cuando además la instalada
   no es la que corre**: una conversación nueva sin actualizar cargaría una versión que ya no es la
   última.
3. Si las tres coinciden, SHALL decir cuál es, sin consejo.
4. Si no puede leer la versión instalada, SHALL comparar la que corre con la del clon, como hacía el
   aviso de `verifica.sh` antes de este cambio.

El caso 1 es el del 2026-09-14: con la 1.12.2 instalada, una conversación reanudada seguía en la
1.10.0, y el aviso decía «claude plugin update».

**Límite declarado.** No ve una versión publicada que todavía no ha llegado al clon del
marketplace: verlo exige red. Eso lo mira `/kit-verifica`, una vez al día.

#### Scenario: Conversación reanudada con una versión vieja

- **WHEN** corre la 1.10.0, y la instalada y la del clon son la 1.12.2
- **THEN** aconseja abrir una conversación nueva
- **AND** no aconseja `claude plugin update`

#### Scenario: El marketplace va por delante de lo instalado

- **WHEN** la que corre y la instalada son la 1.12.1 y el clon trae la 1.12.2
- **THEN** aconseja `claude plugin update` y, después, una conversación nueva

#### Scenario: Todo al día

- **WHEN** las tres versiones coinciden
- **THEN** dice cuál es, sin consejo
