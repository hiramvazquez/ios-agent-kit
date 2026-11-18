## ADDED Requirements

### Requirement: El manifiesto lo valida Claude Code

La verificación del kit SHALL correr `claude plugin validate --strict` sobre el propio kit, y
`autocomprueba.sh` NOT SHALL repetir lo que ese validador comprueba: que los manifiestos
parseen, la forma de `hooks.json` y el frontmatter. Si el CLI de `claude` no está, el paso
SHALL fallar, no saltarse.

#### Scenario: Un manifiesto roto

- **WHEN** `hooks.json` pone sus eventos fuera del objeto `hooks`
- **THEN** la verificación del kit sale en rojo por el paso del validador

#### Scenario: Falta el CLI

- **WHEN** `claude` no está en el PATH
- **THEN** el paso falla y lo dice

## MODIFIED Requirements

### Requirement: La autocomprobación se puede apuntar a un árbol, y por eso se puede probar

`autocomprueba.sh` SHALL poder comprobar un árbol de kit distinto del suyo.

1. Con una raíz como argumento, SHALL comprobar ESA raíz.
2. Sin argumento, SHALL comprobar la suya.

Sirve para probarla a mano contra un árbol roto sin tocar el del kit, y es lo que da sentido a su
«no pude mirar»: una raíz que no existe.

**Límite declarado.** Sin banco, nada comprueba que siga cazando lo que dice cazar: se ve cuando
falla al publicar.

#### Scenario: Un árbol de kit con un manifiesto roto

- **WHEN** se apunta la autocomprobación a un árbol cuyo `hooks.json` llama a un script que no
  existe
- **THEN** falla, y nombra el script

#### Scenario: Un árbol de kit sano

- **WHEN** se apunta a un árbol correcto
- **THEN** sale limpio

#### Scenario: Sin argumento

- **WHEN** se invoca sin argumentos, como hace `kit.conf`
- **THEN** comprueba su propia raíz
