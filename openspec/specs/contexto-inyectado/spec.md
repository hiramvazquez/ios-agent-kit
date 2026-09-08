# contexto-inyectado Specification

## Purpose

Poner el acuerdo delante del modelo en cada turno, corto y atribuido. Contra la deriva no
sirve obligar a leer una skill: el modelo cree que se acuerda y no relee. Lo que sirve es que
el texto esté delante otra vez, siempre.

«Atribuido» es la mitad que costó aprender. El hook lee el repositorio del directorio que
hereda la sesión, que no tiene por qué ser aquel en el que se trabaja, y un digest que
describe otro repositorio empuja exactamente en la dirección contraria a la que fue puesto.
Nombrarlo NO elimina ese desfase —no hay señal disponible de dónde trabaja el modelo, y
adivinarla sería peor que callarse—, pero convierte «sin cambio activo», falso sobre el
trabajo en curso, en «en este repositorio, sin cambio activo», que es cierto.

Y no escribe nada dentro del repositorio que observa: corre en toda sesión del usuario,
también en repositorios que nunca pidieron el kit.

## Requirements

### Requirement: El contexto inyectado dice de qué repositorio habla

El hook que inyecta el acuerdo en cada turno SHALL atribuir lo que afirma al repositorio
del que lo ha leído.

1. El digest SHALL nombrar ese repositorio, incluso cuando no haya nada que contar sobre él.
2. Un repositorio sin `openspec/` SHALL producir un digest que lo diga, y que NO ordene
   abrir una propuesta.
3. Un repositorio con `openspec/` SHALL producir el mismo digest que producía antes de
   este cambio, **salvo las líneas de atribución que exige la cláusula 1**.

La 1 no es cosmética y no arregla el desfase: el hook no puede saber en qué repositorio
trabaja el modelo. Lo que hace es convertir una afirmación falsa sobre el trabajo en curso
—«sin cambio activo»— en una afirmación cierta y atribuida —«en este repositorio, sin cambio
activo»—, que es la diferencia entre engañar y informar.

La 2 existe porque la orden de abrir una propuesta, dada sobre un repositorio que no usa
OpenSpec, es un consejo que nadie puede seguir ahí.

#### Scenario: Un repositorio que no usa OpenSpec

- **WHEN** el hook corre en un repositorio sin `openspec/`
- **THEN** el digest nombra ese repositorio
- **AND** dice que no usa OpenSpec
- **AND** no ordena abrir una propuesta

#### Scenario: Un repositorio con OpenSpec y sin cambio activo

- **WHEN** el hook corre en un repositorio con `openspec/` y ningún cambio activo
- **THEN** el digest dice lo mismo que decía antes de este cambio
- **AND** lo atribuye a ese repositorio

### Requirement: El hook no escribe en repositorios que no usan el kit

El hook SHALL evitar crear ficheros o directorios dentro de un repositorio que no dé
señales de usar el kit.

1. Tras correr sobre un repositorio sin `kit.conf` ni `openspec/`, el estado de git SHALL
   quedar igual que antes.
2. El caché que hoy vive en `.agent-kit/` SHALL vivir fuera del repositorio observado.
3. Dos repositorios distintos SHALL tener cachés distintos.
4. El caché SHALL seguir evitando el recorrido de `DerivedData` en turnos consecutivos.

La 3 es la que se rompe si la 2 se hace mal: un caché fuera del repositorio, sin el
repositorio en la clave, serviría las dependencias de un proyecto a otro — un fallo peor que
el que se arregla, porque el dato equivocado parecería correcto.

#### Scenario: Un repositorio ajeno al kit

- **WHEN** una sesión pasa por un repositorio sin `kit.conf` ni `openspec/`
- **THEN** el hook inyecta su contexto
- **AND** no deja ningún fichero ni directorio nuevo en ese repositorio

#### Scenario: Dos proyectos con dependencias distintas

- **WHEN** el hook corre en un repositorio y después en otro con dependencias distintas
- **THEN** cada uno recibe las suyas
- **AND** ninguno recibe las del otro
