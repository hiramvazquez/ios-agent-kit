#!/usr/bin/env bash
# El mismo cambio, bien hecho: solo cambia el mensaje que se guarda.
. "$(dirname "${BASH_SOURCE[0]}")/../_comun/base.sh"
escribe_cargar '        do {
            productos = try await servicio.productos()
        } catch {
            self.error = error.localizedDescription
        }
        cargando = false
'
