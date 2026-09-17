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

## 7. Segundo cierre del juez (DEVUELTO, 2026-09-16)

- [x] 7.1 **El banco no probaba el mensaje del commit.** Los 29 casos usaban `-m x`, así que
      un `git commit -m "titulo⏎⏎cuerpo"` —la forma en que se commitea este repositorio— no
      estaba cubierto, y el tercer intento lo dejó invisible. Cinco casos nuevos ANTES de
      arreglar nada: mensaje con cuerpo, `-F -` con heredoc, `echo` multilínea, here-string y
      `<<EOF` entre comillas. Verificación: 4 de 43 en rojo antes del arreglo.
- [x] 7.2 **Cuarta versión de D2 (D2ter), escrita antes de implementar.** Las tres anteriores
      reconstruían las fronteras de los comandos después de que `shlex` se comiera los saltos.
      `shlex` no las había perdido: expone `lineno` y maneja las comillas. Ahora se leen de
      ahí. Verificación: los 43 casos en verde.
- [x] 7.3 **Comparadas las cuatro versiones sobre 15 formas de comando**: la actual acierta
      las 15; original, 2º y 3º fallan al menos dos cada una. Verificación: la tabla está en
      el mensaje del commit.
- [x] 7.4 Se retiran `lineas_logicas()` sobre texto crudo y la constante `HEREDOC`. El
      analizador queda del tamaño del original con el doble de casos cubiertos.

## 8. Tercer DEVUELTO: se para y se revierte (2026-09-16)

- [x] 8.1 **Las cinco reproducciones del juez, confirmadas midiéndolas.** La peor: una LÍNEA
      EN BLANCO delante del commit desactiva la puerta. `tokens_con_linea` lee `lex.lineno`
      antes de pedir el token, y el salto se consume dentro de esa llamada, así que con una
      línea vacía por medio `git` y `commit` caen en grupos distintos. Pulsar Enter una vez
      es más barato que el agujero original, que pedía escribir la ruta con `~`.
      Además: un cuerpo de heredoc que mencione su propio delimitador vuelve a bloquear en
      falso —le pasó al juez EN VIVO al escribir sus sondas—, y `<<-EOF` o un apóstrofo en
      el cuerpo se tragan el commit posterior.
- [x] 8.2 **Se revierte `analiza-invocacion.py` y la cabecera de `puerta-commit.sh` al estado
      de `022b5fd`.** Queda el agujero conocido (`~` sin expandir, `add`+`commit` en líneas
      distintas) y NINGUNA regresión ni bloqueo falso. Dejar `main` con una puerta que se
      apaga pulsando Enter era peor.
- [x] 8.3 **El banco vuelve a sus 24 casos**, porque `kit.conf` lo corre como paso bloqueante
      y un banco con rojos pendientes impide commitear — es su diseño: las pruebas y su
      arreglo aterrizan juntos. Los 19 casos escritos en estas rondas quedan aquí abajo para
      que el próximo intento empiece por ponerlos, que es lo único que no hay que volver a
      pensar.

### Los 19 casos, para el próximo intento

```bash
espera_home bloquea "$TMP/kit_firmado" "cd ~/kit_sin_firma && git $C -m x" \
espera_home bloquea "$TMP/kit_firmado" 'cd $HOME/kit_sin_firma && git '"$C"' -m x' \
espera_home pasa    "$TMP/kit_sin_firma" "cd ~/kit_firmado && git $C -m x" \
espera pasa "$TMP/kit_sin_firma" "cd $TMP/kit_firmado
espera bloquea "$TMP/kit_sin_firma" "git add -A
espera bloquea "$TMP/kit_sin_firma" "git $C -m \"titulo
espera bloquea "$TMP/kit_sin_firma" "git $C -F - <<EOF
espera pasa "$TMP/kit_sin_firma" "echo \"documentación:
espera_home pasa "$TMP/kit_sin_firma" "cd $TMP/kit_firmado && git $C -m x" \
espera pasa "$TMP/kit_firmado" "D=$TMP/kit_sin_firma; cd \$D && git $C -m x" \
espera pasa "$TMP/kit_sin_firma" "cat > /tmp/nota.md <<EOF
espera pasa "$TMP/kit_sin_firma" "git add -A
espera pasa "$TMP/kit_sin_firma" "git status
```

Y el que de verdad faltaba, el que hizo invisible el agujero grave durante dos rondas: el
banco no probaba NINGÚN mensaje de commit con cuerpo — los 24 usan `-m x`.

## 9. Lo que queda decidido para quien siga

Cuatro intentos, cuatro veredictos: AMBER, DEVUELTO, DEVUELTO, DEVUELTO. Cada ronda el banco
creció, cada ronda quedó verde, y cada ronda el analizador perdió un caso que la versión
anterior acertaba. Eso no es «quedan flecos»: es la firma de escribir a mano el lexer de un
lenguaje que tiene sintaxis de verdad.

La pregunta que ya no decide otra ronda de arreglos —y que el juez formuló mejor que yo— es
si un analizador sintáctico de shell dentro del hook es la forma correcta del problema. Las
dos salidas que no son otro parche:

- **Un parser de shell de verdad** (`bashlex` o equivalente). Hoy el plugin no tiene ninguna
  dependencia fuera de la stdlib, así que es una decisión de arquitectura, no de código.
- **Cambiar la forma del problema**: que la puerta deje de deducir el repositorio del texto
  del comando. Comprobar siempre el repositorio heredado y, aparte, `-C`/`--git-dir`, que
  son inequívocos. Cubre menos casos pero ninguno adivinando.
