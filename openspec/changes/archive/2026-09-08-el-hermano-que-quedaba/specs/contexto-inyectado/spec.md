# contexto-inyectado — delta

## MODIFIED Requirements

### Requirement: El hook no escribe en repositorios que no usan el kit

El hook SHALL evitar crear ficheros o directorios dentro de un repositorio que no dé
señales de usar el kit, y las dependencias que anuncia SHALL acotarse al prefijo del
repositorio observado.

1. Tras correr sobre un repositorio sin `kit.conf` ni `openspec/`, el estado de git SHALL
   quedar igual que antes.
2. El caché que hoy vive en `.agent-kit/` SHALL vivir fuera del repositorio observado.
3. Dos repositorios distintos SHALL tener cachés distintos.
4. El caché SHALL seguir evitando el recorrido de `DerivedData` en turnos consecutivos.
5. La búsqueda de dependencias SHALL acotarse por el prefijo `<carpeta del repositorio>-*`
   sobre `DerivedData`. Un repositorio sin dependencias resueltas NO SHALL recibir las de un
   proyecto cuyo nombre no case con ese prefijo.
6. **El acotado es por prefijo y no por identidad**, con la consecuencia que eso tiene: un
   repositorio `spm` SÍ recibe las de `spm-pro`. Ese límite SHALL estar declarado donde vive
   la resolución.

Las cláusulas 5 y 6 sustituyen a una 5 que prometía un absoluto —«NO SHALL recibir las de
otro proyecto de la misma máquina»— que el acotado por prefijo rompe. Reproducido el
2026-09-08: un repositorio `spm`, sin dependencias propias, recibía `PaqueteDelVecino` desde
`spm-pro-555444`.

**Por qué se corrige aquí y no en otro cambio.** Este es el que hizo que las dos piezas
compartan la MISMA función y el que decidió declarar sus límites como canon. Archivarlo
dejando la norma del hermano diciendo lo contrario sobre la misma función es, literalmente, el
defecto que este cambio persigue — «la regla que llegó a un fichero y no a su hermano»— cometido
en la capa del acuerdo.

Se corrigieron una por una todas las instancias que se fueron encontrando, y aun así esta se
escapó dos rondas seguidas —y con ella el escenario de aquí abajo, dentro del arreglo—, porque
el criterio que las buscaba estaba escrito en términos **léxicos** («que ningún documento diga que falla hacia
el lado seguro») mientras lo que protege es **semántico**: que ningún documento prometa una
garantía de acotado que el código no da. Este no dice esa frase; dice algo más fuerte y más
falso. Es el hueco léxico-semántico que el prompt del juez de aceptación ya tiene escrito como
la trampa más fina de los censos, aplicada a una promesa en vez de a un número.

#### Scenario: Un repositorio sin dependencias en una máquina con otros proyectos

- **WHEN** el hook corre en un repositorio sin dependencias resueltas, en una máquina cuyo
  `DerivedData` tiene paquetes de proyectos cuyo nombre no empieza por el suyo
- **THEN** el digest no nombra ninguna dependencia

#### Scenario: Un proyecto vecino cuyo nombre empieza por el del repositorio

- **WHEN** el hook corre en un repositorio `spm` y la máquina tiene `DerivedData` de `spm-pro`
- **THEN** el digest todavía nombra las de `spm-pro`
- **AND** ese límite está declarado donde vive la resolución

#### Scenario: Un repositorio ajeno al kit

- **WHEN** una sesión pasa por un repositorio sin `kit.conf` ni `openspec/`
- **THEN** el hook inyecta su contexto
- **AND** no deja ningún fichero ni directorio nuevo en ese repositorio

#### Scenario: Dos proyectos con dependencias distintas

- **WHEN** el hook corre en un repositorio y después en otro con dependencias distintas, y
  ninguno de los dos nombres es prefijo del otro
- **THEN** cada uno recibe las suyas
- **AND** ninguno recibe las del otro
