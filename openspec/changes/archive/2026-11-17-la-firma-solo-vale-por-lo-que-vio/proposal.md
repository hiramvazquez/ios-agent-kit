# La firma solo vale por lo que vio

## Why

Tres fallos reproducidos en repositorios temporales el 2026-11-17, los tres en la pieza que
decide si se puede commitear:

1. **Una verificación en rojo se acepta como verde.** Quien juzga la firma busca
   `resultado: verde` en el fichero entero, y debajo de la cabecera va el informe, que copia
   la salida de los pasos que fallan. Un test que imprime esa línea y falla deja la firma con
   `resultado: rojo` arriba y `resultado: verde` abajo, y la puerta deja pasar el commit.
2. **Se firma un árbol que los pasos no vieron.** La foto se toma después de correr
   `verificaciones()`. Si el árbol cambia mientras tanto —otra sesión, un formateador, el
   propio agente—, la firma vale para un árbol que nadie probó.
3. **Un duplicado en un fichero nuevo se da por preexistente.** La lista de ficheros tocados
   sale de `git diff`, que no ve lo que está sin trackear: la copia recién escrita en un
   fichero nuevo se resume como «sin relación con este cambio».

## What Changes

- La firma se juzga leyendo solo su cabecera, en los tres sitios donde se juzga.
- `verifica.sh` fotografía el árbol antes y después de los pasos. Si las fotos difieren, la
  verificación sale en rojo y dice qué rutas cambiaron.
- Los ficheros sin trackear que git no ignora cuentan como tocados para el detector, y salen
  en el aviso de lo que falta por stagear.

## Fuera de alcance

- El detector no aprende a leer firmas en varias líneas ni `init`.
- La puerta no pasa a verificar el contenido del commit: sigue comprobando que el árbol es el
  verificado y que el índice no lleva otra cosa.
- Los ficheros trackeados que casan con `.gitignore`, el clon sin puerta y `--informe`.
- Las instrucciones de los comandos y de los agentes.

## Criterios de aceptación

- [x] Una verificación en rojo cuyo paso imprime `resultado: verde` NOT SHALL dar firma
      válida: ni `--comprueba`, ni el hook de commit, ni el digest. Fijado por casos de banco
      que salen rojos contra el código anterior.
- [x] Un árbol que cambia mientras corren los pasos SHALL dejar la verificación en rojo, con
      las rutas que cambiaron en el informe. Fijado por un caso de banco.
- [x] Un árbol que no cambia SHALL seguir firmándose en verde: los bancos existentes pasan sin
      tocar sus aserciones.
- [x] Un cuerpo repetido en un fichero nuevo sin trackear SHALL reportarse entero, no contarse
      como preexistente. Fijado por un caso de banco.
- [x] El aviso de árbol sucio SHALL nombrar también los ficheros sin trackear.
