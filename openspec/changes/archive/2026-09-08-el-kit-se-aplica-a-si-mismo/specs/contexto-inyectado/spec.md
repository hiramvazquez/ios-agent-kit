## ADDED Requirements

### Requirement: El hook no escribe en directorios compartidos

El hook que inyecta el acuerdo NO SHALL crear ficheros fuera de su caché declarada.

1. NO SHALL escribir en un directorio compartido por todos los usuarios de la máquina con un
   nombre derivable del identificador de proceso.
2. El digest producido SHALL ser el mismo que antes de este cambio, salvo lo que exija la
   cláusula de los cambios activos múltiples.

Este hook corre en cada turno de cualquier repositorio por el que pase una sesión, así que un
temporal de nombre adivinable en un directorio escribible por cualquiera es un riesgo
innecesario para lo que hace: componer tres líneas de texto. Es además la extensión natural
de la regla que este mismo hook ya cumple —no escribir dentro del repositorio observado— al
único sitio donde todavía escribe.

#### Scenario: El hook compone el digest con tareas pendientes

- **WHEN** el hook corre en un repositorio con un cambio activo y tareas sin cerrar
- **THEN** el digest sale igual que antes
- **AND** no queda ningún fichero nuevo en el directorio temporal del sistema
