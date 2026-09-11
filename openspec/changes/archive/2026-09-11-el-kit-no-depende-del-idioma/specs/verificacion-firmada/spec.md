# Verificación firmada — delta

## ADDED Requirements

### Requirement: El veredicto del kit no depende del idioma de la máquina

Los scripts del kit SHALL dar el mismo resultado con `LANG` vacío y con un locale UTF-8, que es
el que trae por defecto el terminal de macOS.

1. Ningún script del kit SHALL escribir `$VAR` pegado a un carácter no-ASCII. SHALL escribirse
   `${VAR}`, porque `bash` 3.2 con `LC_CTYPE` UTF-8 mete los bytes de ese carácter dentro del
   nombre de la variable.
2. `kit.conf` SHALL tener un paso que lo compruebe, que salga en rojo si encuentra alguno y diga
   en qué fichero y en qué línea.
3. El paso NO SHALL marcar la forma correcta `${VAR}` seguida del mismo carácter.
4. El paso SHALL mirar el byte y no una lista de caracteres: cuenta cualquier carácter no-ASCII,
   no solo los seis con los que se midió el fallo.

La 1 es el fallo real y no una precaución: con `set -u` —que usan todos los scripts del kit— no
degrada, **aborta**, y `/kit-verifica` sale sin firma, así que la puerta de commit bloquea el
commit. El kit queda inservible para quien abra un terminal con su configuración por defecto.

La 2 se la gana por las dos mitades de la regla. **Falló en varios scripts y en varios cambios,
a lo largo de semanas**, y su recuento exacto no se escribe aquí a propósito: parte de las
apariciones nunca llegó a commitearse, así que ningún `git log` puede devolver el número. Lo que
sí se comprueba, cada vez que corre `/kit-verifica`, es que no queda ninguna: lo dice el paso
«variables pegadas».

Y no hay forma más barata de verla: `bash -n` sale con 0, `shellcheck --severity=warning` sale con 0, y
los bancos pasan en verde porque el agente corre con el locale vacío. Es invisible a todo el
instrumental que ya existe y visible para el usuario a la primera.

La 3 existe porque un paso que marcara las dos formas sería inútil: el mensaje correcto lleva el
mismo carácter, y la diferencia son exactamente las llaves.

**Límite declarado.** Esto cubre los scripts del kit —`scripts/*.sh`, `scripts/*.py`, `kit.conf` y
su plantilla—, que es lo que el kit controla. El código del proyecto que lo usa queda fuera: ahí el
kit no manda, y prometerlo sería prometer de más. Tampoco ve un script fuera de `scripts/` o en una
subcarpeta suya, una variable partida con `\` al final de la línea, ni avisa si no puede abrir un
fichero.

#### Scenario: Un script con la forma rota

- **WHEN** un script del kit escribe `$VAR` pegado a un carácter no-ASCII
- **THEN** el paso sale en rojo y dice en qué fichero y en qué línea

#### Scenario: La forma correcta

- **WHEN** un script escribe `${VAR}` seguido del mismo carácter
- **THEN** el paso no lo marca

#### Scenario: El mismo veredicto en los dos idiomas

- **WHEN** se corre la verificación con `LANG` vacío y con `LANG=en_US.UTF-8`
- **THEN** las dos salen en verde y con firma
