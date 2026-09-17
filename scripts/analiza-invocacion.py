#!/usr/bin/env python3
"""Decide si un comando de shell invoca un commit, y a qué repositorio va.

Lo usa `puerta-commit.sh`. Vive en su propio fichero por dos razones, y las dos
salieron de fallos reales:

- En un heredoc dentro de `$(python3 - <<'PY')`, stdin lo ocupa el PROPIO programa,
  así que el JSON del hook no llega nunca y el analizador responde «no es un commit»
  a todo: la puerta queda abierta de par en par, sin síntoma visible.
- Leer el JSON en un intérprete y analizar en otro cuesta +12,6 ms en CADA comando
  de la sesión. Aquí es uno solo.

Lee el JSON del hook por stdin e imprime una línea:
    NO              → esto no invoca un commit
    COMMIT <ruta>   → sí, y <ruta> es la pista de dónde (o "." si no hay pista)
"""
import json
import os
import shlex
import sys

# Operadores que separan comandos simples.
# El salto de línea NO está, a propósito: `shlex` con `whitespace_split` lo consume como
# espacio y nunca lo emite como token, así que enumerarlo hacía creer que un `cd` en una
# línea y un commit en la siguiente estaban cubiertos. Lo están, pero por el escaneo que no
# abandona el segmento tras un `cd` — no por esta lista.
SEPARADORES = {";", "&&", "||", "|", "&"}

# Agrupadores que NO son un comando: `(cd X && …)`, `{ cd X && …; }`. Si no se
# descartan, el primer token del segmento es `(` o `{`, el `cd` no se registra como
# tal y el commit acaba juzgándose contra el directorio heredado. Era el fallo que
# este script existe para cerrar, colándose por la puerta de al lado.
AGRUPADORES = {"(", ")", "{", "}"}

# Cambian el directorio para lo que venga después en la cadena.
CAMBIAN_DIR = {"cd", "pushd"}

# Opciones globales de git que se COMEN el argumento siguiente. Sin esta lista, en
# `git -C /ruta commit` el subcomando parecería ser "/ruta".
CON_VALOR = {"-C", "--git-dir", "--work-tree", "-c", "--exec-path", "--namespace",
             "--super-prefix", "--config-env"}

# Envoltorios que reciben un comando como cadena y lo ejecutan: `bash -c '…'`. Se
# analizan por dentro, porque `bash -c 'cd X && git commit'` es un commit dirigido a
# X con todas las letras. Sin esto se colaba sin comprobar nada.
ENVOLTORIOS = {"bash", "sh", "zsh", "dash", "ksh"}

LIMITE_RECURSION = 4


def expandir(ruta):
    """Resuelve la pista como la resolvería el shell que va a ejecutar el comando.

    Variables primero y `~` después: al revés, un `$HOME/...` sin expandir no empieza por
    `~`, `expanduser` no haría nada y la ruta seguiría sin resolver — que es exactamente
    cómo se colaban los commits.

    Lo que NO resuelve, y sigue siendo fallo abierto declarado: una ruta construida en
    tiempo de ejecución —`$(pwd)`, o una variable definida en el propio comando—, porque
    para eso habría que ejecutar el comando.
    """
    return os.path.expanduser(os.path.expandvars(ruta))


def tokens_con_linea(cmd):
    """Los tokens del comando, cada uno con la línea en la que empieza.

    La clave está en NO reconstruir las fronteras: `shlex` ya sabe por qué línea va —expone
    `lineno`— y además maneja las comillas, así que un mensaje de commit de varias líneas es
    UN token y no se parte. Los tres intentos anteriores fallaron por lo contrario: partían
    el texto por saltos físicos, o adivinaban dónde acababa un comando después de que el
    tokenizador se hubiera comido esa información.
    """
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=True)
    lex.whitespace_split = True
    fuera = []
    while True:
        # `lineno` antes de pedir el token es la línea en la que acabó el anterior, que es
        # donde este empieza salvo por los espacios de en medio.
        inicio = lex.lineno
        tok = lex.get_token()
        if tok is None:
            break
        fuera.append((tok, inicio))
    return fuera


def sin_cuerpos_de_heredoc(toks):
    """Quita los tokens del CUERPO de cada heredoc: ese texto no se ejecuta.

    Se reconoce por tokens, no por texto: `<<` es un token propio y `<<<` es otro distinto,
    y un `<<EOF` escrito dentro de comillas es un token de texto. Por eso aquí no hay ni
    here-strings mal leídos ni delimitadores fantasma — que es lo que rompía la versión
    anterior, hecha con una expresión regular sobre las líneas.
    """
    fuera, i = [], 0
    while i < len(toks):
        tok, linea = toks[i]
        fuera.append((tok, linea))
        if tok in ("<<", "<<-") and i + 1 < len(toks):
            delimitador = toks[i + 1][0]
            fuera.append(toks[i + 1])
            i += 2
            while i < len(toks) and toks[i][0] != delimitador:
                i += 1
            i += 1      # el delimitador de cierre tampoco es un comando
            continue
        i += 1
    return fuera


