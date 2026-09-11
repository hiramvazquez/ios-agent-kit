# Verificación firmada — delta

## ADDED Requirements

### Requirement: El veredicto del kit no depende del idioma de la máquina

Los scripts del kit SHALL dar el mismo resultado con `LANG` vacío y con un locale UTF-8, que es
el que trae por defecto el terminal de macOS.

1. Ningún script del kit SHALL escribir `$VAR` pegado a un carácter no-ASCII. SHALL escribirse
   `${VAR}`, porque `bash` 3.2 con `LC_CTYPE` UTF-8 mete los bytes de ese carácter dentro del
   nombre de la variable.
2. SHALL existir un detector que lo compruebe, y `kit.conf` SHALL correrlo.
3. El detector NO SHALL marcar la forma correcta `${VAR}` seguida del mismo carácter.
4. Su banco SHALL montar como casos los caracteres con los que se midió el fallo, no solo uno.

La 1 es el fallo real y no una precaución: con `set -u` —que usan todos los scripts del kit— no
degrada, **aborta**, y `/kit-verifica` sale sin firma, así que la puerta de commit bloquea el
commit. El kit queda inservible para quien abra un terminal con su configuración por defecto.

La 2 se la gana por las dos mitades de la regla. Falló más de dos veces: catorce apariciones en
seis scripts, escritas en varias semanas y varios cambios, diez de ellas ya publicadas. Y no hay
forma más barata de verla: `bash -n` sale con 0, `shellcheck --severity=warning` sale con 0, y
los bancos pasan en verde porque el agente corre con el locale vacío. Es invisible a todo el
instrumental que ya existe y visible para el usuario a la primera.

La 3 existe porque un detector que marcara las dos formas sería inútil: el mensaje correcto lleva
el mismo carácter, y la diferencia son exactamente las llaves.

**Límite declarado.** Esto cubre los scripts del kit, que es lo que el kit controla. El código del
proyecto que lo usa queda fuera: ahí el kit no manda, y prometerlo sería prometer de más.

#### Scenario: Un script con la forma rota

- **WHEN** un script del kit escribe `$VAR` pegado a un carácter no-ASCII
- **THEN** el detector falla y dice en qué fichero y en qué línea

#### Scenario: La forma correcta

- **WHEN** un script escribe `${VAR}` seguido del mismo carácter
- **THEN** el detector no lo marca

#### Scenario: El mismo veredicto en los dos idiomas

- **WHEN** se corre la verificación con `LANG` vacío y con `LANG=en_US.UTF-8`
- **THEN** las dos salen en verde y con firma
