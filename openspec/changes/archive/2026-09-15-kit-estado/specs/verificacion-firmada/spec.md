## ADDED Requirements

### Requirement: El aviso de kit desfasado da el consejo que lo arregla

El aviso de kit desfasado del informe de verificación SHALL dar, para las mismas tres versiones —la
que corre, la instalada y la del clon del marketplace—, el mismo consejo que `/kit-estado` (ver
`estado-del-kit`). SHALL seguir comparando además el clon del marketplace con su remoto, como mucho
una vez al día.

1. Si el remoto del marketplace trae una versión distinta de la del clon, SHALL aconsejar actualizar
   el marketplace, después el plugin y después abrir una conversación nueva.
2. Sin red, SHALL callarse sobre el remoto y dar el consejo que salga de las otras tres versiones.

Hasta este cambio el aviso comparaba solo la versión que corre con la del clon, y aconsejaba
`claude plugin update` también cuando la actualización ya estaba instalada y lo que la dejaba sin
efecto era una conversación reanudada.

#### Scenario: Verificar desde una conversación reanudada

- **WHEN** se verifica desde una conversación que corre la 1.10.0, con la 1.12.2 instalada y en el
  clon del marketplace
- **THEN** el informe aconseja abrir una conversación nueva
- **AND** no aconseja `claude plugin update`
