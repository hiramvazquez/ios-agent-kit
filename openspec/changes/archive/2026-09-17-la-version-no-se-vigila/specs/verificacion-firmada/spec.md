## REMOVED Requirements

### Requirement: El aviso de kit desfasado da el consejo que lo arregla
**Reason**: La verificación deja de mirar versiones y de consultar el remoto del marketplace.
Claude Code se encarga de actualizar y recargar el plugin.
**Migration**: Activar auto-update para el marketplace del kit, o actualizar a mano y
`/reload-plugins`. Está en `docs/INSTALACION.md`.
