# deteccion-de-duplicados — delta

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
5. Este cambio NO SHALL mover ninguno de los dos.

Los suelos son **3 líneas** y **60 caracteres normalizados**, y hasta hoy la spec solo hablaba
del primero. Por el segundo, un ayudante real de tres líneas copiado en dos ficheros **no se
reporta**, lo que hacía falsa la cláusula 3 tal como estaba escrita y su escenario con ella.
El caso está montado en `verifica-duplicados.sh`, y va ahí y no como número en esta prosa a
propósito: la primera versión de esta frase citaba una medición sobre un cuerpo que no estaba
en ningún fixture, así que nadie podía reproducirla. Un número con fecha y sin fixture
envejece igual que uno sin fecha.

**Se renegocia el acuerdo y no se toca el comportamiento**, con tres razones. El suelo de 60
lleva ahí desde el principio y filtra la coincidencia trivial, que es ruido y no duplicación.
`docs/PIEZAS.md` ya lo documentaba con su número, así que el kit lo conocía y se lo contaba a
quien lo instala: lo que faltaba era el acuerdo, no el conocimiento. Y quitarlo cambiaría el
detector en proyectos reales sin medición previa, que es justo lo que la cláusula 4 prohíbe —
moverlo hoy sería romper esa cláusula para cumplir la 3.

Lo que no se acepta es que un suelo viva sin declarar. La cláusula 1 ya lo exigía y el de 60
no tenía ni comentario: estaba en la documentación de cara al usuario y ausente del sitio
donde lo lee quien va a tocarlo.

El intento de subir el suelo de líneas está medido, porque alguien lo volverá a intentar:

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

Así que los suelos se quedan donde estaban y el ruido conocido —un par de dobles de test— se
asume. Y de ahí sale la cláusula 4, que es lo más transferible de todo esto: **un recuento
agregado no dice si lo que se fue era lo que sobraba.**

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
