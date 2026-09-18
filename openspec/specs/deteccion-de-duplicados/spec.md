# deteccion-de-duplicados Specification

## Purpose

Cazar el mismo cuerpo de función escrito en dos sitios: ningún linter lo ve —cada copia es
correcta por separado— y ninguna revisión lo caza, porque el revisor mira UN diff y las copias
nacen en semanas distintas. Lo que sí exige de sí mismo: contar una vez lo que es un fichero, y
no mover su suelo de ruido con una medición que solo cuente grupos.

Lo que **no** pretende: detección semántica —dos funciones que hacen lo mismo escritas distinto
no se parecen para él— ni distinguir la copia deliberada de la accidental, que la decide quien
tiene el cambio delante; por eso avisa y no bloquea.

## Requirements

### Requirement: Un fichero real cuenta una vez

El detector de lógica repetida SHALL contar una sola vez un fichero alcanzable por más de
una ruta.

1. Dos rutas que resuelven al mismo fichero real NO SHALL producir un grupo de duplicados.
2. La deduplicación SHALL hacerse por identidad del fichero, no por una lista de directorios
   excluidos escrita a mano.

Un symlink no es una copia deliberada: es el mismo fichero. Enlazar fuentes es el apaño
estándar cuando un build tool plugin de SwiftPM no puede depender de un target de librería,
así que esto reaparece en cualquier repositorio de paquetes.

La 2 existe porque una lista de excepciones envejece y hay que mantenerla, y porque la
pregunta que hay que responder no es «¿ignoro este directorio?» sino «¿son dos ficheros o
uno?».

#### Scenario: Fuentes enlazadas desde un plugin de SwiftPM

- **WHEN** el detector recorre un repositorio donde un directorio de plugin enlaza las
  fuentes de un target
- **THEN** no reporta ningún grupo por esas rutas enlazadas
- **AND** sigue reportando los duplicados que sí son ficheros distintos

### Requirement: El suelo de ruido está declarado, y medido por identidad

El detector SHALL ignorar los cuerpos por debajo de **dos** suelos declarados —uno de tamaño
en líneas y otro de tamaño en caracteres normalizados—, y los dos SHALL ir acompañados de la
razón que los justifica.

1. Los dos suelos SHALL estar escritos en el propio script, cada uno con su razón. El de
   líneas SHALL llevar además la medición que lo fija.
2. Un cuerpo de DOS líneas repetido en ficheros distintos NO SHALL reportarse.
3. Un cuerpo de TRES líneas **que supere el suelo de caracteres** repetido en ficheros
   distintos SÍ SHALL reportarse.
4. Toda medición que justifique mover cualquiera de los dos suelos SHALL decir QUÉ grupos
   cambian de lado, no solo cuántos.

Los suelos son **3 líneas** y **60 caracteres normalizados**. «Un cuerpo de N líneas» significa
N saltos de línea dentro de las llaves, que son N−1 sentencias; spec, banco y salida del
detector usan la misma cuenta.

El intento de subir el suelo de líneas está medido, porque alguien lo volverá a intentar:

| suelo | falsos positivos que elimina | verdaderos que se lleva por delante |
|---|---|---|
| 3 (el que hay) | — | — |
| 4 | `ProfileLogicMock.loadProfile()` / `ProfileServiceMock.me()`, en `AppStarter` | `pascalCase()` y `displayPath()`, copiados entre `Sources/ArchInitSupport` y `Plugins/GenerateFeature` en `spm-pro` |
| 5 | los mismos | los anteriores, más `loadingView()`, `errorView()` y `emptyView()` (entre `Background.swift` y `ScreenContainer.swift`, en `iOSandbox`) y `load()` (entre `getting-started-view.swift` y `getting-started-viewmodel.swift`, en `spm-pro`) |

Medido el 2026-09-08. Subir a 4 cambia un falso positivo por dos duplicados de verdad; a 5, por
cinco. La tabla va con nombres y no con cuentas porque lo exige la cláusula 4: un recuento
agregado no dice si lo que se fue era lo que sobraba.

#### Scenario: Dos cuerpos de dos líneas iguales

- **WHEN** dos ficheros distintos tienen el mismo cuerpo de dos líneas
- **THEN** el detector no lo reporta

#### Scenario: Un ayudante de tres líneas copiado entre dos módulos

- **WHEN** dos ficheros distintos tienen el mismo cuerpo de tres líneas, por encima del suelo
  de caracteres
- **THEN** el detector lo reporta

#### Scenario: Un cuerpo de tres líneas por debajo del suelo de caracteres

- **WHEN** dos ficheros distintos tienen el mismo cuerpo de tres líneas y menos caracteres
  normalizados que el suelo
- **THEN** el detector no lo reporta
- **AND** el suelo que lo explica está escrito en el script
