## ADDED Requirements

### Requirement: Dice qué versión del kit corre

`/kit-estado` SHALL decir la versión del kit que ha cargado la conversación, leída del
manifiesto del plugin que ejecuta el comando, y NO SHALL compararla con nada ni dar consejo.

1. La línea SHALL salir siempre que el manifiesto sea legible; si no lo es, SHALL decirlo.
2. NO SHALL consultar la red ni leer ficheros internos de Claude Code para averiguar qué hay
   instalado.

#### Scenario: Se pregunta el estado

- **WHEN** se invoca `/kit-estado`
- **THEN** una línea dice la versión del kit que corre
- **AND** no hay ninguna otra línea sobre versiones

#### Scenario: El manifiesto no está

- **WHEN** el plugin no tiene un `plugin.json` legible junto a sus scripts
- **THEN** la línea dice que no encuentra el manifiesto

## REMOVED Requirements

### Requirement: La versión del kit se dice con el consejo que la arregla
**Reason**: Claude Code actualiza los plugins de un marketplace con auto-update y los recarga
con `/reload-plugins`; comparar tres versiones y redactar consejos era un detector para un
problema que se resuelve con una casilla.
**Migration**: Activar auto-update para el marketplace del kit desde `/plugin` › Marketplaces,
o actualizar a mano y recargar. Está en `docs/INSTALACION.md`.
