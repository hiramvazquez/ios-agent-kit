#!/usr/bin/env python3
"""Caza lógica repetida: el mismo cuerpo de función escrito en dos sitios.

Ningún linter lo ve —cada copia es correcta por separado— y ninguna review lo caza, porque
el revisor mira UN diff y las copias nacen en semanas distintas.

Qué hace: extrae cada `func`/`var` computada con cuerpo, lo normaliza (fuera comentarios,
espacios y el nombre propio) y agrupa por huella. Dos cuerpos idénticos en ficheros
distintos son un duplicado; en el mismo fichero, no (sobrecargas legítimas).

Y aparte: agrupa las `extension` del MISMO tipo declaradas en módulos distintos, que es
la forma que toma el problema antes de que los cuerpos sean idénticos.

Uso:  python3 "${CLAUDE_PLUGIN_ROOT}/scripts/busca-duplicados.py" [rutas...]
      ... --tocados <fichero> ...  solo los grupos que toca el cambio en curso

Sobre `--tocados`: un proyecto vivo arrastra duplicados preexistentes que ya se miraron y
se decidieron. Listarlos enteros en CADA verificación convierte el aviso en papel pintado
y entierra el único que importa: el que ESTE cambio acaba de introducir. Con `--tocados` se
reporta un grupo solo si alguna de sus copias está en un fichero del diff, y los demás se
resumen en una línea.

Sale 1 si encuentra algo (de lo reportado); 0 si está limpio.
"""
import hashlib, re, sys
from collections import defaultdict
from pathlib import Path

argv = sys.argv[1:]
TOCADOS = None
if "--tocados" in argv:
    i = argv.index("--tocados")
    lista = Path(argv[i + 1]) if len(argv) > i + 1 else None
    argv = argv[:i] + argv[i + 2:]
    if lista and lista.exists():
        TOCADOS = {l.strip() for l in lista.read_text().splitlines() if l.strip()}

RAICES = [Path(p) for p in (argv or ["App", "Sources", "Packages"]) if Path(p).exists()]

def tocado(*rutas):
    """¿Alguna de estas rutas está en el diff? Sin `--tocados`, todo cuenta como tocado."""
    return True if TOCADOS is None else any(str(r) in TOCADOS for r in rutas)
# El suelo de líneas, y la medición que lo fija (la tabla completa, con nombres, está en la
# spec `deteccion-de-duplicados`): subirlo de 3 a 4 quitaba un falso positivo —dos dobles de
# test— y se llevaba dos duplicados REALES de tres líneas copiados entre un target y un
# plugin, justo la clase que este detector existe para cazar. Toda medición para moverlo
# tiene que decir QUÉ grupos cambian de lado, no cuántos.
MIN_LINEAS = 3

# El segundo suelo: sin él, un cuerpo de tres líneas cuya única sustancia normalizada es
# una llave, una asignación trivial y un `return` se reporta como duplicado, que es
# coincidencia de forma y no lógica repetida. El caso exacto que decide este número está
# montado en `verifica-duplicados.sh`.
MIN_CARACTERES = 60

def sin_ruido(txt):
    txt = re.sub(r"//[^\n]*", "", txt)
    txt = re.sub(r"/\*.*?\*/", "", txt, flags=re.S)
    return re.sub(r"\s+", " ", txt).strip()

def cuerpos(ruta):
    """(nombre, huella, línea, nº de líneas) por cada func/var con cuerpo."""
    src = ruta.read_text(errors="replace")
    for m in re.finditer(r"\b(?:func|var)\s+(\w+)[^\n{]*\{", src):
        i = src.index("{", m.end() - 1)
        prof, j = 0, i
        while j < len(src):
            if src[j] == "{": prof += 1
            elif src[j] == "}":
                prof -= 1
                if prof == 0: break
            j += 1
        cuerpo = src[i + 1:j]
        n = cuerpo.count("\n")
        if n < MIN_LINEAS: continue
        norm = sin_ruido(cuerpo)
        if len(norm) < MIN_CARACTERES: continue
        yield m.group(1), hashlib.sha1(norm.encode()).hexdigest()[:10], src[:m.start()].count("\n") + 1, n

def extensiones(ruta):
    for m in re.finditer(r"^\s*(?:public\s+|internal\s+)?extension\s+(\w+)", ruta.read_text(errors="replace"), re.M):
        yield m.group(1), ruta.name

# Un fichero real se cuenta UNA vez, aunque se llegue a él por dos rutas: un symlink no es
# una copia deliberada. Enlazar fuentes es el apaño estándar cuando un build tool plugin de
# SwiftPM no puede depender de un target de librería. Se deduplica por identidad del fichero
# —`resolve()`— y no por una lista de directorios a ignorar, que habría que mantener.
_vistos = {}
for _r in RAICES:
    for _f in sorted(_r.rglob("*.swift")):
        if ".build" in _f.parts or "checkouts" in _f.parts:
            continue
        _real = _f.resolve()
        if _real in _vistos:
            continue
        _vistos[_real] = _f
ficheros = sorted(_vistos.values())
por_huella, por_tipo = defaultdict(list), defaultdict(set)
for f in ficheros:
    for nombre, h, linea, n in cuerpos(f):
        por_huella[h].append((f, nombre, linea, n))
    for tipo, nom in extensiones(f):
        por_tipo[tipo].add(str(f))

fallos = 0
todos = {h: v for h, v in por_huella.items() if len({x[0] for x in v}) > 1}
dups = {h: v for h, v in todos.items() if tocado(*{x[0] for x in v})}
ocultos = len(todos) - len(dups)
if dups:
    fallos += len(dups)
    print(f"❌ {len(dups)} cuerpo(s) repetido(s) en ficheros distintos:\n")
    for h, apar in sorted(dups.items(), key=lambda kv: -kv[1][0][3]):
        print(f"  huella {h} — {apar[0][3]} líneas, {len(apar)} copias:")
        for f, nombre, linea, _ in apar:
            print(f"     {f}:{linea}  {nombre}()")
        print()

esparcidas = {t: fs for t, fs in por_tipo.items() if len(fs) > 2 and tocado(*fs)}
if esparcidas:
    print(f"⚠️  tipos extendidos desde 3+ ficheros (mírales antes de que converjan):\n")
    for t, fs in sorted(esparcidas.items(), key=lambda kv: -len(kv[1])):
        print(f"  extension {t} — {len(fs)} ficheros")
        for f in sorted(fs): print(f"     {f}")
        print()

if not fallos and not esparcidas:
    # El número es lo MIRADO, no lo tocado: pegado a «que toque este cambio» se leía como si
    # el cambio tocara todos esos ficheros.
    if TOCADOS is not None:
        print(f"✅ sin lógica repetida que toque este cambio ({len(ficheros)} ficheros Swift mirados).")
    else:
        print(f"✅ sin lógica repetida en {len(ficheros)} ficheros Swift.")

if ocultos:
    # Ni se ocultan a escondidas ni se repiten enteros: se cuentan, y hay un comando para
    # verlos. Un duplicado preexistente es deuda conocida, no un hallazgo de este cambio.
    print(f"\n({ocultos} grupo(s) repetido(s) preexistente(s), sin relación con este cambio."
          f" Lístalos con /kit-duplicados.)")
sys.exit(1 if fallos else 0)
