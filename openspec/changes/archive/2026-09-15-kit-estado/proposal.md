# /kit-estado: preguntar cómo estamos sin compilar nada

## Why

El 2026-09-14 el owner lo dijo así: «a veces estoy a ciegas». Los seis comandos del kit sirven
para *hacer* —verificar, revisar, juzgar, buscar duplicados— y ninguno para *preguntar*. Lo que
se querría saber ya lo escribe el propio kit, pero disperso: la firma y el veredicto en
`.agent-kit/verificacion.txt`, los cambios activos en `openspec/changes/`, el desfase de versión
dentro de `verifica.sh`, lo pendiente de empujar en git. Esa tarde, contestar «¿en qué punto
estamos?» fue juntarlo a mano, comando a comando.

La única pieza que ya dice parte de esto no sirve para preguntar: `/kit-verifica` ejecuta el
`kit.conf` entero —en AppStarter, cinco pasos de build y tests, minutos—, y una pregunta que tarda
minutos no se hace.

Y ese mismo día el kit se aconsejó mal a sí mismo. El aviso de desfase de `verifica.sh` compara la
versión que corre con la del clon del marketplace, no con la instalada: con la 1.12.2 ya instalada
y una conversación reanudada que seguía en la 1.10.0, decía «→ claude plugin update». Actualizar
ya estaba hecho; lo que faltaba era abrir una conversación nueva, y costó dos rondas averiguarlo.
`docs/INSTALACION.md` dice «reinicia la sesión», que es lo que el owner hizo —cerrar la app,
abrirla y retomar la conversación— sin que sirviera.

## What Changes

- **Comando nuevo `/kit-estado`**, con su script. Solo lee: no ejecuta `kit.conf`, no compila, no
  consulta la red y no escribe nada. Dice, en una pantalla:
  - la rama y lo que hay sin commitear, sin empujar y sin traer —respecto al último `fetch`—;
  - **todos** los cambios OpenSpec activos, con sus tareas hechas;
  - si la firma de verificación vale para este árbol, y la fecha y el resultado de la última;
  - cuántos grupos de lógica repetida hay, todos y no solo los que toca el cambio en curso;
  - la versión del kit que corre, la instalada y la del clon del marketplace, con el consejo que
    lo arregla cuando no coinciden.
- **El consejo de versión se corrige, y es el mismo en `/kit-estado` y en el informe de
  `/kit-verifica`**: si la instalada no es la que corre, abrir una conversación nueva; si el
  marketplace trae otra que la instalada, `claude plugin update` y después conversación nueva.
- **Lo que las dos piezas comparten se mueve a `lib-kit.sh`, no se copia**: el recuento de
  tareas, hoy dentro del hook; la lista completa de cambios activos; y la lectura de versiones, hoy
  dentro de `verifica.sh`. El digest que se inyecta en cada turno no cambia.
- **`verifica.sh --comprueba` e `--informe` dejan de crear `.agent-kit/`.** `/kit-estado` usa
  `--comprueba` para dar el mismo veredicto que la puerta de commit, y una pregunta no puede dejar
  un directorio en un repositorio que nunca pidió el kit.
- **La doc de actualizar dice «conversación nueva»**, no solo «reinicia»: reanudar una
  conversación conserva la versión del kit con la que nació.

## Capabilities

### New Capabilities

- `estado-del-kit`: qué responde `/kit-estado` y qué garantiza no hacer.

### Modified Capabilities

- `verificacion-firmada`: un requisito nuevo para el aviso de kit desfasado del informe —hoy no lo
  describe ninguna spec—, para que dé el mismo consejo que `/kit-estado`.

## Impact

- **Nuevos:** `commands/kit-estado.md`, `scripts/estado.sh`.
- **Se editan:** `scripts/lib-kit.sh`, `scripts/inyecta-contexto.sh`, `scripts/verifica.sh`,
  `README.md`, `docs/PIEZAS.md`, `docs/INSTALACION.md`.
