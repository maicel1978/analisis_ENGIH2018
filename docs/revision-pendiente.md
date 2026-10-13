# Lo que depende de usted

Documento de tarea. Todo lo que no depende de usted está hecho o está en la cola
de `docs/hoja-de-ruta.md`. Aquí solo queda lo que nadie más puede hacer.

Está en orden de ejecución: cada bloque supone hecho el anterior. Se va tachando
y se sobrescribe; no se duplica.

Actualizado el 2026-10-13.

---

## 1. Correr la cadena

**Nada de lo escrito esta semana se ha ejecutado nunca.** El código nuevo
compila en apariencia, pero compilar es lo único que no se ha probado. Hasta que
esto corra, el informe es texto sin verificar.

```
cd C:\proyectos\analisis_ENGIH2018 && git pull
```

Correr en este orden. Si algo se detiene, pare y avise: una guarda que suena es
información, no un estorbo.

```
Rscript scripts/06_escenarios_fortificacion.R
```
Produce dos tablas nuevas que el informe ya cita: el **alcance de cada
combinación de vehículos** y el **reparto de hogares según cuántos adquieren**.
Si no salen, el informe no compila.

```
Rscript scripts/07_riesgo_inadecuacion.R
```
```
Rscript scripts/09_mapas.R
```
Los PNG de `media/mapas/` son anteriores a la numeración de provincias. Hasta
que esto corra, los mapas que usted ve son los viejos, sin número ni clave de
nombres. Si avisa que falta `ggspatial`: `install.packages("ggspatial")`.

```
Rscript scripts/diagnostico_outliers.R
```
Mide cuánto retira la exclusión de valores atípicos. **La cifra que importa es
`pct_retirado` por nutriente.** Si es de pocas décimas, el Anexo B del informe
queda cerrado con ella. Si pasa de un punto, hay que rehacer 04 a 07 sin la
exclusión y comparar: eso es un brote aparte y hay que decidirlo.

```
quarto render reports/INFORME_final.qmd
```
```
quarto render reports/MANUAL_tecnico.qmd
```
El manual **nunca se ha compilado**. Al salir, cuente las páginas: el TdR 18
pide de 20 a 30. La estimación es 20 a 24, pero es una estimación.

- [ ] La cadena corre completa sin que se detenga ninguna guarda
- [ ] `pct_retirado` anotado: ___________
- [ ] Páginas del manual: ___________

---

## 2. Mirar las figuras

Compilar prueba que el código corre, no que la figura comunique. **Ninguna de
las ocho se ha mirado.** Abra el HTML y recórralas.

En todas: etiquetas que se salen del área, texto encimado, leyendas que tapan
datos, escalas que no discriminan, categorías que aparecen como `NA`.

- [ ] **Fig. 1 · Cobertura de composición por nutriente.** Que la etiqueta no se
      corte en la barra más larga; que ningún nutriente salga con nombre técnico.
- [ ] **Fig. 2 · Riesgo por nutriente.** Que los segmentos de intervalo se vean;
      si son muy estrechos quedan bajo el punto y entonces no aportan.
- [ ] **Fig. 3 · Aporte de cada grupo a cada micronutriente.** *La figura más
      importante del informe.* Que se lean los nombres de grupo; que los números
      blancos sobre celdas claras sean legibles; que ninguna columna quede casi
      vacía, lo que indicaría que el umbral del 5% es alto.
- [ ] **Fig. 4 · Mapa bivariado.** Que se distingan las clases; que la leyenda se
      entienda sin explicación.
- [ ] **Fig. 5 · Gradiente por quintil bajo los dos criterios.** Que el cruce se
      vea, porque el cruce es el argumento.
- [ ] **Fig. 6 · Los dos coropléticos de folato.** Que la clave de provincias sea
      legible al ancho del documento.
- [ ] **Fig. 7 · Escalera de escenarios.** Que las etiquetas del eje (`0`, `1a`,
      `1b`, `1c`, `2a`, `2b`, `3`) se entiendan o haga falta una nota.
- [ ] **Fig. 8 · Razón entre quintiles extremos por escenario.** Que la línea de
      referencia en 1 se vea.

Y las dos tablas nuevas, que nadie ha visto nunca:

- [ ] **Alcance combinado de vehículos.** Si las tres combinaciones dan
      prácticamente lo mismo, la tabla dice que los mismos hogares compran todo y
      hay que escribirlo así. Si abre un hueco, ese hueco es el hallazgo.
- [ ] **Reparto por número de vehículos.**

---

## 3. Contrastar el texto contra las cifras

Estas frases están escritas **sin haber visto la corrida**. Cada una es
falsable mirando su propia figura, en la misma página. Si alguna no se sostiene,
es error de redacción y se corrige sin discutir el dato.

- [ ] «La norma vigente desplaza la proporción bajo el requerimiento, pero la
      deja todavía en el entorno de la mitad.» → Fig. 7
- [ ] «Extender la norma a todos los derivados del trigo añade un desplazamiento
      menor.» → Fig. 7
- [ ] «Los escenarios con niveles de la OMS producen un desplazamiento mayor.»
      → Fig. 7
