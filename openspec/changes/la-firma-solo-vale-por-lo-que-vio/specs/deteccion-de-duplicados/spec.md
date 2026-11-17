## ADDED Requirements

### Requirement: Un fichero nuevo cuenta como tocado

Al verificar, los ficheros sin trackear que git no ignora SHALL contar como tocados por el
cambio en curso, igual que los modificados y los stageados.

#### Scenario: La copia vive en un fichero recién creado

- **WHEN** un fichero nuevo, sin trackear, repite un cuerpo que ya existía en otro
- **THEN** la verificación reporta el grupo entero
- **AND** no lo cuenta como preexistente