def lineas_logicas(toks):
    """Agrupa los tokens en líneas, por la línea en la que empieza cada uno."""
    lineas = []
    for tok, linea in toks:
        if not lineas or linea > lineas[-1][0]:
            lineas.append((linea, []))
        lineas[-1][1].append(tok)
    return [tokens for _, tokens in lineas]


def analiza(cmd, profundidad=0):
    """Devuelve la ruta de destino si `cmd` invoca un commit, o None."""
    if profundidad > LIMITE_RECURSION:
        # Fallo ABIERTO: pasado este nivel de anidamiento el comando pasa sin comprobar
        # nada. El límite existe para que un `bash -c` recursivo no cuelgue el hook, y
        # cuatro niveles no los alcanza ningún commit que alguien escriba sin querer.
        return None
    try:
        toks = tokens_con_linea(cmd)
    except ValueError:
        # Fallo ABIERTO: comillas sin cerrar, así que no es un comando que vaya a
        # ejecutarse tal cual. Bloquear ante algo que ni siquiera va a correr convertiría
        # un fallo del analizador en una sesión inutilizable.
        return None

    cd_pendiente = None
    for tokens in lineas_logicas(sin_cuerpos_de_heredoc(toks)):
        destino, cd_pendiente = analiza_linea(tokens, cd_pendiente, profundidad)
        if destino is not None:
            return destino
    return None


def analiza_linea(tokens, cd_pendiente, profundidad):
    """Analiza los tokens de UNA línea lógica.

    Devuelve `(destino o None, pista del cd para la línea siguiente)`. La pista se arrastra
    porque `cd` persiste: un `cd X` en una línea manda sobre el commit de la siguiente.
    """
    segmentos, actual = [], []
    for tok in tokens:
        if tok in SEPARADORES:
            segmentos.append(actual)
            actual = []
        else:
            actual.append(tok)
    segmentos.append(actual)

    for seg in segmentos:
        seg = [x for x in seg if x not in AGRUPADORES]
        if not seg:
            continue

        # Saltar asignaciones que preceden al comando: FOO=bar git …
        i = 0
        while (i < len(seg) and "=" in seg[i] and not seg[i].startswith("-")
               and "/" not in seg[i].split("=")[0]):
            i += 1
        if i >= len(seg):
            continue
        base = seg[i].rsplit("/", 1)[-1]

        if base in CAMBIAN_DIR and i + 1 < len(seg):
            cd_pendiente = expandir(seg[i + 1])
            continue

        if base in ENVOLTORIOS:
            # `bash -c '<comando>'`: analizar el argumento de -c por dentro.
            for j in range(i + 1, len(seg) - 1):
                if seg[j] == "-c":
                    dentro = analiza(seg[j + 1], profundidad + 1)
                    if dentro is not None:
                        # Una ruta relativa de dentro se interpreta desde el `cd` que
                        # hubiera fuera; sin él, desde el directorio heredado.
                        return (dentro if dentro != "." else (cd_pendiente or ".")), cd_pendiente
                    break
            continue

        if base != "git":
            continue

        ruta = None
        j = i + 1
        while j < len(seg):
            arg = seg[j]
            if arg in CON_VALOR:
                if arg in ("-C", "--git-dir") and j + 1 < len(seg):
                    ruta = expandir(seg[j + 1])
                j += 2
                continue
            if arg.startswith("--git-dir="):
                ruta = expandir(arg.split("=", 1)[1])
                j += 1
                continue
            if arg.startswith("-"):
                j += 1
                continue
            # Primer argumento que no es opción ni valor de opción: el subcomando.
            if arg == "commit":
                return (ruta or cd_pendiente or "."), cd_pendiente
            break   # otro subcomando de git; este segmento no interesa

    return None, cd_pendiente


def main():
    try:
        cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "")
    except Exception:
        # Fallo ABIERTO: sin poder leer la entrada no se puede afirmar que haya un
        # commit, y bloquear todo comando ante un JSON raro convertiría un fallo del
        # hook en una sesión inutilizable.
        print("NO")
        return
    # Fallo ABIERTO si `command` no es una cadena: el hook recibiría algo que no es un
    # comando, y no hay invocación que juzgar. Mismo argumento que arriba.
    destino = analiza(cmd) if isinstance(cmd, str) else None
    print("NO" if destino is None else "COMMIT " + destino)


if __name__ == "__main__":
    main()
