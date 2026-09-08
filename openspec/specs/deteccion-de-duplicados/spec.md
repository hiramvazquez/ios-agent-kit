# deteccion-de-duplicados Specification

## Purpose

Cazar el mismo cuerpo de función escrito en dos sitios. Ningún linter lo ve —cada copia es
correcta por separado— y ninguna revisión lo caza, porque el revisor mira UN diff y las
copias nacieron en semanas distintas. El caso que lo motivó fueron tres `extension Date` en
tres view models.

Lo que **no** pretende: detección semántica. Dos funciones que hacen lo mismo escritas
distinto no se parecen para él. Y no distingue la copia deliberada de la accidental — eso lo
decide quien tiene el cambio delante, por eso avisa y no bloquea.

Lo que sí exige de sí mismo: contar una vez lo que es un fichero, y no mover su suelo de
ruido con una medición que solo cuente grupos. Las dos cosas nacen del mismo error, cometido
aquí: un recuento agregado se lee perfectamente bien mientras esconde que lo que se fue era
justo lo que había que ver.

## Requirements

### Requirement: Un fichero real cuenta una vez

El detector de lógica repetida SHALL contar una sola vez un fichero alcanzable por más de
una ruta.

1. Dos rutas que resuelven al mismo fichero real NO SHALL producir un grupo de duplicados.
2. La deduplicación SHALL hacerse por identidad del fichero, no por una lista de directorios
   excluidos escrita a mano.

Un symlink no es una copia deliberada: es el mismo fichero. Enlazar fuentes es el apaño
estándar cuando un build tool plugin de SwiftPM no puede depender de un target de librería,
así que esto reaparece en cualquier repositorio de paquetes. Medido el 2026-09-08 en
`spm-pro`: cuatro symlinks producían 21 de los 28 grupos reportados.

La 2 existe porque una lista de excepciones envejece y hay que mantenerla, y porque la
pregunta que hay que responder no es «¿ignoro este directorio?» sino «¿son dos ficheros o
uno?».

#### Scenario: Fuentes enlazadas desde un plugin de SwiftPM

- **WHEN** el detector recorre un repositorio donde un directorio de plugin enlaza las
  fuentes de un target
- **THEN** no reporta ningún grupo por esas rutas enlazadas
- **AND** sigue reportando los duplicados que sí son ficheros distintos

### Requirement: El suelo de ruido está declarado, y medido por identidad

El detector SHALL ignorar los cuerpos por debajo de un suelo de tamaño declarado, y ese suelo
SHALL ir acompañado de la medición que lo justifica.

1. El suelo SHALL estar escrito en el propio script, con su razón y su medición.
2. Un cuerpo de DOS líneas repetido en ficheros distintos NO SHALL reportarse.
3. Un cuerpo de TRES líneas repetido en ficheros distintos SÍ SHALL reportarse.
4. Toda medición que justifique mover el suelo SHALL decir QUÉ grupos cambian de lado, no
   solo cuántos.

El suelo es 3, y el intento de subirlo está medido, porque alguien lo volverá a intentar:

| suelo | falsos positivos que elimina | verdaderos que se lleva por delante |
|---|---|---|
| 3 (el que hay) | — | — |
| 4 | `ProfileLogicMock.loadProfile()` / `ProfileServiceMock.me()`, en `AppStarter` | `pascalCase()` y `displayPath()`, copiados entre `Sources/ArchInitSupport` y `Plugins/GenerateFeature` en `spm-pro` |
| 5 | los mismos | los anteriores, más `loadingView()`, `errorView()` y `emptyView()` (entre `Background.swift` y `ScreenContainer.swift`, en `iOSandbox`) y `load()` (entre `getting-started-view.swift` y `getting-started-viewmodel.swift`, en `spm-pro`) |

Subir el suelo a 4 cambia un falso positivo por dos duplicados de verdad —`pascalCase()` y
`displayPath()` son exactamente la clase que este detector existe para cazar—, y a 5, por
cinco. Mal trato las dos veces.

La tabla va con nombres y no con cuentas porque lo exige la cláusula 4, y porque la versión
que solo contaba es la que dejó pasar el error: escrita como «4 → ninguno» se leía
perfectamente bien, y era falsa.

**Nota de vocabulario, porque muerde:** «un cuerpo de N líneas» significa aquí N saltos de
línea dentro de las llaves, que son N−1 sentencias. El cuerpo de `pascalCase()` —dos
sentencias— es el que el banco y el detector llaman «de tres líneas». Spec, banco y salida
del detector usan la misma cuenta; quien cuente sentencias leerá una cosa por otra.

Así que el suelo se queda en 3 y el ruido conocido —un par de dobles de test— se asume. Y de
ahí sale la cláusula 4, que es lo más transferible de todo esto: **un recuento agregado no
dice si lo que se fue era lo que sobraba.**

#### Scenario: Dos cuerpos de dos líneas iguales

- **WHEN** dos ficheros distintos tienen el mismo cuerpo de dos líneas
- **THEN** el detector no lo reporta

#### Scenario: Un ayudante de tres líneas copiado entre dos módulos

- **WHEN** dos ficheros distintos tienen el mismo cuerpo de tres líneas
- **THEN** el detector lo reporta
