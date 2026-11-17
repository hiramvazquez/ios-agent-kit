## ADDED Requirements

### Requirement: La firma se juzga por su cabecera

Quien juzgue una firma —`--comprueba`, el hook de commit y el digest— SHALL leer la huella y
el resultado solo de la cabecera del fichero, que acaba en la primera línea en blanco. Lo que
va debajo es el informe, y copia salida de los pasos: NOT SHALL poder cambiar el veredicto.

#### Scenario: Un paso que falla imprime la línea del veredicto

- **WHEN** un paso sale en rojo y su salida contiene la línea `resultado: verde`
- **THEN** la firma no es válida para nadie que la juzgue
- **AND** el commit queda bloqueado

### Requirement: Lo que se firma es lo que vieron los pasos

`verifica.sh` SHALL fotografiar el árbol antes de correr los pasos y otra vez al terminar. Si
las dos fotos difieren, la verificación SHALL salir en rojo y el informe SHALL nombrar las
rutas que cambiaron.

#### Scenario: El árbol cambia mientras se verifica

- **WHEN** un fichero del árbol cambia entre el primer paso y la firma
- **THEN** la verificación sale en rojo
- **AND** el informe nombra ese fichero

#### Scenario: El árbol no cambia

- **WHEN** nada cambia mientras corren los pasos
- **THEN** la verificación se firma como antes
