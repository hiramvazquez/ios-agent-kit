#!/usr/bin/env bash
# Banco de pruebas de `busca-duplicados.py`.
# Por qué existe: un detector sin banco es un detector que nadie puede cambiar sin miedo, y
# el miedo se paga dejándolo como está.
#
# Uso:  bash scripts/verifica-duplicados.sh
#       DETECTOR_BAJO_PRUEBA=<ruta> bash scripts/verifica-duplicados.sh   ← contra otra versión
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

# El mismo fichero, alcanzable por dos rutas: el apaño habitual cuando un build tool plugin
# de SwiftPM no puede depender de un target de librería.
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
# Y que el número vaya con lo MIRADO: «N ficheros Swift que toque este cambio» afirmaba que el
# cambio tocaba todo lo escaneado.
contiene "$S" "sin lógica repetida que toque este cambio" && contiene "$S" "preexistente" \
    && ! contiene "$S" "ficheros Swift que toque"; caso $? \
    "con --tocados, un grupo que este cambio no toca no se reporta: se cuenta" \
    "el mensaje limpio pegaba el recuento de ficheros escaneados a «que toque este cambio»"

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

# El suelo son TRES líneas, no cuatro: subirlo quitaría algún doble de test que se cuela, pero
# se llevaría por delante ayudantes de tres líneas copiados entre un target y un plugin, que
# son justo la clase que el detector existe para cazar. `pascalCase()` es uno de esos.
S="$(detecta "$TMP/suelo3")"
contiene "$S" "cuerpo(s) repetido(s)"; caso $? \
    "un ayudante de TRES líneas copiado en dos ficheros SÍ se reporta"

# El segundo suelo: mismo largo en líneas que el caso de arriba, pero por debajo de los 60
# caracteres normalizados. Por él NO se reporta, y es lo que la spec `deteccion-de-duplicados`
# declara.
S="$(detecta "$TMP/suelo3_corto")"
contiene "$S" "sin lógica repetida"; caso $? \
    "un cuerpo de TRES líneas por DEBAJO del suelo de caracteres no se reporta"

S="$(detecta "$TMP/suelo4")"
contiene "$S" "cuerpo(s) repetido(s)"; caso $? \
    "y uno de cuatro, también"

resumen "el detector" "el-kit-se-aplica-a-si-mismo"
