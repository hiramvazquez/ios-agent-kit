## ADDED Requirements

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
