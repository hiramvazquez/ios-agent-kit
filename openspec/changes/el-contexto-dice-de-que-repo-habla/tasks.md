# Tareas

Cada tarea se cierra con `/kit-revisa` sobre su rodaja, no al final del cambio.

- [ ] 1. Banco de pruebas para el hook, ANTES de tocarlo. Monta tres repos temporales —uno
      sin `openspec/`, uno con `openspec/` y sin cambio activo, uno con cambio activo—, le
      pasa un prompt por stdin y comprueba el `additionalContext` que sale. Va primero
      porque es lo que hace falsificables los criterios, y porque debe salir rojo contra el
      script actual en los sitios esperados y verde en el caso que no puede romperse.

- [ ] 2. El digest nombra el repositorio del que habla. Es la línea que convierte una
      afirmación falsa sobre el trabajo en una afirmación cierta sobre otro repo.

- [ ] 3. Separar «no usa OpenSpec» de «lo usa y no hay cambio activo». La orden
      `/opsx:propose` solo sale en el segundo caso.

- [ ] 4. El caché sale del repositorio observado: a un directorio del usuario, con el
      repositorio en la clave. Aquí es donde hay que comprobar que dos repos no se sirven el
      caché del otro — es el fallo que introduce este movimiento si se hace mal.

- [ ] 5. El hook deja de crear nada dentro de un repositorio que no da señales del kit.
      Comprobado con `git status` limpio después de correrlo.

- [ ] 6. La cabecera del script, al día: hoy dice que inyecta «tres cosas y ninguna más» y
      no menciona que escribe en disco. Si sigue escribiendo, lo dice; y dice dónde.

- [ ] 7. Banco de pruebas en verde, y comprobado que cada prueba nueva falla contra el
      script sin arreglar. Una a una, no en bloque.
