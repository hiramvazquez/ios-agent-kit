#!/usr/bin/env bash
# Banco de pruebas de `busca-duplicados.py`.
#
# Por qué existe: nació y creció a ojo, y este cambio le toca la semántica. Un detector sin
# banco es un detector que nadie puede cambiar sin miedo, y el miedo se paga dejándolo como
# está.
#
# Aquí ponía «es el único script del kit con lógica de verdad que nunca se ha probado», y era
# falso: `verifica.sh` —que decide si hay firma— y `rodaja.sh` —única fuente del juez—
# tampoco tenían banco. Los tres lo tienen desde este mismo cambio, y el de `verifica.sh`
# llegó el último porque nadie se acordó de mirar quién más faltaba.
#
# El caso que nace en ROJO salió de medir el detector contra cuatro proyectos reales el
# 2026-09-08: en `spm-pro`, 28 grupos reportados de los cuales 21 eran EL MISMO FICHERO visto
# por dos rutas. Cuatro symlinks —el apaño estándar cuando un build tool plugin de SwiftPM no
# puede depender de un target de librería— bastaban para hacer ilegible el informe.
#
# Los tres casos del SUELO no nacen en rojo, y conviene saber por qué: fijan un suelo que no
# cambió. La misma medición creyó ver un segundo defecto —dos dobles de test de `AppStarter`,
# cuerpo de tres líneas, que colaban como duplicados— y subir el suelo a cuatro los quitaba.
# Se hizo, y el juez de aceptación lo devolvió: ese suelo borraba también `pascalCase()` y
# `displayPath()` en `spm-pro`, duplicados de verdad. Perder dos verdaderos para quitarse uno
# falso es mal trato. Se revirtió, y estos casos se quedan fijando el suelo real, incluido el
# de cuatro líneas que impide que alguien lo vuelva a subir sin medir por identidad.
#
# Uso:  bash scripts/verifica-duplicados.sh
#
# Se puede apuntar a otra versión para comprobar que cada caso rojo lo está por lo que dice:
#
#   git show <commit>:scripts/busca-duplicados.py > scripts/.dup-viejo.py
#   DETECTOR_BAJO_PRUEBA="$PWD/scripts/.dup-viejo.py" bash scripts/verifica-duplicados.sh
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$DIR/lib-banco.sh"

DETECTOR="${DETECTOR_BAJO_PRUEBA:-$DIR/busca-duplicados.py}"
[ -f "$DETECTOR" ] || { echo "no encuentro el detector en $DETECTOR"; exit 2; }

# --- montaje ------------------------------------------------------------------------------
#
# Aquí no hacen falta repositorios git: el detector recorre directorios y no pregunta por
# git. Se montan árboles pelados, que es lo que ve en un proyecto de verdad.

# cuerpo_largo <fichero> <nombre_de_func>   → 6 líneas, muy por encima del suelo de ruido
cuerpo_largo() {
    cat > "$1" <<EOF
import Foundation

struct Cosa {
    func $2(_ error: Error) -> String {
        let mapped = error.localizedDescription
        let prefix = "Se ha producido un problema al cargar los datos"
        let suffix = "Vuelve a intentarlo en unos segundos, por favor"
        let joined = [prefix, mapped, suffix].joined(separator: " · ")
        return joined.trimmingCharacters(in: .whitespaces)
    }
}
EOF
}

# cuerpo_de <n> <fichero>   → un cuerpo de exactamente <n> líneas, sobre los 60 caracteres
#                             normalizados que el detector exige
cuerpo_de() {
    case "$1" in
    2)  cat > "$2" <<'EOF'
struct Ajuste {
    func etiqueta() -> String {
        return "una cadena larga de verdad para pasar el umbral de sesenta caracteres"
    }
}
EOF
        ;;
    3)  cat > "$2" <<'EOF'
struct Ayudante {
    func pascalCase(_ texto: String) -> String {
        let partes = texto.split(separator: "-").map { $0.capitalized }
        return partes.joined()
    }
}
EOF
        ;;
    4)  cat > "$2" <<'EOF'
struct VistaConEstados {
    func loadingView() -> some View {
        let indicador = ProgressView().controlSize(.large)
        let contenedor = indicador.padding(24).background(.thinMaterial)
        return contenedor.transition(.opacity)
    }
}
EOF
        ;;
    esac
}

# cuerpo_corto <fichero>   → 3 líneas, como cuerpo_de 3, pero BAJO los 60 caracteres
#                            normalizados: 25, medido — el segundo suelo del detector
cuerpo_corto() {
    cat > "$1" <<'EOF'
struct Breve {
    func iguales(_ a: Int, _ b: Int) -> Bool {
        let ok = a == b
        return ok
    }
}
EOF
}

# detecta <directorio> [args...]   → la salida del detector sobre ese árbol
detecta() { local d="$1"; shift; (cd "$d" && python3 "$DETECTOR" . "$@" 2>&1); }

