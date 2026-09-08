## ADDED Requirements

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

**Renegociado dos veces, y la segunda duele.** La primera redacción pedía no reportar «los
dobles de test que solo devuelven un valor»: semántico, y la forma obvia de cumplirlo —subir
el suelo a 5— borraba los tres hallazgos verdaderos de `iOSandbox`. Se cambió por un suelo
de 4 con esta tabla:

| suelo | falsos positivos que elimina | verdaderos que se lleva por delante |
|---|---|---|
| 3 (el que hay) | — | — |
| 4 | `ProfileLogicMock.loadProfile()` / `ProfileServiceMock.me()`, en `AppStarter` | `pascalCase()` y `displayPath()`, copiados entre `Sources/ArchInitSupport` y `Plugins/GenerateFeature` en `spm-pro` — *la primera versión de esta fila decía «ninguno»* |
| 5 | los mismos | los anteriores, más `loadingView()`, `errorView()` y `emptyView()` (entre `Background.swift` y `ScreenContainer.swift`, en `iOSandbox`) y `load()` (entre `getting-started-view.swift` y `getting-started-viewmodel.swift`, en `spm-pro`) — *este último faltaba en la primera versión de la fila* |

La fila del 4 era falsa, y lo demostró el juez de aceptación yendo a mirar **cuáles**
desaparecían en vez de cuántos: en `spm-pro`, el suelo de 4 se lleva `pascalCase()` y
`displayPath()`, copiados de verdad entre `Sources/ArchInitSupport` y
`Plugins/GenerateFeature`. Dos duplicados reales de tres líneas, que son exactamente la clase
que el detector existe para cazar, a cambio de quitarse uno falso.

La tabla va con nombres y no con cuentas porque lo exige la cláusula 4, y porque la versión
que solo contaba es la que dejó pasar el error: «4 → ninguno» se leía perfectamente bien.

**Nota de vocabulario, porque muerde:** «un cuerpo de N líneas» significa aquí N saltos de
línea dentro de las llaves, que son N−1 sentencias. El cuerpo de `pascalCase()` —dos
sentencias— es el que el banco y el detector llaman «de tres líneas». Spec, banco y salida
del detector usan la misma cuenta; quien cuente sentencias leerá una cosa por otra.

Por eso el suelo **se queda en 3** y el ruido conocido —un par de dobles de test— se asume.
Y por eso existe la cláusula 4: la medición original contaba grupos (28→5, 6→5, 3→3) y
cuadraba perfectamente sin decir nada de lo que importaba. Un recuento agregado no dice si lo
que se fue era lo que sobraba.

#### Scenario: Dos cuerpos de dos líneas iguales

- **WHEN** dos ficheros distintos tienen el mismo cuerpo de dos líneas
- **THEN** el detector no lo reporta

#### Scenario: Un ayudante de tres líneas copiado entre dos módulos

- **WHEN** dos ficheros distintos tienen el mismo cuerpo de tres líneas
- **THEN** el detector lo reporta
