## 1. La ruta se resuelve como la resolvería el shell

- [x] 1.1 Añadir a `verifica-puerta.sh` los casos `cd ~/…`, `cd $HOME/…` y `cd ~usuario/…`
      sobre un repositorio con `kit.conf` y sin firma. Verificación: los tres FALLAN antes de
      tocar el analizador — si pasaran, la prueba no estaría probando nada.
- [x] 1.2 Expandir la pista en `analiza-invocacion.py` con `expandvars` y luego `expanduser`.
      **Hecho**: `expandir()` en el analizador, aplicada a la pista del `cd` y a los valores
      de `-C`/`--git-dir`. Variables primero y `~` después, porque al revés un `$HOME/...`
      sin expandir no empieza por `~` y `expanduser` no haría nada.
- [x] 1.3 Comprobar que una ruta construida en ejecución sigue cayendo al fallo abierto, y
      que ese límite sigue escrito en la cabecera de `puerta-commit.sh`. Verificación: el
      **Hecho**: el caso `D=…; cd $D && git commit` pasa (fallo abierto), y la cabecera lo
      nombra explícitamente junto a los demás límites.

## 2. El salto de línea separa comandos

- [x] 2.1 Añadir a `verifica-puerta.sh` el caso `cd <ruta>` en una línea y `git commit` en la
      siguiente. Verificación: FALLA antes de tocar el analizador.
- [x] 2.2 Que un `cd` deje de descartar el resto de su segmento (ver D2 enmendada: partir
      por líneas habría roto el caso del heredoc). Verificación: el caso de 2.1 pasa a
      **Hecho**: tras un `cd` el escaneo avanza en el mismo segmento en vez de abandonarlo.
      El caso del heredoc sigue pasando, que era el motivo de descartar partir por líneas.
- [x] 2.3 Retirar `"\n"` de `SEPARADORES`, que ya no le llega, para que la constante no
      enumere lo que no cubre (punto 7 del requisito). **Hecho**, con un comentario que
      explica por dónde SÍ queda cubierto el caso.

## 3. Que las pruebas sepan fallar

- [x] 3.1 Revertir cada arreglo por separado y comprobar que su prueba se pone roja.
      **Hecho, y separan limpio**: quitando la expansión → rojos los dos casos de ruta, verde
      el del salto. Devolviendo el `break` tras el `cd` → rojo solo el del salto. Cada arreglo
      sostiene su propia prueba y ninguna cubre por accidente a la otra.
- [x] 3.2 La suite entera de `verifica-puerta.sh` en verde, con los casos que ya cubría.
      **30 casos en verde**, de 24 que había antes de este cambio (6 nuevos: tres de ruta,
      dos de salto de línea y uno que fija el límite que sigue abierto).

## 4. Decir lo que ahora cubre

- [x] 4.1 Actualizar la cabecera de `puerta-commit.sh`: lo que cubre y lo que no, con las
      formas nuevas. **Hecho**: la cabecera nombra el `cd` en línea aparte, la expansión de
      `~` y variables, y el límite de la ruta construida en ejecución.
- [x] 4.2 `/kit-verifica` en verde.

## 5. Cierre del revisor (AMBER, 2026-09-16)

- [x] 5.1 **El arreglo cubría menos de lo que el spec prometía.** Tras el `cd`, el escaneo
      paraba en el primer token que no fuera `git commit`, así que `cd X` + `git add -A` +
      `git commit` en tres líneas pasaba sin comprobar nada. Y medido al verificarlo: `git
      add -A` + `git commit` en dos líneas **sin** `cd` tampoco comprobaba el repo de la
      sesión —preexistente, y la forma más común de escribir un commit—. Ahora, tras un `cd`
      o un subcomando de git, el escaneo busca el siguiente inicio de comando conocido en el
      mismo segmento. Verificación: 3 casos nuevos en el banco, los tres bloqueando.
- [x] 5.2 **El límite que queda, declarado y con prueba**: un comando que no es de git entre
      el `cd` y el commit cae al directorio heredado. No se cubre porque dentro de un segmento
      no se distingue un nombre de comando de un argumento, y partir por líneas rompería el
      caso del heredoc. Verificación: caso en el banco que lo fija como «pasa», y la cabecera
      del hook lo explica.
- [x] 5.3 **`~usuario` se afirmaba probado y no lo estaba.** El comportamiento funciona, pero
      `expanduser` lo resuelve por la base de datos de usuarios y no por `$HOME`, así que el
      truco del banco no sirve y probarlo exigiría escribir en el home real. Criterio de
      aceptación corregido y dicho en el spec, en vez de dejar creer que hay una prueba.
- [x] 5.4 **Control contra el montaje**, que el revisor echó de menos: con `HOME` apuntado al
      banco y ruta absoluta a un repo FIRMADO, la puerta pasa. Si `HOME=$TMP` rompiera
      `verifica.sh`, los dos «bloquea» de las rutas bloquearían por el montaje y no por el
      fallo. Verificación: caso 31 del banco.
- [x] 5.5 El banco pasa de 30 a 35 casos, todos en verde.

## 6. Cierre del juez (DEVUELTO, 2026-09-16)

- [x] 6.1 **El arreglo de 5.1 introdujo una regresión, y de la peor clase.**
      `siguiente_comando()` saltaba hacia delante sobre tokens arbitrarios, así que tras un
      `git add` entraba en el cuerpo de un heredoc o en los argumentos de un `grep`/`echo` y
      encontraba un `git commit` que nadie iba a ejecutar. Medido: `git status` + `grep -rn
      git commit .` → bloqueaba. **Un bloqueo falso es peor que el agujero**: deja la sesión
      inservible para comandos legítimos, que es el fallo que costó arreglar el
      reconocimiento por subcadena. Y rompía justo el caso que la enmienda D2 protegía.
- [x] 6.2 **Tercera versión de D2, escrita antes de tocar código (D2bis).** La causa de las
      tres vueltas era la misma: dentro de un segmento no se sabe dónde acaba un comando,
      porque `shlex` se come el salto de línea. En vez de adivinarlo, se conserva la
      información antes de perderla: el comando se parte en líneas lógicas ANTES de tokenizar
      y los cuerpos de heredoc se descartan por su delimitador, como hace el shell.
      Verificación: `siguiente_comando()` e `INICIOS` retirados; el analizador es más corto.
- [x] 6.3 **Cubre más de lo que se declaraba como límite.** `cd X` + un comando cualquiera +
      `git commit` ya se bloquea, y `swift build` + `git add` + `git commit` también — que no
      lo cubría ninguna versión anterior. La prueba que fijaba ese límite pasa a fijar la
      cobertura, y el spec y la cabecera se ajustan a lo que hace.
- [x] 6.4 **Tres casos de no-regresión** para lo que rompió 5.1: heredoc suelto, heredoc tras
      un `git add`, y `grep` tras un `git status`. Verificación: banco de 35 a 38 casos.
- [x] 6.5 El escenario del spec decía «cae al directorio heredado» y el código no comprueba
      nada cuando no reconoce un commit. Corregido: ese escenario desaparece porque el caso
      ya está cubierto, y el fallo abierto que queda —ruta construida en ejecución— sigue
      dicho donde estaba.
