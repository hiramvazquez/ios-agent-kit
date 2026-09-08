# Tareas

Un solo fichero y una sola sección. Por la tabla de `docs/FLUJO.md` este cambio podría
saltarse esta lista; va porque el esquema del CLI la pide para `apply`.

- [x] 1. **Reescribir la sección «Tope» de `agents/aceptacion.md`** con las tres salidas, cada
      una con su causa. La tercera, con sus tres condiciones: para igual que las otras,
      obliga a descartar las dos primeras con la comprobación hecha, y exige evidencia por
      cada error de hecho.

- [x] 2. **Escribir la regla de «ninguna encaja»** en esa misma sección: decirlo y describir
      lo que se ve. Es lo único que no es «una salida más», y es lo que hace que la plantilla
      ayude a parar en vez de obligar a mentir.

- [x] 3. **Dejar el caso del 2026-09-08 junto a la regla**, con lo que el juez midió para
      descartar las dos salidas viejas — el mismo sitio y la misma forma que el caso que ya
      está ahí, el que desmintió al tope por vueltas.

- [x] 4. **Declarar el límite en el propio fichero**: nada mecánico comprueba que un juez
      obedezca esta sección. `autocomprueba.sh` mira frontmatter y rutas; lo que la sección
      dice no lo verifica nadie.

- [x] 6. **De la revisión (AMBER, 2026-09-08).** El revisor encontró que la cuarta vía —«si
      ninguna encaja»— era la única que **no decía si para**, siendo la más abusable: las tres
      etiquetas llevan «y para», ella no. Y trajo el caso que lo rompe, sacado de este mismo
      fichero: si el tope se alcanza y en esa ronda aparece un bug de código, ninguna de las
      tres encaja, y el documento no decía si el juez emite veredicto o entrega el bug al
      owner. Las dos lecturas cuestan.

      Cerrado por los dos lados: la cuarta vía ahora dice **«dilo, descríbelo y para igual,
      sin veredicto»**, y se añade lo que faltaba antes de llegar ahí — si lo encontrado hace
      tocar código, **el tope no aplica**, porque esa ronda no es «sin hallazgos» y el contador
      vuelve a cero; lo que toca es un veredicto normal. El delta gana la cláusula 6 y un
      escenario para ese caso.

      Y dos de sus tres opcionales: «tres ediciones de una línea» eran tres errores en cuatro
      sitios —el «seis versiones» estaba copiado en dos—, y el ejemplo «un número que ya no
      cuadra» ahora avisa de que un censo a mano no es solo un error de hecho, sino la forma
      que este mismo documento prohíbe. El tercero se cerró solo: el puntero posicional a «la
      última línea de este documento» desapareció al reescribir el párrafo, sustituido por la
      regla citada.

- [x] 7. **Del juez (DEVUELTO, 2026-09-08).** Dos afirmaciones falsas en el fichero
      entregado, las dos de la clase exacta que la sección nueva acaba de nombrar, y una
      provocada por el arreglo de la revisión anterior:

      1. El **límite declarado decía de más**: «lo que dice, no lo verifica nadie», cuando
         `autocomprueba.sh` sí lintea `agents/*.md` buscando censos a mano — justo la trampa
         que el tercer punto acababa de señalar. El fichero avisaba de una trampa y dos
         párrafos después declaraba que nadie la vigila. Corregido aquí y en el `proposal.md`,
         de donde se heredaba.
      2. «La tercera salida y **el párrafo de arriba**» dejó de apuntar a lo que apuntaba
         cuando el arreglo del hallazgo del revisor —el párrafo de «si toca código, el tope no
         aplica»— se insertó entre la regla y el caso. Es literalmente el ejemplo que el
         tercer punto pone: *un puntero a algo que se movió*. Ahora nombra la regla en vez de
         su posición, que es lo mismo que ya se hizo con «la última línea de este documento».

      El juez juzgó además desde la versión ANTERIOR de este mismo fichero —los sub-agentes
      cargan su prompt del plugin instalado, y el cambio está sin publicar—, así que leyó lo
      entregado en el árbol en vez de sus propias instrucciones. Lo dijo él.

- [x] 8. **Del juez, segunda ronda (DEVUELTO, 2026-09-08).** El mismo error girado: la ronda
      anterior arregló un límite que decía **de menos**, y el arreglo lo dejó diciendo **de
      más** — en el único párrafo cuyo trabajo es acotar con precisión. El juez midió las tres
      afirmaciones del lint que yo daba por buenas, y las tres se caían:

      1. **No lee acuerdos.** Sus globs son `README.md`, `docs/*.md`, `agents/*.md`,
         `commands/*.md` y `skills/*/SKILL.md`; `openspec/**` no entra. O sea que el censo a
         mano dentro de un acuerdo —que es exactamente el que la tercera salida manda mirar—
         no lo caza. Contó los que viven ahí hoy con el lint en verde.
      2. **No es «un censo», son las piezas del kit.** Su patrón es
         `skills|agentes|hooks|comandos|scripts|casos`: «las nueve pantallas», que es el
         ejemplo de la sección de más abajo, le pasa por delante.
      3. **Fuera de este repo no corre.** Es un paso del `kit.conf` propio del kit y no está
         en `plantillas/kit.conf.ejemplo`, la que se instala en los proyectos — y este prompt
         sí viaja a esos proyectos.

      El límite dice ahora las tres cosas, y acaba donde tenía que acabar: **el censo a mano
      dentro de un acuerdo lo cazas tú o no lo caza nadie.** Corregido también en el
      `proposal.md`, que era de donde se heredaba.

      Y su observación, aceptada sin discusión: «la trampa del **tercer punto**» era otro
      puntero posicional —la forma que este mismo cambio señala como error de hecho— y competía
      con otras dos listas numeradas del fichero. Fuera.

- [x] 5. **Cierre:** `git diff agents/aceptacion.md` no toca ninguna otra sección,
      `/kit-verifica` en verde, y `/kit-revisa` sobre la rodaja — 156 líneas, la primera de
      toda esta tanda con el tamaño que el revisor pide, y encontró justo lo que una rodaja
      así encuentra: un caso concreto en el que lo que el cambio afirma es falso. El juez de
      este cambio será el primero que corra con la sección nueva delante.
