# Tareas

Cada tarea se cierra con `/kit-revisa` sobre su rodaja, no al final del cambio.

- [x] 1. Un banco de pruebas para la puerta, ANTES de tocarla. Hoy no existe ninguno: el
      script se ha cambiado a ojo desde que nació. Un `scripts/verifica-puerta.sh` que monte
      repos temporales —uno con firma válida, otro sin firma— y le pase a la puerta cada
      forma de invocación por stdin, comprobando `permissionDecision`. Va primero porque es
      lo que hace falsificables todos los criterios, y porque debe poder correrse contra el
      script SIN arreglar y salir rojo en los sitios esperados.

- [x] 2. Reconocer la invocación, no la subcadena. Que `git -C … commit` entre y que un
      `echo`, un `grep` o un heredoc que mencione las dos palabras no. Es el criterio 5 y el
      que hoy bloquea escribir documentación sobre la propia puerta.

- [x] 3. Derivar el repo del comando: `-C <ruta>`, `--git-dir`, y un `cd <ruta>` que
      preceda al commit en la misma línea. Caer al cwd solo cuando el comando no dice nada.
      Aquí es donde el caso normal —commit a secas en el repo de la sesión— tiene que quedar
      byte a byte como estaba.

- [x] 4. La puerta se desentiende de los repos sin `kit.conf`. Es el deadlock: hoy bloquea
      el commit y `verifica.sh` no puede firmar allí porque aborta por falta de ese mismo
      fichero. Ojo con no pasarse de largo — un repo CON `kit.conf` y sin firma tiene que
      seguir bloqueado, y esa es la prueba que hay que escribir junto a la otra.

- [x] 5. Auditar los `exit 0`. Uno por uno: cuál falla abierto, cuál cerrado, y el porqué
      escrito al lado. No es limpieza cosmética — hoy hay salidas silenciosas que no
      distinguen «esto no es un commit» de «no he podido averiguarlo».

- [x] 6. La cabecera del script y la sección del README, reescritas con los límites reales.
      `git -C` sale de la lista de lo que se cuela; lo que siga colándose entra en ella.

- [x] 7. `scripts/verifica-puerta.sh` en verde, y comprobado que cada prueba nueva falla
      contra el script sin arreglar. Uno a uno, no en bloque.
