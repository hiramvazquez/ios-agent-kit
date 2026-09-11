#!/usr/bin/env python3
"""¿Hay algún `$VAR` pegado a un carácter que no sea ASCII?

POR QUÉ EXISTE. `bash` 3.2 —el que trae macOS— con `LC_CTYPE` UTF-8 se traga los bytes del
carácter multibyte que venga pegado a `$VAR` y los mete DENTRO del nombre de la variable:

    $ LANG=en_US.UTF-8 bash -c 'set -u; A=ok; echo "«$A»"'   # pegada-de-ejemplo
    bash: A»: unbound variable

Con `set -u` —que usan todos los scripts del kit— no degrada: aborta. Y `LANG=en_US.UTF-8` es el
valor por defecto de Terminal.app, así que no es un caso raro: es el terminal recién abierto de
cualquiera. Cuando pasó, `/kit-verifica` daba cuatro pasos en rojo y salía sin firma, y sin firma
la puerta de commit bloquea el commit. El kit quedaba inservible.

No es solo el guillemet. Medido con `»`, `—`, `·`, `…`, `á` y `€`: los seis rompen.

Y no hay forma más barata de verlo, que es la otra mitad de la regla de la casa: `bash -n` sale
con 0, `shellcheck --severity=warning` sale con 0, y los bancos pasan en verde porque el agente
corre con el locale vacío. Es invisible a todo el instrumental que ya existe, y visible para el
usuario a la primera. La clase había reincidido catorce veces en seis scripts, escritas a lo
largo de varias semanas, y diez de ellas ya estaban publicadas.

POR QUÉ PYTHON Y NO `grep`. La primera versión usaba `grep -rnoP`, y **no encontraba nada nunca**:
el `grep` de macOS es BSD y no tiene `-P`. Salía con «invalid option», el `|| true` se comía el
error, y el detector contestaba «✅ ninguna» sobre ficheros que sí las tenían. No se vio antes
porque el `grep` del agente es otro —un envoltorio que sí soporta `-P`—, o sea exactamente el
mismo hueco entre dos entornos que este cambio viene a cerrar. Python ya es dependencia del kit
—`busca-duplicados.py` y el paso «sintaxis · python»— y aquí es además lo preciso: se lee el
fichero en BYTES y se busca un byte alto, sin depender de ningún locale.

EL ARREGLO SON LAS LLAVES: `${VAR}`. No fijar `LC_ALL`, que arreglaría el fallo y de paso
cambiaría el orden de todo lo que ordena y la comparación de todo lo que compara.

Uso:  variables-pegadas.py [directorio]   ← por defecto, el `scripts/` del kit

Salidas, con la forma que `verifica.sh` ya tiene decidida:
  0  ninguna
  1  hay alguna, y dice cuál y dónde
  3  no pude mirar (el directorio no existe)

LA MARCA DE EJEMPLO. Una línea que lleve `pegada-de-ejemplo` se salta. Hace falta porque los
sitios que documentan el fallo tienen que poder ENSEÑARLO —esta misma cabecera lo hace—, y sin
la marca el detector se denuncia a sí mismo. Es la misma forma que usa `shellcheck disable`.
Va por línea, no por fichero, para que marcar un ejemplo no ciegue el resto del script.

LÍMITE DECLARADO, y son dos. Mira los scripts del kit —`.sh` y `.py`—, que es lo que el kit
controla: el código del proyecto que lo usa queda fuera, porque ahí el kit no manda y prometerlo
sería prometer de más. Y mira el fuente, no lo compilado: un `.pyc` no es algo que nadie escriba.
"""
import os
import re
import sys

# En BYTES, no en texto: el fallo es de bytes. `\$NOMBRE` seguido de un byte >= 0x80, sin llaves.
# `${NOMBRE}` no casa, y esa es toda la diferencia — un detector que marcara las dos formas sería
# inútil, porque el mensaje correcto lleva el mismo carácter.
PEGADA = re.compile(rb"\$[A-Za-z_][A-Za-z0-9_]*[\x80-\xff]")

# La marca que salta una línea. Se compara en bytes por lo mismo que todo lo demás.
MARCA = b"pegada-de-ejemplo"

# Solo fuente. Un `.pyc` lleva bytes altos por todas partes y nadie lo escribe a mano.
EXTENSIONES = (".sh", ".py")

donde = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))

if not os.path.isdir(donde):
    print("NO PUDE MIRAR — no existe «%s»" % donde)
    sys.exit(3)

hallazgos = []
for raiz, _, ficheros in os.walk(donde):
    if "__pycache__" in raiz.split(os.sep):
        continue
    for f in sorted(ficheros):
        if not f.endswith(EXTENSIONES):
            continue
        ruta = os.path.join(raiz, f)
        try:
            with open(ruta, "rb") as fh:
                for n, linea in enumerate(fh, 1):
                    if MARCA in linea:
                        continue
                    for m in PEGADA.finditer(linea):
                        hallazgos.append((ruta, n, m.group().decode("utf-8", "replace")))
        except OSError:
            continue

if hallazgos:
    print("❌ hay $VAR pegado a un carácter no-ASCII, y con LANG UTF-8 eso aborta:")
    for ruta, n, txt in hallazgos:
        print("   %s:%s: %s" % (ruta, n, txt))
    print()
    print("   Ponle llaves: $VAR → ${VAR}. La razón está en la cabecera de este script.")
    sys.exit(1)

print("✅ sin variables pegadas en «%s»." % os.path.basename(donde.rstrip("/")))
