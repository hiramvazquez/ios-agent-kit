# El hermano que quedaba

## Why

El cambio anterior se llama `donde-la-regla-solo-llego-a-un-hermano`, y su tesis era que los
defectos que arregló no eran reglas que faltaran sino reglas escritas en un fichero y ausentes
en su gemelo. **Cometió el mismo error.**

La auditoría encontró que el hook de contexto recorría todo
`~/Library/Developer/Xcode/DerivedData` sin filtrar, y anunciaba dependencias de otros
proyectos de la máquina. Se arregló el hook. `doc-paquetes.sh` hace **la misma búsqueda**, sin
acotar, y nadie miró.

Medido el 2026-09-08 con la 1.8.0 ya instalada y publicada:

```
$ cd spm-pro && /kit-doc
── AppFoundation
   (raíz: …/DerivedData/AppStarter-alojroukyjcwfwazufihaivukuda/SourcePackages/checkouts/AppFoundation)
```

`spm-pro` no tiene `.build/checkouts` ni DerivedData propio. Lo que se le anuncia es de
`AppStarter`. Lo mismo en `iOSandbox`.

### Por qué muerde más aquí que en el hook

La salida de `/kit-doc` termina diciendo «léelas antes de usar los tipos de un paquete» y «las
reglas de arquitectura que hacen fallar el build están ahí». En un proyecto que no es
AppStarter, eso manda leer las reglas de AppStarter. No es una línea de ruido en un digest:
es una instrucción, y es falsa.

### Por qué no lo cazó nadie

Dos filtros y los dos ciegos por la misma razón:

- **La comprobación manual sobre AppStarter pasó**, porque su DerivedData sí es el suyo: el
  resultado era correcto por casualidad.
- **`verifica-doc-paquetes.sh` fija `HOME` a un temporal vacío**, así que en las pruebas ese
  `find` no encuentra nada. Es literalmente lo que el `proposal.md` anterior escribió sobre el
  banco del hook —«su caso de aislamiento pasaba por el fixture, no por el código»— reproducido
  en el banco que ese mismo cambio creó.

## What Changes

- La resolución de «qué DerivedData es de este repositorio» **se extrae a `lib-kit.sh`** y la
  usan los dos scripts.
- `doc-paquetes.sh` deja de anunciar paquetes de proyectos cuyo nombre no case con su
  prefijo. Lo que ese acotado NO cubre queda declarado en `lib-kit.sh`.
- El banco monta un DerivedData **ajeno** bajo su `HOME` de prueba, que es el punto ciego que
  dejó pasar esto.

### La decisión de diseño

**Se extrae, no se copia.** Copiar el acotado a `doc-paquetes.sh` arreglaría el síntoma y
dejaría la misma expresión en dos sitios — que es la clase de defecto que este kit inyecta en
cada turno como regla («antes de escribir una función, busca si ya existe») y la que ya se
cobró un fallo con la resolución del cambio activo, hoy en `lib-kit.sh`. Sería la tercera vez
en la misma sesión.

`lib-kit.sh` ya existe para esto y ya tiene un precedente con la misma forma: `cambio_activo`
deja variables puestas y se llama sin subshell. La función nueva sigue ese patrón, porque
devolver un array desde una sustitución de comandos en bash 3.2 no se puede.

## Fuera de alcance

- **Mejorar la heurística.** Sigue siendo casar el nombre de la carpeta del repositorio con el
  prefijo `<Proyecto>-` de DerivedData. Este cambio la mueve de sitio y la aplica donde
  faltaba; no la hace más lista. Sus límites no cambian, pero su DECLARACIÓN sí crece: el
  tercero —un vecino que se llame como tú más un guion se cuela— no estaba escrito en ningún
  sitio, lo encontró el revisor, y ahora está en `lib-kit.sh` y en el requisito.
- **Auditar los demás scripts** buscando terceras copias de esta u otras clases. Es otro
  trabajo y merece su propio cambio.
- **`inyecta-contexto.sh` cambia solo para llamar a la función extraída.** Su comportamiento
  no se toca: el digest sale igual. Lo que sí se toca es su **spec**: prometía un acotado
  absoluto que el código nunca dio, y dejarla así al archivar sería plantar la norma falsa
  sobre la misma función que este cambio acaba de compartir.

## Criterios de aceptación

- [x] La resolución del DerivedData propio SHALL existir una sola vez en el código, y los dos
      scripts que la necesitan SHALL usarla.
- [x] En un repositorio sin `.build/checkouts` y sin ningún DerivedData que case con su
      prefijo, `doc-paquetes.sh` NO SHALL anunciar paquetes de otro proyecto de la máquina.
- [x] El límite del acotado por prefijo SHALL estar declarado donde vive la resolución y en el
      requisito, y **ningún documento ni spec del kit SHALL prometer una garantía de acotado
      que el código no dé** — se dijera con la frase «falla hacia el lado seguro» o con
      cualquier otra. Escrito en términos de lo que se promete y no de cómo se escribe, porque
      la primera versión de este criterio hablaba de la frase y por ese hueco se coló la spec
      de `contexto-inyectado`, que promete algo más fuerte sin usarla.
- [x] En un repositorio CON DerivedData propio, `doc-paquetes.sh` SHALL seguir anunciando los
      suyos, igual que antes de este cambio.
- [x] El banco de `doc-paquetes.sh` SHALL montar un DerivedData ajeno bajo su `HOME` de
      prueba, y ese caso SHALL salir en rojo contra la 1.8.0.
- [x] El digest de `inyecta-contexto.sh` SHALL salir idéntico a como sale hoy.
- [x] `/kit-verifica` SHALL salir en verde y `autocomprueba.sh` limpio.