- **No se tocan:** `hooks/hooks.json` —ningún hook nuevo— ni los bancos. Lo que se mueve a la lib
  lo vigilan bancos que ya existen: `verifica-contexto.sh` fija el digest, recuento de tareas
  incluido, y `verifica-salidas.sh` los modos de `verifica.sh`.
- **El kit crece**, y va dicho: dos ficheros y un comando más. Lo que no añade es otra fuente de
  verdad: cada cosa que dice la decide una pieza que ya existe.
- **Proyectos que usan el kit:** nada que tocar. Un `verificacion.txt` ya escrito conserva el aviso
  viejo hasta la siguiente verificación.

## FUERA de alcance

- **La rodaja pendiente de revisar.** No estaba en lo que se acordó mostrar, y `rodaja.sh` ya lo
  responde.
- **Consultar el remoto desde `/kit-estado`.** «Sin empujar» y «sin traer» son respecto al último
  `fetch`; quien mira el remoto del marketplace sigue siendo `verifica.sh`, una vez al día.
- **Un banco para `estado.sh`.** Límite declarado: su salida no la comprueba nada salvo leerla.
- **Estas líneas en el digest de cada turno.** El digest es corto a propósito, y lo que se
  pregunta de vez en cuando no tiene que pagarse en cada turno.
- **El digest dice «firmada» tras una verificación en rojo.** Hallazgo de esta planificación: mira
  la huella del árbol y no el resultado, al contrario que la puerta de commit. Es otra decisión.
- **AppStarter**, y su `verificacion.txt` con el aviso viejo.
- **Publicar.** Versión y push, cuando se decida.

## Criterios de aceptación

- [ ] `/kit-estado` en AppStarter SHALL responder en menos de 1 s en tres corridas seguidas, y
      `git status --porcelain` y `ls -la .agent-kit` SHALL salir iguales antes y después.
- [ ] En un repositorio git temporal sin `.agent-kit/`, `/kit-estado` NO SHALL crear ese
      directorio.
- [ ] En un repositorio temporal con dos cambios activos, uno sin `tasks.md`, SHALL listar los dos,
      con recuento solo en el que tiene lista.
- [ ] El veredicto de firma de `/kit-estado` SHALL coincidir con el de `verifica.sh --comprueba` en
      los cuatro casos: nada verificado, firma de otro árbol, última en rojo y verde.
- [ ] Con un `HOME` temporal que simule los tres casos de versión —todo igual, instalada distinta
      de la que corre, marketplace distinto de la instalada—, `/kit-estado` y el informe de
      `verifica.sh` SHALL dar el mismo consejo, y en el segundo caso SHALL ser abrir una
      conversación nueva, sin `claude plugin update`.
- [ ] Fuera de un repositorio git, `estado.sh` SHALL decir que no lo es, salir con un código
      distinto de 0 y no crear nada.
- [ ] El digest del hook SHALL salir byte a byte igual antes y después del cambio, sobre este
      repositorio y sobre uno temporal con un cambio activo con tareas pendientes.
- [ ] La sección «Actualizar» de `docs/INSTALACION.md` y el bloque «Para mejorar el kit» del
      `README.md` SHALL decir que hace falta una conversación nueva y que reanudar una no carga la
      versión nueva.
- [ ] `/kit-estado` SHALL aparecer en la tabla de comandos de `docs/PIEZAS.md` y en la lista de
      `commands/` del `README.md`.
- [ ] `/kit-verifica` en verde con `LANG=` y con `LANG=en_US.UTF-8`.

## Presupuesto

Ocho ficheros y varias capas —un script nuevo, la lib compartida, el hook, `verifica.sh` y doc—,
así que va por la fila «varios ficheros» de `docs/FLUJO.md`: proposal, delta y tareas; **una pasada
de revisor por rodaja**, y **el juez al final**, que es el caso en que paga. Si una ronda encuentra
fallos que causó el arreglo de la anterior, se para y se archiva con la deuda escrita.

---

## Enmienda del 2026-09-15: el banco del hook no fija los números del recuento

