#!/usr/bin/env bash
# El repositorio de juguete de los dos casos del revisor: un view model con su carga ya
# commiteado y un cambio OpenSpec abierto. Cada caso lo carga con `.` y deja encima, sin
# commitear, su versión del cambio: una con el bug y otra sin él.
set -euo pipefail

git init -q .
git config user.email eval@kit.test
git config user.name eval

mkdir -p Sources openspec/changes/el-error-del-servidor
cat > Sources/ListadoViewModel.swift <<'SWIFT'
import Foundation

@MainActor
final class ListadoViewModel {
    private(set) var productos: [Producto] = []
    private(set) var cargando = false
    private(set) var error: String?
    private let servicio: Servicio

    init(servicio: Servicio) {
        self.servicio = servicio
    }

    func cargar() async {
        cargando = true
        error = nil
        do {
            productos = try await servicio.productos()
        } catch {
            self.error = "No se pudo cargar"
        }
        cargando = false
    }
}
SWIFT
cat > openspec/changes/el-error-del-servidor/proposal.md <<'MD'
# El listado enseña el error del servidor

## Why

Cuando falla la carga, el listado dice siempre «No se pudo cargar». El servidor ya manda un
mensaje que explica qué pasó, y no se enseña.

## What Changes

- `ListadoViewModel.cargar()` guarda en `error` el mensaje del error recibido.

## Fuera de alcance

- La vista, el servicio y los reintentos.

## Criterios de aceptación

- [ ] Si la carga falla, `error` SHALL llevar el mensaje del error recibido.
- [ ] El resto del comportamiento de `cargar()` NOT SHALL cambiar.
MD
cat > openspec/changes/el-error-del-servidor/tasks.md <<'MD'
# Tareas

- [x] 1. `cargar()` guarda el mensaje del error recibido.
MD
git add -A
git commit -qm "base"

# escribe_cargar <cuerpo del do/catch> — reescribe `cargar()` con el cuerpo que le den.
escribe_cargar() {
    python3 - "$1" <<'PY'
import sys
p = "Sources/ListadoViewModel.swift"
s = open(p).read()
ini = s.index("        do {")
fin = s.index("    }\n}", ini)
open(p, "w").write(s[:ini] + sys.argv[1] + s[fin:])
PY
}
