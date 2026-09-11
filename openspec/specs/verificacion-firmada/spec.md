# verificacion-firmada Specification

## Purpose

Que «verificado» signifique algo que se puede comprobar: la verificación se firma contra el
`sha256` del árbol que se verificó, y la firma vale para ese árbol y solo si el resultado fue
verde.

Y que se distinga **«no pude mirar»** de **«está mal»**. No son lo mismo: confundirlos hace
que un gate roto parezca un proyecto roto, y al revés. Por eso el código de salida reserva un
valor propio para el primer caso, y el recuento de pasos fallidos vive donde de verdad se
lee —el informe y la firma— en vez de en un código de salida que no puede decir dos cosas a
la vez.

## Requirements

### Requirement: «No pude mirar» y «está mal» salen con códigos distintos

`verifica.sh` SHALL distinguir en su código de salida el caso en que no ha podido verificar
del caso en que ha verificado y hay pasos en rojo.

1. Faltar `kit.conf`, o que no defina `verificaciones()`, SHALL seguir saliendo con el código
   documentado para «no pude mirar».
2. Que haya pasos en rojo SHALL salir con un código distinto de ese, **sea cual sea el número
   de pasos fallidos**.
3. El número de pasos en rojo SHALL seguir siendo legible en el informe y en la línea
   `resultado:` de la firma.

Hoy el script sale con el número de fallos, así que exactamente tres pasos en rojo son
indistinguibles de «no hay `kit.conf`» — y la documentación pública del kit afirma que se
distinguen. La 3 existe porque el recuento no se pierde: se mueve a donde de verdad se lee.

#### Scenario: Tres pasos en rojo

- **WHEN** la verificación corre con tres pasos que fallan
- **THEN** el código de salida no es el de «no pude mirar»
- **AND** el informe dice cuántos pasos fallaron

#### Scenario: Un repositorio sin kit.conf

- **WHEN** la verificación corre donde no hay `kit.conf`
- **THEN** sale con el código de «no pude mirar»

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
