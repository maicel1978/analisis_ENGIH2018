# Lista de revisión pendiente

Qué hay que mirar antes de dar por cerrado el informe final y el manual técnico.
Levantada el 2026-10-12. Se va tachando.

Está ordenada por lo que más daño haría si estuviera mal. Los apartados A y B
son los que bloquean el cierre; C y D pueden esperar.

---

## A. Las ocho figuras del informe

Todas compilan. **Ninguna ha sido mirada.** Compilar solo prueba que el código
corre, no que la figura comunique. Abrir
`C:\proyectos\output\reports\INFORME_final.html` y recorrerlas.

Lo que hay que buscar en todas: etiquetas que se salen del área, texto
encimado, leyendas que tapan datos, escalas que no discriminan, y categorías
que aparecen como `NA`.

- [ ] **Figura 1 · Cobertura de composición por nutriente** (Factibilidad).
      Barras horizontales con el porcentaje al final. *Comprobar:* que la
      etiqueta numérica no se corte en la barra más larga; que ningún nutriente
      aparezca con nombre técnico en vez de su etiqueta.

- [ ] **Figura 2 · Riesgo por nutriente** (Riesgo). Punto con segmento de
      intervalo de confianza. *Comprobar:* que los segmentos se vean —si los
      intervalos son muy estrechos quedan ocultos bajo el punto y entonces el
      segmento no aporta—; que la etiqueta numérica no se salga a la derecha.

- [ ] **Figura 3 · Aporte de cada grupo a cada micronutriente** (Grupos). Mapa
      de calor. **Es la figura más importante del informe.** *Comprobar:* que
      se lean los nombres de grupo en el eje vertical; que los números blancos
      sobre celdas claras sean legibles —si no lo son, hay que cambiar el
      umbral o el color del texto—; que ninguna columna quede casi vacía de
      números, lo que indicaría que el umbral del 5% es demasiado alto.

- [ ] **Figura 4 · Mapa bivariado de cobertura y consumo** (Vehículos).
      *Comprobar:* que se distingan las clases de color; que la leyenda
      bivariada se entienda sin explicación.

- [ ] **Figura 5 · Gradiente por quintil bajo los dos criterios**
      (Desigualdad). Dos líneas. *Comprobar:* que se crucen de forma visible,
      porque el cruce es el argumento; que los colores se distingan.

- [ ] **Figura 6 · Los dos coropléticos de folato** (Desigualdad). Van
      apilados, no lado a lado. *Comprobar:* que la leyenda **impresa dentro de
      cada imagen** sea legible al ancho del documento. Si no lo es, hay que
      regenerar los mapas sin leyenda incrustada, que es la tarea M7 de la hoja
      de ruta.

- [ ] **Figura 7 · Escalera de escenarios** (Escenarios). Una línea por
      nutriente a través de los siete escenarios. *Comprobar:* que las
      etiquetas del eje horizontal (`0`, `1a`, `1b`, `1c`, `2a`, `2b`, `3`) se
      entiendan, o si hace falta una nota que las traduzca; que la leyenda de
      colores no tape la figura.

- [ ] **Figura 8 · Razón entre quintiles extremos por escenario**
      (Escenarios). *Comprobar:* que la línea de referencia en 1 se vea; que
      las etiquetas numéricas no se salgan.

---

## B. Las afirmaciones del texto contra las cifras

El texto hace afirmaciones cualitativas que las cifras tienen que sostener. Las
escribí a partir de los resultados conocidos, pero **sin ver la corrida**. Cada
una de estas frases es falsable mirando su propia tabla o figura, en la misma
página.

- [ ] *«La norma vigente desplaza la proporción bajo el requerimiento, pero la
      deja todavía en el entorno de la mitad.»* Contrastar con la Figura 7.
- [ ] *«Extender la norma a todos los derivados del trigo añade un
      desplazamiento menor.»* Misma figura.
- [ ] *«Los escenarios con niveles de la OMS producen un desplazamiento
      mayor.»* Misma figura.
- [ ] *«El zinc, la B12 y la vitamina A permanecen prácticamente invariables a
      lo largo de los escenarios de la norma nacional.»* Misma figura.
- [ ] *«Solo la propuesta que incorpora arroz los desplaza.»* Misma figura.
- [ ] *«El arroz lleva la razón entre quintiles prácticamente a la unidad.»*
      Figura 8.
- [ ] *«Las vitaminas D y E son las de cobertura más baja.»* Figura 1.
- [ ] *«El rango de inadecuación cubre casi toda la escala.»* Figura 2.
- [ ] *«Los cereales y raíces son prácticamente irrelevantes para los
      nutrientes de origen animal.»* Figura 3.
- [ ] *«El gradiente socioeconómico se invierte entre criterios.»* Figura 5.
- [ ] *«La cobertura del arroz y la del trigo no dejan zonas desatendidas.»*
      Tabla de vehículos y Figura 4.

Si alguna no se sostiene, es error de redacción mío y se corrige sin discutir
el dato.

---

## C. Lo que solo usted puede juzgar

No son errores de código ni de cifras: son juicios de contenido.

- [ ] **La tabla de instrumentos normativos** de la Introducción. ¿Están bien
      descritos los niveles, los instrumentos y el estado de vigencia? ¿Falta
      algún vehículo que debería estar?
- [ ] **La afirmación sobre el azúcar**: norma obligatoria desde 2004, sin
      aplicación verificable, etiqueta observada sin declaración de vitamina A.
      ¿Está dicho de forma que se sostenga ante el ministerio?
- [ ] **El arroz presentado como propuesta y no como norma.** ¿Es exacto para
      2018?
- [ ] **Las siete conclusiones**, una por una. ¿Alguna afirma más de lo que el
      análisis sostiene?
- [ ] **El apartado de implicaciones.** Es donde el informe se acerca más a
      recomendar. ¿Se queda del lado correcto de la línea?
- [ ] **La ubicación de la tabla de normas.** Hoy es la Tabla 1 y está en la
      Introducción. Decidir si se mueve a Métodos, donde le corresponde por ser
      un parámetro de los escenarios.

---

## D. Lo que falta compilar

- [ ] **Manual técnico.** `quarto render reports/MANUAL_tecnico.qmd`. Nunca se
      ha compilado. Hay que medir las páginas contra las 20 a 30 que pide el
      TdR 18; la estimación es que se queda corto y habrá que ampliar.
- [ ] Comprobar que no queda ningún comentario `<!--` en los dos documentos
      antes de entregarlos. Es M6 de la hoja de ruta.

---

## E. Decisiones que no son revisión

Están documentadas con sus opciones y no se degradan por esperar, pero no se
cierran solas.

- [ ] **Visibilidad del repositorio** y qué hacer con los microdatos
      versionados. Opciones en el bloque de decisión abierta de la hoja de ruta.
- [ ] **El PR de la plataforma**, `fortificacion#1`. Defensivo, no urgente.
- [ ] **Los comentarios de revisión**: hace falta su texto para escribir el
      anexo de respuesta, que es lo último que le queda al informe.