- [ ] «El zinc, la B12 y la vitamina A permanecen prácticamente invariables a lo
      largo de los escenarios de la norma nacional.» → Fig. 7
- [ ] «Solo la propuesta que incorpora arroz los desplaza.» → Fig. 7
- [ ] «El arroz lleva la razón entre quintiles prácticamente a la unidad.» → Fig. 8
- [ ] «Las vitaminas D y E son las de cobertura más baja.» → Fig. 1
- [ ] «El rango de inadecuación cubre casi toda la escala.» → Fig. 2
- [ ] «Los cereales y raíces son prácticamente irrelevantes para los nutrientes
      de origen animal.» → Fig. 3
- [ ] «El gradiente socioeconómico se invierte entre criterios.» → Fig. 5
- [ ] «La cobertura del arroz y la del trigo no dejan zonas desatendidas.»
      → Tabla de vehículos y Fig. 4

Y una del anexo, que depende de una cifra que el documento calcula al compilar:

- [ ] **Correlación de rangos entre los dos criterios provinciales.** La lámina
      de la presentación la muestra. Si es alta, los dos criterios ordenan el
      territorio casi igual y la frase que acompañe a los dos mapas tiene que
      decir eso, no lo contrario.

---

## 4. Juicios de contenido

No son errores de código ni de cifras. Nadie más los puede emitir.

- [ ] **La tabla de instrumentos normativos** de la Introducción. ¿Están bien los
      niveles, los instrumentos y la vigencia? ¿Falta algún vehículo?
- [ ] **La afirmación sobre el azúcar**: norma obligatoria desde 2004, sin
      aplicación verificable, etiqueta sin declaración de vitamina A. ¿Se sostiene
      ante el ministerio?
- [ ] **El arroz como propuesta y no como norma.** ¿Es exacto para 2018?
- [ ] **Las siete conclusiones**, una por una. ¿Alguna afirma más de lo que el
      análisis sostiene?
- [ ] **El apartado de implicaciones.** Es donde el informe más se acerca a
      recomendar. ¿Se queda del lado correcto de la línea?
- [ ] **La ubicación de la tabla de normas.** Hoy es Tabla 1 en la Introducción;
      por ser un parámetro de los escenarios, su sitio es Métodos.

---

## 5. Decisiones abiertas

Las cuatro primeras dependen de terceros y su corte propio fue el **15 de
octubre**. Si ese día no hay respuesta, se cierra con los supuestos actuales y se
declaran en el informe. No se espera.

- [ ] **Valores de referencia**: Requerimiento Promedio Estimado del IOM frente
      a Requerimiento Promedio Armonizado. Es sustituir `valores_referencia.csv`
      y recompilar; altera **todas** las estimaciones de riesgo. Mientras no se
      resuelva, la lista de referencias del informe declara la edición del IOM
      como pendiente de confirmar.
- [ ] **Biodisponibilidad del hierro**: 10%, 18%, o ambas como rango.
- [ ] **Documento normativo del arroz**: obtenerlo o mantener el escenario como
      análisis de sensibilidad.
- [ ] **Fuente citable** para las fracciones de harina en pan, pastas y galletas.

Estas tres son enteramente suyas:

- [ ] **Visibilidad del repositorio y los microdatos versionados.** Sigue
      abierto: `analisis_ENGIH2018` es público y tiene 127 MB de microdatos de
      hogar rastreados desde el 6 de septiembre, en las dos ramas. El paso
      reversible e inmediato es ponerlo en privado. Las opciones y sus
      consecuencias están en el bloque de decisión abierta de la hoja de ruta.
      **Es lo de mayor consecuencia de toda esta lista.**
- [ ] **`INFORME_factibilidad`: corregir o congelar.** Está entregado. Si se
      congela, se queda como está y la etiqueta `informe-factibilidad-v1` lo
      conserva. Si se corrige, hay seis puntos suyos pendientes: la convención
      `n (%)`, el registro del texto, el caldo de pollo ya resuelto en campo, el
      agua purificada que no es alimento, la sección 11.2 a documento interno, y
      la bibliografía. Más las diez apariciones de «elaboración propia», que
      **solo** quedan en ese documento.
- [ ] **Los dos PR de la plataforma.** `fortificacion#1` es defensivo. El #2
      lleva ahora la corrección del módulo 24: el método que se enseña pasa a ser
      el del análisis en cuatro puntos, incluida una tabla de factores EMA
      atribuida a INCAP/WFP que el proyecto no usa. Quedan de ejemplo las dos
      tablas auxiliares de conversión y porción comestible, que no se pueden
      poner en línea; **publicarlas o no depende de qué se pueda publicar de los
      parámetros**, y eso es decisión suya.

---

## 6. Cierre

- [ ] Comprobar que no queda ningún `<!--` en los documentos renderizados. Los
      comentarios HTML **sobreviven al renderizado** y quedan visibles en el
      código fuente del entregable. El 11 de octubre se encontraron diez.
      `findstr /c:"<!--" INFORME_final.html`
- [ ] Fusión de `ajustes-octubre` a `main` y etiqueta de cierre.
- [ ] **El README de `main` conserva la conclusión sobre el trigo anterior a la
      corrección de la línea base.** Es un error visible en la rama pública.
