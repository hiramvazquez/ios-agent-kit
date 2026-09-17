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
