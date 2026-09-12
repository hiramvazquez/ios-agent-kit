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
import shlex
import sys

# Operadores que separan comandos simples.
SEPARADORES = {";", "&&", "||", "|", "&", "\n"}

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


def tokeniza(cmd):
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=True)
    lex.whitespace_split = True
    return list(lex)


def analiza(cmd, profundidad=0):
    """Devuelve la ruta de destino si `cmd` invoca un commit, o None."""
    if profundidad > LIMITE_RECURSION:
        # Fallo ABIERTO: pasado este nivel de anidamiento el comando pasa sin
        # comprobar nada. El límite existe para que un `bash -c` recursivo no cuelgue
        # el hook, y cuatro niveles no los alcanza ningún commit que alguien escriba
        # sin querer — que es lo que esta puerta frena.
        return None
    try:
        tokens = tokeniza(cmd)
    except ValueError:
        # Fallo ABIERTO: comillas sin cerrar, así que no es un comando que vaya a
        # ejecutarse tal cual. Bloquear ante algo que ni siquiera va a correr
        # convertiría un fallo del analizador en una sesión inutilizable.
        return None

    segmentos, actual = [], []
    for t in tokens:
        if t in SEPARADORES:
            segmentos.append(actual)
            actual = []
        else:
            actual.append(t)
    segmentos.append(actual)

    cd_pendiente = None

    for seg in segmentos:
        seg = [t for t in seg if t not in AGRUPADORES]
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
            cd_pendiente = seg[i + 1]
            continue

        if base in ENVOLTORIOS:
            # `bash -c '<comando>'`: analizar el argumento de -c por dentro.
            for j in range(i + 1, len(seg) - 1):
                if seg[j] == "-c":
                    dentro = analiza(seg[j + 1], profundidad + 1)
                    if dentro is not None:
                        # Una ruta relativa de dentro se interpreta desde el `cd`
                        # que hubiera fuera; sin él, desde el directorio heredado.
                        return dentro if dentro != "." else (cd_pendiente or ".")
                    break
            continue

        if base != "git":
            continue

        ruta = None
        j = i + 1
        while j < len(seg):
            a = seg[j]
            if a in CON_VALOR:
                if a in ("-C", "--git-dir") and j + 1 < len(seg):
                    ruta = seg[j + 1]
                j += 2
                continue
            if a.startswith("--git-dir="):
                ruta = a.split("=", 1)[1]
                j += 1
                continue
            if a.startswith("-"):
                j += 1
                continue
            # Primer argumento que no es opción ni valor de opción: el subcomando.
            if a == "commit":
                return ruta or cd_pendiente or "."
            break   # otro subcomando de git; este segmento no interesa

    return None


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
