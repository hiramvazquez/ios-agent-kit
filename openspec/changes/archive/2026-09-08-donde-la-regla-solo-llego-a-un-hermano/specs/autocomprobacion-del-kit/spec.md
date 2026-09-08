# autocomprobacion-del-kit — delta

## ADDED Requirements

### Requirement: «No pude mirar» y «hay problemas» salen con códigos distintos

`autocomprueba.sh` SHALL distinguir en su código de salida el caso en que no ha podido
comprobar nada del caso en que ha comprobado y hay problemas.

1. No poder resolver o alcanzar la raíz que se le pide SHALL salir con un código propio para
   «no pude mirar».
2. Que haya problemas SHALL salir con un código distinto de ese, **sea cual sea el número de
   problemas**.
3. El número de problemas SHALL seguir siendo legible en la salida del script.

Hoy sale con `exit "$FALLOS"`, y además sale con `1` cuando la raíz no existe: **un** problema
encontrado es indistinguible de «no existe la raíz». Es exactamente la colisión que
`verifica.sh` arregló, documentada en `verificacion-firmada` con su razón —«confundirlos hace
que un gate roto parezca un proyecto roto, y al revés»—, sin aplicar al hermano.

Y este hermano es la **puerta de publicación**: el script que dice «se puede publicar». Que
la regla llegara al que firma y no al que publica es el patrón que este cambio entero
persigue.

No tiene consecuencia viva hoy, y conviene decirlo en vez de inflarlo: su único invocador es
`kit.conf`, que solo mira cero contra no-cero. Se arregla porque el contrato es el que se lee
al depurar a mano, y porque la casa ya decidió cuál es la forma correcta.

#### Scenario: Un árbol de kit con varios defectos

- **WHEN** la autocomprobación corre sobre un árbol con más de un problema
- **THEN** el código de salida no es el de «no pude mirar»
- **AND** la salida dice cuántos problemas hay

#### Scenario: Una raíz que no existe

- **WHEN** se apunta la autocomprobación a un directorio que no existe
- **THEN** sale con el código de «no pude mirar»
