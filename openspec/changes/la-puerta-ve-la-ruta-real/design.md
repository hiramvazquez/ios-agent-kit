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
