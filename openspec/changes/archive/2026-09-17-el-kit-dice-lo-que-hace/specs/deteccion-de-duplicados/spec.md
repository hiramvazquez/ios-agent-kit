## MODIFIED Requirements

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