mkdir -p "$TMP/enlazado/Sources" "$TMP/enlazado/Plugins" \
         "$TMP/copias" "$TMP/limpio" "$TMP/suelo2" "$TMP/suelo3" "$TMP/suelo4" "$TMP/suelo3_corto"

# El mismo fichero, alcanzable por dos rutas. Es el caso de `spm-pro`.
cuerpo_largo "$TMP/enlazado/Sources/Real.swift" describeError
ln -s ../Sources/Real.swift "$TMP/enlazado/Plugins/Enlazado.swift"

# Dos ficheros de verdad con el mismo cuerpo. Es lo que el detector existe para cazar.
cuerpo_largo "$TMP/copias/A.swift" describeError
cuerpo_largo "$TMP/copias/B.swift" describeError

# Un solo fichero: no hay con quién repetirse.
cuerpo_largo "$TMP/limpio/Solo.swift" describeError

cuerpo_de 2 "$TMP/suelo2/A.swift"; cp "$TMP/suelo2/A.swift" "$TMP/suelo2/B.swift"
cuerpo_de 3 "$TMP/suelo3/A.swift"; cp "$TMP/suelo3/A.swift" "$TMP/suelo3/B.swift"
cuerpo_de 4 "$TMP/suelo4/A.swift"; cp "$TMP/suelo4/A.swift" "$TMP/suelo4/B.swift"
cuerpo_corto "$TMP/suelo3_corto/A.swift"; cp "$TMP/suelo3_corto/A.swift" "$TMP/suelo3_corto/B.swift"

echo "A.swift"    > "$TMP/tocados-suyo.txt"
echo "ajeno.swift" > "$TMP/tocados-ajeno.txt"

# --- los casos ----------------------------------------------------------------------------

echo "▶ lo que ya hacía, y no puede romperse"

S="$(detecta "$TMP/copias")"
contiene "$S" "cuerpo(s) repetido(s)"; caso $? \
    "dos ficheros distintos con el mismo cuerpo: lo reporta"

contiene "$S" "A.swift" && contiene "$S" "B.swift"; caso $? \
    "nombra las dos copias, con fichero y línea"

S="$(detecta "$TMP/limpio")"
contiene "$S" "sin lógica repetida"; caso $? \
    "un árbol sin repeticiones: lo dice y no inventa"

S="$(detecta "$TMP/copias" --tocados "$TMP/tocados-ajeno.txt")"
contiene "$S" "sin lógica repetida" && contiene "$S" "preexistente"; caso $? \
    "con --tocados, un grupo que este cambio no toca no se reporta: se cuenta"

S="$(detecta "$TMP/copias" --tocados "$TMP/tocados-suyo.txt")"
contiene "$S" "cuerpo(s) repetido(s)"; caso $? \
    "con --tocados, un grupo que este cambio SÍ toca se reporta entero"

echo "▶ un fichero real se cuenta una vez"

S="$(detecta "$TMP/enlazado")"
if contiene "$S" "sin lógica repetida"; then
    caso 0 "un fichero alcanzable por un symlink no se duplica a sí mismo"
else
    caso 1 "un fichero alcanzable por un symlink no se duplica a sí mismo" \
        "seguía el enlace y leía el mismo fichero dos veces: en spm-pro eso eran 21 de los 28 grupos"
fi

echo "▶ el suelo de ruido, y lo que NO se le pide"

S="$(detecta "$TMP/suelo2")"
contiene "$S" "sin lógica repetida"; caso $? \
    "un cuerpo de DOS líneas repetido no se reporta: por debajo del suelo, coincidir es normal"

# Este caso fija lo que el juez de aceptación salvó. Subir el suelo a 4 quitaba un falso
# positivo (dos dobles de test de AppStarter) y se llevaba por delante dos duplicados REALES
# de tres líneas en spm-pro —`pascalCase()` y `displayPath()`, copiados entre un target y un
# plugin—, que son justo la clase que el detector existe para cazar. El fixture es una copia
# de uno de ellos.
S="$(detecta "$TMP/suelo3")"
contiene "$S" "cuerpo(s) repetido(s)"; caso $? \
    "un ayudante de TRES líneas copiado en dos ficheros SÍ se reporta"

# El segundo suelo, el que hasta este cambio no tenía ni comentario: mismo largo en líneas que
# el caso de arriba, pero por debajo de los 60 caracteres normalizados. Por él NO se reporta,
# y eso es lo que la spec `deteccion-de-duplicados` pasa a declarar en vez de dejarlo mudo.
S="$(detecta "$TMP/suelo3_corto")"
contiene "$S" "sin lógica repetida"; caso $? \
    "un cuerpo de TRES líneas por DEBAJO del suelo de caracteres no se reporta"

S="$(detecta "$TMP/suelo4")"
contiene "$S" "cuerpo(s) repetido(s)"; caso $? \
    "y uno de cuatro, también"

resumen "el detector" "el-kit-se-aplica-a-si-mismo"
