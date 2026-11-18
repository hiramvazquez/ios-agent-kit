#!/usr/bin/env bash
# El bug sembrado: `cargando = false` se ha movido DENTRO del `do`, así que si la carga falla
# el indicador de progreso no se apaga nunca.
. "$(dirname "${BASH_SOURCE[0]}")/../_comun/base.sh"
escribe_cargar '        do {
            productos = try await servicio.productos()
            cargando = false
        } catch {
            self.error = error.localizedDescription
        }
'
