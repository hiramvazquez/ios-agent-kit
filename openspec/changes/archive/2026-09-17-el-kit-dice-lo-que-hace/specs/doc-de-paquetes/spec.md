## MODIFIED Requirements

### Requirement: Los paquetes anunciados se acotan al prefijo del repositorio

`doc-paquetes.sh` SHALL anunciar únicamente los paquetes resueltos en su propio
`.build/checkouts` o en un DerivedData cuyo nombre case con `<carpeta del repositorio>-*`.

1. En un repositorio sin `.build/checkouts` y sin ningún DerivedData que case con ese
   prefijo, NO SHALL anunciar ningún paquete, aunque la máquina tenga DerivedData de otros
   proyectos.
2. En un repositorio con DerivedData propio, SHALL anunciar los suyos igual que antes.
3. La resolución de qué DerivedData casa SHALL existir una sola vez en el código, y
   compartirse con el hook que ya la necesitaba.
4. **El acotado es por prefijo y no por identidad**, así que un proyecto cuyo nombre empiece
   por el del repositorio más un guion casa igual: un repositorio `spm` recibe lo de
   `spm-pro-<hash>`. Ese límite SHALL estar declarado en dos sitios y solo en dos: la función
   que resuelve el acotado, y la referencia de piezas (`docs/PIEZAS.md`).

Muerde más aquí que en el hook: la salida de este script manda leer las reglas de los paquetes
que anuncia, así que anunciar los de otro proyecto no es ruido, es una instrucción falsa.

#### Scenario: Un repositorio sin dependencias propias en una máquina con otros proyectos

- **WHEN** se invoca en un repositorio sin `.build/checkouts`, en una máquina cuyo DerivedData
  tiene paquetes de un proyecto cuyo nombre NO empieza por el suyo
- **THEN** no anuncia ningún paquete
- **AND** dice que no hay paquetes resueltos todavía

#### Scenario: Un proyecto vecino cuyo nombre empieza por el del repositorio

- **WHEN** se invoca en un repositorio `spm` y la máquina tiene DerivedData de `spm-pro`
- **THEN** todavía anuncia los de `spm-pro`
- **AND** ese límite está escrito donde vive la resolución

#### Scenario: Un repositorio con su propio DerivedData

- **WHEN** se invoca en un repositorio cuyo DerivedData tiene paquetes resueltos
- **THEN** los anuncia, igual que antes de este cambio
