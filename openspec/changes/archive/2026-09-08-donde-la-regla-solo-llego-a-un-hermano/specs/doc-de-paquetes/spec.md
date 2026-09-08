# doc-de-paquetes — delta

## ADDED Requirements

### Requirement: Las dependencias resueltas por SwiftPM se encuentran donde SwiftPM las deja

`doc-paquetes.sh` SHALL localizar los paquetes resueltos en los **dos** sitios que declara su
propia cabecera: el `.build/checkouts/` del repositorio y el `SourcePackages/checkouts/` de
`DerivedData`.

1. Un paquete resuelto en el `.build/checkouts/` del repositorio SHALL aparecer en la
   salida, sin que haga falta ningún `DerivedData`.
2. Un repositorio sin ningún paquete resuelto SHALL seguir recibiendo el mensaje que ya
   recibe, y no una lista vacía.
3. SHALL existir un banco que lo compruebe.

La rama de `.build/checkouts` lleva un `-depth 1` en su `find`, y en el `find` de BSD eso
significa «profundidad exactamente 1»: incompatible con un `-path "*/.build/checkouts/*"`,
que necesita profundidad 3 o más. La condición es insatisfacible, así que esa rama **nunca ha
devuelto nada**. Comprobado el 2026-09-08 montando un `.build/checkouts/MiPaquete/` con su
`Package.swift` y su `AGENTS.md`: no aparecía.

Un proyecto SwiftPM puro —el que resuelve con `swift build` y no abre Xcode— recibe «Sin
paquetes resueltos todavía» teniéndolos resueltos, que es el primero de los dos casos que la
cabecera del script promete cubrir.

La 3 no es una consecuencia de las otras dos: es la razón por la que este defecto llevaba ahí
sin que nadie lo viera. `doc-paquetes.sh` era el único script de producción del kit sin banco,
y el único con una rama muerta. Las dos cosas a la vez no son coincidencia.

#### Scenario: Un paquete resuelto por SwiftPM en el propio repositorio

- **WHEN** el repositorio tiene un paquete con `Package.swift` y `AGENTS.md` en
  `.build/checkouts/`
- **THEN** la salida lo nombra
- **AND** nombra su `AGENTS.md`

#### Scenario: Un repositorio sin nada resuelto

- **WHEN** el repositorio no tiene ningún paquete resuelto en ninguno de los dos sitios
- **THEN** la salida dice que no hay paquetes resueltos todavía
