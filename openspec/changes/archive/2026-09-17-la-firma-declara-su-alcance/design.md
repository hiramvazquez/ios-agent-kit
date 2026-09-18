## Context

El motivo y las mediciones están en `proposal.md` — Why. Lo que condiciona el cómo:

- El marker (`.agent-kit/verificacion.txt`) es **orientado a líneas** en su cabecera:
  `verificado:`, `diff:`, `rama:`, `resultado:`, y debajo el informe en prosa. `--comprueba` lo
  lee con `grep -q "^diff: …"` y `grep -q "^resultado: verde$"`, así que cualquier cosa que se
  añada arriba tiene que seguir siendo una línea.
- El digest (`inyecta-contexto.sh`) se inyecta **en cada turno**. Lo que cueste ahí se paga
  decenas de veces por sesión, y lo que ocupe se lee siempre.
- `estado.sh` y el digest **no verifican**: leen el marker. Hoy sacan de él la fecha, el
  resultado y la rama.
- El kit ya tuvo el fallo de dos definiciones de lo mismo: la huella del diff está en un solo
  sitio *por requisito* (`verificacion-firmada`, requisito de la huella, cláusula 3) porque dos
  copias divergentes hacían que el digest dijera «la firma es de OTRO diff» en un árbol recién
  firmado.
- `kit.conf` se carga con `.`, así que una variable que el proyecto defina ahí está disponible
  sin inventar ningún formato nuevo. Es como ya se leen `FUENTES` y `verificaciones`.

## Goals / Non-Goals

**Goals**

- Que el alcance viaje **en la firma**, no en un comentario que nadie lee.
- Que haya **una sola** definición de «qué toolchain es este».
- Que el digest siga siendo corto y siga sin ejecutar nada caro.

**Non-Goals**

- Invalidar una firma porque después se cambie de toolchain. La firma afirma «estos pasos
  pasaron con X», y eso sigue siendo verdad al cambiar de Xcode. Ver D3.
- Que el kit sepa qué toolchain usa el CI de cada proyecto.

## Decisions

### D1. La detección vive en una sola función, en `lib-kit.sh`

Una función del kit devuelve una línea con el toolchain, y `verifica.sh` es el único que la
llama. El digest y `/kit-estado` **leen la línea del marker**; no vuelven a detectar.

*Por qué:* es la regla que el propio requisito de la huella impone, y por el mismo motivo —dos
copias divergen—. Y porque detectar cuesta 0,3 s: despreciable una vez por verificación,
inaceptable en un hook que corre en cada turno.

*Alternativa descartada:* que cada superficie detecte lo suyo. Además de caro, haría que el
digest afirmara un toolchain distinto del que firmó, que es justo la confusión que este cambio
viene a cerrar.

### D2. Los límites: una palabra en la cabecera, la prosa en el informe

La cabecera gana `limites: declarados` o `limites: sin declarar`. El texto que el proyecto
escriba va **en el cuerpo del informe**, donde ya vive la prosa.

*Por qué:* la cabecera tiene que seguir siendo de una línea por campo para que `--comprueba` la
lea con `grep`. Meter prosa multilínea ahí obliga a inventar un terminador y a que todo lector
lo respete — un formato nuevo para nada.

*Alternativa descartada:* `limites:` con la prosa indentada debajo. Funciona hasta que alguien
escribe una línea vacía en su texto.

### D3. Cambiar de toolchain después de firmar NO invalida la firma

La huella sigue cubriendo árbol e índice, y nada más.

*Por qué:* lo que la firma afirma es que esos pasos pasaron con ese toolchain, y cambiar de
Xcode después no lo desmiente. Bloquear el commit por eso añadiría fricción sin cerrar ningún
agujero: el código no ha cambiado.

*Consecuencia asumida, y declarada:* alguien puede firmar con un toolchain, cambiar de Xcode y
commitear. El commit es legítimo y la firma dice con qué se probó, que es exactamente la
información que hoy falta. Detectar el toolchain en cada turno para avisar de la diferencia se
descarta por el coste del digest (D1).

### D4. Qué se detecta, y qué se hace si no está

Tres datos, en este orden: la versión del compilador del PATH, el Xcode seleccionado, y si el
compilador del PATH y el de `xcrun` divergen. Si alguna herramienta no está, se dice —«no
identificado»— y la verificación sigue.

*Por qué ese orden:* el primero es el que ejecuta la mayoría de los pasos de un `kit.conf`; el
segundo es el que resuelve el SDK y los plugins; el tercero es la trampa medida el 15 de
septiembre. Los tres juntos cuestan 0,3 s.

*Por qué no bloquear si falta:* el kit se usa en repositorios sin Xcode, y un paso que se salta
—o que aborta— por no poder *describir* el entorno convertiría un dato informativo en una puerta.

## Risks / Trade-offs

- **[El texto de `LIMITES` crece y sepulta el informe]** → es del proyecto y es prosa suya; el
  informe ya es prosa. La plantilla dirá que son dos o tres líneas, no un ensayo.
- **[Alguien lee el toolchain de la firma como si fuera el del CI]** → el texto que acompaña la
  línea dice de qué habla: con qué se corrió **aquí**. Es el riesgo que no se puede cerrar con
  código, solo con la redacción.
- **[Un marker viejo no tiene las líneas nuevas]** → `--comprueba` solo mira `diff:` y
  `resultado:`, así que una firma anterior a este cambio sigue siendo válida y se lee sin
  toolchain. No hay migración que hacer; se declara y se prueba.
- **[Un `swift` del PATH que cuelgue]** → la verificación colgaría igual en el primer paso que
  lo use, así que no añade un modo de fallo nuevo.

## Migration Plan

Aditivo, sin migración: las líneas nuevas se añaden a la cabecera y los lectores existentes
(`--comprueba`, la puerta) no las necesitan. Un marker firmado antes del cambio sigue valiendo.
