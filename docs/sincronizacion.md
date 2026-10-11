# Sincronización del repositorio

Reglas de quién escribe dónde, para que la copia local y el remoto no se
separen y para que el control quede del lado de quien trabaja en local.
Escrito el 2026-10-11.

## Fuente de verdad

`origin/ajustes-octubre`. Es la única rama de trabajo. `main` conserva la
versión revisada con la etiqueta `informe-factibilidad-v1` y no se toca hasta
el paquete P7.

## Reglas del asistente

1. Escribe **solo** en `ajustes-octubre`, con commits ordinarios.
2. **Nunca** `push --force`, **nunca** reescribe historia, **nunca** empuja a
   `main`, **nunca** mueve ni borra etiquetas. Si alguna vez hace falta
   reescribir historia, la ejecuta quien trabaja en local, no el asistente.
3. Hace `pull` antes de escribir, de modo que construye sobre los commits
   locales ya subidos y no sobre una copia vieja.
4. Avisa en cuanto empuja algo. A partir de ese aviso queda un `pull`
   pendiente.
5. No agrega microdatos, archivos grandes ni documentos de terceros.

Consecuencia práctica: nada de lo que hace el asistente es irreversible. Todo
es un commit que se deshace con `git revert <hash>`.

## Rutina local

Al empezar un brote:

    git pull --ff-only origin ajustes-octubre

Al terminarlo:

    git add -A && git commit -m "..." && git push origin ajustes-octubre

## Ver el estado en una línea

    git fetch -q origin && git status -sb && git rev-list --left-right --count origin/main...origin/ajustes-octubre

La primera línea dice si la copia local está adelante o atrás del remoto. Los
dos números dicen cuántos commits tiene `main` que no estén en
`ajustes-octubre` y al revés, en ese orden. El primero debe ser siempre 0: si
no lo es, alguien escribió en `main` y hay que mirarlo antes de seguir.

## Si `pull --ff-only` es rechazado

Significa que hay commits locales sin subir. No es un problema:

    git pull --rebase origin ajustes-octubre
    git push origin ajustes-octubre

Y conviene decirlo, para que el asistente haga `pull` antes de volver a
escribir.

## Verificar contra un clon nuevo

Al cerrar un brote importante, comprobar que lo que está en el remoto es lo que
se cree que está:

    git clone --depth 1 -b ajustes-octubre https://github.com/maicel1978/analisis_ENGIH2018 C:\temp\verificacion

Y revisar ahí los archivos que importan. Un `push` que no se verificó contra un
clon nuevo no está verificado.