La revisión de la primera rodaja (GREEN) midió que el «Impact» de arriba afirma algo falso:
`verifica-contexto.sh` **no** fija el recuento de tareas. Mira si la línea `tareas:` sale o no, y la
trampa de `grep -c` en bash 3.2, pero no los números: cambiar el recuento para que cuente pendientes
en vez de hechas deja el banco en verde, con el hook de antes de este cambio y con el de ahora.
`design.md` repite la afirmación en la decisión 3 y en «Risks».

**Qué la sustituye.** Los números del digest los fija, en este cambio, el criterio que compara el
digest byte a byte con el de antes. Después de archivar no los fija nada, igual que antes de este
cambio, que es cuando se abrió el hueco. Y en `estado.sh`, que usará la misma función, tampoco: va
sin banco, que es un límite ya declarado.

**Lo que no se hace, y es una decisión.** No se añade un caso al banco para cerrar el hueco: es
anterior a este cambio, y convertir un hallazgo en una pieza de banco por reflejo es lo que la casa
decidió no hacer. Si el owner lo quiere, es un caso corto en `verifica-contexto.sh`.

No cambia el alcance ni los criterios de aceptación. Se escribe sin esperar al owner porque corrige
un hecho, no un acuerdo, y se le avisa en la sesión.

### Y una contradicción en la spec de versión, del mismo día

La revisión de la segunda rodaja (AMBER) encontró que las cláusulas 1 y 2 del requisito de versión
de `estado-del-kit` chocaban en un caso: la instalada no es la que corre **y** el marketplace trae
otra. La 1 prohibía aconsejar `claude plugin update`; la 2 lo exigía. El código ya seguía la 2, y es
la única lectura que aconseja bien: una conversación nueva sin actualizar cargaría una versión vieja.

**Esta sí toca el acuerdo**, porque elige entre dos lecturas del texto. La cláusula 1 pasa a decir su
condición completa —que el marketplace traiga la misma que la instalada— y la 2 dice que manda en el
caso de las dos a la vez. Lo que dice «What Changes» no cambia, y el código tampoco. Se escribe ya
porque la otra lectura aconsejaría mal, y queda pendiente del visto bueno del owner, a quien se le
pregunta en la sesión.

### Decisiones del owner, del mismo día

- **La cláusula de versión de arriba:** visto bueno, tal cual.
- **El índice de git.** La revisión de la tercera rodaja (AMBER) midió que `/kit-estado` puede
  refrescar `.git/index`. `GIT_OPTIONAL_LOCKS=0` lo respeta `git status`, pero no —medido— el
  `git diff HEAD` con el que `verifica.sh --comprueba` calcula la huella de la firma, que refresca
  la caché del índice igual. La cláusula 2 del requisito «solo lee» prometía no modificar ningún fichero. Se le
  presentaron dos salidas —declararlo como límite, o cambiar la huella, que toca la firma, la puerta
  y el hook— y **eligió declararlo**. La cláusula pasa a decir «del árbol de trabajo», y el refresco
  queda escrito como límite en la spec, en la cabecera de `estado.sh` y en el comando. Lo mismo vale
  para el «no escribe nada» del «What Changes» de arriba y de los «Goals» de `design.md`. Lo
  stageado no cambia.
- **Reanudar una conversación.** La segunda pasada de la cuarta rodaja (AMBER) midió que el acuerdo
  afirma en absoluto algo que solo se comprobó en un caso: reanudar desde el historial de la app.
  Con `--continue` o `--resume` no lo ha medido nadie. Se le presentaron tres salidas —enmendar al
  condicional, mantener el absoluto o medirlo antes— y **eligió el condicional**. La cláusula 1 del
  requisito de versión de `estado-del-kit` pasa a decir que una reanudada *puede* seguir con la
  versión con la que empezó. El criterio de aceptación de la doc («que reanudar una no carga la
  versión nueva») y la frase del «What Changes» («reanudar una conversación conserva la versión…»)
  se leen desde aquí en ese mismo condicional. Lo que se aconseja —abrir una conversación nueva— no
  cambia.
