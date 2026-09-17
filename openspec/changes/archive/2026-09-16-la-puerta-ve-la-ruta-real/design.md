## Context

Ver `proposal.md` — Why. Lo medido, con el comando que lo mide, para que se pueda repetir:

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"cd ~/repo && git commit -m x"}}' \
  | bash scripts/puerta-commit.sh     # no imprime nada → pasa
```

Y la causa del segundo caso, en el propio analizador:

```python
shlex.shlex("cd /tmp\ngit commit -m x", posix=True, punctuation_chars=True)  # whitespace_split
# → ['cd', '/tmp', 'git', 'commit', '-m', 'x']   ← el "\n" no aparece
```

## Goals / Non-Goals

**Goals**
- Que la puerta resuelva la ruta como la resolvería el shell que va a ejecutar el comando.
- Que el código y la norma digan lo mismo sobre el salto de línea.

**Non-Goals**
- Ampliar la cobertura más allá de eso. Los límites declarados siguen donde están.
- Interpretar rutas que solo existen en tiempo de ejecución. Eso es fallo abierto por diseño.

## Decisions

### D1. Expandir con `expanduser` + `expandvars`, en el analizador y no en el hook

La expansión va donde se decide la pista —`analiza-invocacion.py`—, no en el shell que la
consume. Si viviera en `puerta-commit.sh` habría que repetirla en cada sitio que use una
ruta, y la siguiente vía de entrada volvería a olvidarla.

*Orden:* primero variables, después `~`. Al revés, `$HOME` sin expandir haría que
`expanduser` no vea un `~` inicial y la ruta siguiera sin resolver.

*Alternativa descartada — pasar la cadena a `os.path.realpath` y confiar:* no expande `~` ni
variables; habría dado la misma falsa sensación de arreglo.

*Límite que se mantiene:* una ruta construida en ejecución (`$(...)`, una variable definida
en el mismo comando) sigue sin resolverse, y sigue siendo fallo abierto declarado.

### D2. Que un `cd` deje de comerse el resto de su segmento

*Enmendada el 2026-09-16, antes de implementar.* La primera versión decía «partir el comando
por líneas antes de tokenizar». **Habría roto un caso que el banco ya cubre**: el heredoc

```
cat > /tmp/x <<'EOF'
git commit va aquí dentro
EOF
```

Partido por líneas, la segunda línea ES un `git commit` a ojos del analizador, y ese caso
—que existe porque fue el fallo que destapó el reconocimiento por subcadena— pasaría de
«pasa» a «bloquea». Tokenizar la cadena entera es lo que mantiene el cuerpo del heredoc
pegado a su `cat`, y eso hay que conservarlo.

El arreglo real es más pequeño y está en otro sitio: cuando el analizador ve un `cd`, anota
la pista y hace `continue`, **descartando el resto del segmento**. Como `shlex` se come el
salto de línea, el `git commit` de la línea siguiente vive en ese resto. Basta con seguir
examinando el segmento después del `cd` en vez de abandonarlo.

*Por qué no genera falsos positivos:* solo se sigue escaneando después de un `cd`/`pushd`.
Un `echo git commit` sigue parándose en `echo`, que es lo que hace pasar los casos de texto.

### D2bis. Separar por líneas de verdad, saltando los cuerpos de heredoc

*Enmendada el 2026-09-16, tras el DEVUELTO del juez.* Las dos versiones anteriores de D2 eran
insuficientes o peores:

- «No abandonar el segmento tras un `cd`» cubría solo el commit INMEDIATAMENTE siguiente. Con
  un `git add` por medio —la forma normal— seguía pasando sin comprobar nada.
- «Buscar el siguiente inicio de comando saltando tokens» (lo que se implementó para cerrar
  eso) **rompió el caso que D2 existía para proteger**: tras un `git add`, el salto entra en
  el cuerpo de un heredoc o en los argumentos de un `grep`/`echo` y encuentra un `git commit`
  que nadie va a ejecutar. Medido: `git status` + `grep -rn git commit .` → bloquea. Un
  bloqueo falso es peor que el agujero, porque deja la sesión inservible para comandos
  legítimos; es el fallo que costó arreglar el reconocimiento por subcadena.

La causa de fondo de las tres vueltas: dentro de un segmento no se sabe dónde acaba un
comando, porque `shlex` se come el salto de línea. En vez de adivinarlo, **se conserva la
información antes de perderla**: el comando se parte en líneas lógicas ANTES de tokenizar, y
las líneas que son cuerpo de un heredoc se descartan —se detectan por su `<<`/`<<-` y su
delimitador, que es una regla léxica, no una heurística—. Cada línea lógica se analiza como
una cadena de comandos, y la pista del `cd` se arrastra entre líneas porque `cd` persiste.

Eso es como lee un shell, y resuelve las tres cosas a la vez: el `git add` por medio, el
heredoc, y `swift build` + `git add` + `git commit` (que ninguna versión anterior cubría).

*Lo que se retira:* `siguiente_comando()` y la constante `INICIOS`. Restar.

*Consecuencia:* `SEPARADORES` deja de enumerar `"\n"`, porque nunca le llega. La constante
pasa a decir la verdad — que es lo que pide el punto 7 del requisito.

### D3. Cada caso entra con su prueba, y la prueba se demuestra capaz de fallar

`verifica-puerta.sh` ya cubre las cuatro formas que este hook cerró en su día. Las nuevas se
añaden ahí. Y no basta con que pasen: hay que revertir el arreglo y ver que fallan. Una
prueba que nunca se ha visto en rojo no prueba nada — es la misma lección que la sonda de
`PopGestureEnabler` dejó ayer en otro repositorio.

## Risks / Trade-offs

- **Que expandir variables cambie el veredicto según el entorno** → solo se expanden las que
  ya existen en el entorno del hook, que es el mismo en el que correría el comando. Si una
  variable no existe, la ruta queda sin resolver y se cae al fallo abierto de siempre.
- **Que partir por líneas rompa un caso que hoy funciona** → la suite entera de
  `verifica-puerta.sh` tiene que seguir en verde; es la red que lo detecta.
- **Que la puerta empiece a bloquear commits que antes pasaban** → es el arreglo. Quien
  commiteaba sin firma creyendo que la puerta le cubría, ahora se entera.

## Migration Plan

Un cambio por vez con su prueba: D1, luego D2. Sin despliegue: el hook se lee del plugin
instalado, así que el arreglo llega con la versión siguiente.

## Open Questions

Ninguna. Las dos causas están medidas y las dos soluciones caben en el analizador.

### D2ter. Leer las fronteras del lexer, no reconstruirlas

*Enmendada el 2026-09-16, tras el segundo DEVUELTO.* Las tres versiones anteriores comparten
un error de raíz, y hasta no verlo en una tabla no quedó claro: **todas intentan reconstruir
dónde acaba cada comando DESPUÉS de que `shlex` se haya comido los saltos de línea.** Por eso
cada arreglo abría la dirección contraria del anterior — agujero, bloqueo falso, las dos a la
vez.

Lo que ninguna miró: `shlex` no ha perdido esa información, la tiene. Expone `lineno`
mientras tokeniza, y además maneja las comillas. Medido:

```
git commit -m "titulo\n\ncuerpo"   → 'git'(1) 'commit'(1) '-m'(1) 'titulo\n\ncuerpo'(1→3)
git add -A\ngit commit -m x        → 'git'(1) 'add'(1) '-A'(1→2) 'git'(2) 'commit'(2)
cat > n.md <<EOF\n…                → … '<<'(1) 'EOF'(1) 'git'(2) 'commit'(2) 'EOF'(3)
grep foo <<<"texto"                → 'grep'(1) 'foo'(1) '<<<'(1) 'texto'(1)
```

Tres cosas caen solas de ahí:

- Un mensaje de commit de varias líneas es **UN token**, así que no se parte. Era el agujero
  grave del tercer intento, y el banco no lo veía porque usaba `-m x` en sus 29 casos.
- La frontera entre comandos sale del `lineno` de cada token: no hay que adivinarla.
- El heredoc se reconoce **por tokens**: `<<` es un token propio, `<<<` es otro distinto, y
  un `<<EOF` dentro de comillas es un token de texto. Ni here-strings mal leídos ni
  delimitadores fantasma — los dos fallos de la regex anterior.

*Consecuencia:* se retira `lineas_logicas()` sobre texto crudo y la constante `HEREDOC`. El
analizador queda del tamaño del original, con el doble de casos cubiertos.

*Lección, escrita para el siguiente:* cuatro intentos, y los tres primeros fueron parches
sobre el síntoma. Lo que cambió no fue esforzarse más, sino mirar si la información que
faltaba estaba disponible antes de tirarla.