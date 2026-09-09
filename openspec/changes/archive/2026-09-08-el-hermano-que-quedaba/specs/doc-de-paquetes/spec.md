# doc-de-paquetes — delta

## ADDED Requirements

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
   `spm-pro-<hash>`. Ese límite SHALL estar declarado donde vive la resolución, y ningún
   documento, spec, comentario ni mensaje de prueba del kit SHALL **prometer una garantía de
   acotado más fuerte que la que el código da** — se diga con la frase «falla hacia el lado
   seguro» o con cualquier otra.

   La cláusula está escrita en términos de lo que se promete y no de cómo se escribe: la
   primera versión prohibía una FRASE, y por ese hueco pasaron instancias que decían lo mismo
   con otras palabras. Es la trampa léxico-semántica que el prompt del juez ya tiene escrita
   para los censos, aplicada a una promesa.

5. **Y la forma que lo hace sostenible: la lista de límites vive en UN solo sitio —donde vive
   la resolución— y toda otra mención de la garantía SHALL llevar su límite al lado o apuntar
   ahí. Lo que NO se admite es el absoluto suelto**: afirmar la exclusión sin la premisa que
   la hace cierta y sin decir dónde está la lista.

   La 5 no es estilo, es lo único que corta el problema, y sale de haberlo medido: el juez de
   aceptación contó nueve instancias de esta promesa a lo largo de cinco rondas, y **cinco
   estaban en texto escrito por el arreglo de la ronda anterior** — una dentro del arreglo de
   otra, dos veces. Cazarlas de una en una no converge, porque cada arreglo vuelve a
   reformular la garantía y reformularla es lo que fabrica la instancia siguiente. Es un paseo
   aleatorio, no una búsqueda.

   Una sola declaración no puede desincronizarse consigo misma; nueve paráfrasis sí. Es
   exactamente la tesis de este cambio —extraer en vez de copiar— aplicada a la prosa, y hace
   falta escribirlo porque no lo comprueba nadie: `autocomprueba.sh` solo lintea recuentos de
   piezas del kit, y esta clase le pasa por delante.

   El borde importa tanto como la regla, y son dos. **Los enunciados de propósito** —«los
   paquetes de los que depende este proyecto»— quedan fuera: dicen para qué existe una pieza,
   no qué excluye. Y **explicar la garantía no es parafrasearla**: `README.md` y
   `docs/PIEZAS.md` la enuncian, nombran el límite y apuntan a la lista, y así deben seguir —
   un documento de usuario que solo dijera «mira `lib-kit.sh`» no le sirve a nadie.

   Esa segunda mitad también salió de medirla, y con vergüenza: la primera versión de esta
   cláusula decía «apuntar **en vez de** parafrasear», y con ella `README.md` y
   `docs/PIEZAS.md` pasaban a ser infractores. Una norma escrita para cortar la deriva, y
   estrenada convirtiendo en infractores a los dos documentos que mejor la cumplen. Es la
   misma clase que las nueve instancias —un predicado más ancho que la realidad— cometida en
   la propia cláusula que venía a cerrarla.

La 4 no es una excusa: es la diferencia entre esta norma y una que el código no cumple. La
primera versión de este requisito decía «los paquetes que **pertenecen** al repositorio», un
absoluto que el acotado por prefijo rompe — y al archivarse habría quedado como norma
permanente que nadie iba a volver a medir. Lo cazó el juez de aceptación reproduciéndolo con
un repositorio `sinada` y un vecino `sinada-pro`.

Tiene su gracia amarga, y por eso se escribe: el `Why` de este cambio usa el par
`spm` / `spm-pro` como prueba del defecto que viene a cerrar, y ese par es exactamente el que
su arreglo sigue dejando pasar, con los nombres al revés.

Arreglar el acotado de verdad —exigir la forma del hash, o leer el `info.plist` de cada
carpeta— es otra decisión con su propia medición, y este cambio la declara fuera de alcance.
Lo que no se puede es prometer lo que no se hace.

La 3 es la que impide que esto vuelva. Este mismo defecto se arregló en
`inyecta-contexto.sh` en el cambio anterior y se dejó aquí, porque la expresión vivía en dos
sitios y solo se miró uno. Copiarla ahora al segundo la dejaría en dos sitios otra vez, que es
la clase que ya se cobró un defecto con la resolución del cambio activo — hoy en `lib-kit.sh`
por la misma razón.

Muerde más aquí que en el hook: la salida de este script manda leer las reglas de los paquetes
que anuncia, así que anunciar los de otro proyecto no es ruido, es una instrucción falsa.
Medido el 2026-09-08 con la 1.8.0 instalada: `spm-pro` e `iOSandbox`, sin dependencias propias
resueltas, recibían las de `AppStarter`.

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
