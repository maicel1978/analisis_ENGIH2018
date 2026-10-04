# Hoja de ruta — Proyecto ENGIH 2018 (Consumo y Nutrición, WFP)

**Congelada el:** 2026-09-03
**Última actualización:** 2026-10-03
**Objetivo final:** artículo científico + dashboard de apoyo a decisiones, siguiendo el marco ampliado de Tang et al. (2021) sobre la base metodológica de Imhoff-Kunsch (2012).

Este documento fija el alcance acordado hasta ahora. Cualquier cambio de alcance debería reflejarse acá explícitamente antes de asumirse en el trabajo diario — si algo cambia, se edita esta hoja, no se improvisa por fuera de ella.

---

## PRIORIDAD ACTUAL (leer esto primero, antes que Fase 0 de abajo)

**Estado al 2026-10-03.** Alcance vigente: lista de tareas pendientes enviada
por el supervisor tras la reunión de revisión (numeral 4 de los TdR). Cierre
de la consultoría: 2026-10-23 (contrato hasta 2026-10-25).

**Método de trabajo.** Rama `ajustes-octubre`; `main` conserva la versión
revisada (etiqueta `informe-factibilidad-v1`). Un bloque por commit. Antes de
cada bloque se declara el efecto esperado sobre las cifras de control
(36.840 / 303.408 / 8.774); si la corrida no coincide, se detiene.

**Fase A — aditiva, no cambia cifras existentes (5–7 oct)**

- [x] A1. Zinc, B12, D y E en `05`; función de composición única. Cobertura en gramos: zinc 96,0%; B12 94,1%; D 89,1%; E 83,0%.
- [x] A2. Harina de maíz, avena y sal como vehículos.
- [x] A3. Provincia arrastrada en `01`, `04` y el diseño muestral (32
      provincias). No es dominio de estimación de la encuesta: de 35 a 1.341
      hogares y de 4 a 160 UPM por provincia. La precisión se evalúa
      en C3.
- [ ] A4a. `catalogo_grupos`, `alimento_agrupado` y `grupo_mddw` en el crosswalk.
- [x] A5. Tabla de parámetros normativos por vehículo (`data/raw/parametros_normativos.csv`).

**Fase B — cambia cifras (7–9 oct)**

- [ ] B1. Factores de conversión: plátano, guineo y resto de la cola.
- [ ] A4b. Herencia de composición por grupo.
- [x] B2. Regla de agotamiento adoptada como estimación principal (2026-10-04).
      La disponibilidad neta prevista no aplica: la pregunta 9 de la Sección 2
      es inventario inicial menos final en el 98,3% de las filas y el
      inventario final no incluye las compras de la semana, de modo que
      `inicial + adquisiciones - final` es la suma que ya se calculaba.
      Regla: si al día 8 queda existencia inicial de un alimento almacenable,
      lo adquirido esa semana se marca como almacenado y no se cuenta.
      Efecto (sin ponderar): energía mediana 2.153 a 2.118 kcal; media 2.755 a
      2.667; hogares sobre 6.000 kcal 572 a 509; bajo 500 kcal 296 a 297.
      Gramos excluidos: aceite 13,4%; pastas 9,7%; azúcar 9,0%; arroz 6,5%.
      La suma simple se conserva como variante de sensibilidad.
- [x] B3. Plausibilidad de la energía por hogar (2026-10-04): columna
      `energia_plausible` (500 a 6.000 kcal por EMA y día). Se marca y no se
      excluye. Quedan fuera del rango 806 hogares (9,2%): 297 por debajo y 509
      por encima. Los criterios basados en la propia distribución dan límites
      implausibles (3 MAD en logaritmo: 351 a 12.792 kcal). La exclusión no es
      neutra entre grupos: fuera del rango queda el 6,0% del quintil 1 y el
      16,5% del quintil 5, por el extremo superior (2,7% frente a 12,1%); el
      inferior es parejo (3 a 4%). Excluir sesgaría la comparación por quintil.
      El riesgo de ingesta inadecuada se reportará con y sin el filtro.
- [x] B4. Equivalente de mujer adulta (2026-10-04). Menores de un año: 649 kcal
      (niños) y 600 (niñas), promedio anual de FAO/WHO/UNU 2004, en lugar del
      valor provisional de 600. Afecta a 505 menores en 501 hogares (5,6%);
      el cambio es de 0,02 EMA por niño varón. Embarazo y lactancia no son
      ajustables: el cuestionario no los registra. Cota de la lactancia: hasta
      505 kcal (0,22 EMA) en, como máximo, ese 5,6% de hogares. El valor de
      niñas queda por contrastar mes a mes con la tabla de la fuente.
- [ ] B5. Trigo en equivalentes de harina: pan, pastas y galletas convertidos
      a gramos de harina con factores de contenido de fuente citable.

**Fase C — análisis (12–16 oct)**

- [ ] C1. Escenarios: sin fortificación, niveles recomendados por la OMS y
      norma nacional. Sin aceite. Yodo desde la sal como escenario poblacional.
- [ ] C2. Riesgo de ingesta inadecuada y densidad por 1.000 kcal: cálculo
      hecho en `scripts/06_riesgo_inadecuacion.R` (punto de corte; probabilidad
      para hierro; proporción sobre el límite superior). Los valores de
      referencia de `data/raw/valores_referencia.csv` y
      `hierro_requerimiento.csv` son PROVISIONALES (IOM): se sustituyen por los
      de la metodología MIMI. Resultados no citables hasta entonces ni hasta
      cerrar C1: el folato muestra 23% bajo el requerimiento y 38% sobre el
      límite superior a la vez, artefacto del mapeo del arroz. La
      biodisponibilidad del hierro (10% o 18%) cambia el resultado de 54% a 27%.
- [ ] C3. Desagregación: hecha en `06` para región, zona, quintil y provincia.
      Región, zona y quintil sin celdas de precisión baja (semiamplitud máxima
      3,6 puntos). Provincia: 47 de 256 celdas con precisión baja. Faltan los
      mapas y la desagregación del consumo de vehículos.
- [ ] C4. Análisis por grupos de alimentos.

**Fase D — redacción y cierre (15–23 oct)**

- [ ] D1. Informe final: reestructurar por preguntas, recompilar, comparar
      contra la versión etiquetada y responder los comentarios de revisión.
- [ ] D2. Fusión a `main`, README y productos finales.

**Estructura del informe final (acordada el 2026-10-04).** Un solo documento
principal: el informe de factibilidad evoluciona a informe final con formato
de artículo. R1 a R5 quedan como cuadernos de cálculo y no se pulen.

1. Introducción: problema, preguntas e hipótesis, objetivos.
2. Métodos: breves; fuentes y cadena de cálculo; el detalle va a anexo.
3. Resultados: un apartado por pregunta, con una tabla o figura principal.
4. Discusión: hallazgo por pregunta, contraste con la literatura,
   limitaciones, implicaciones.
5. Conclusiones.
Anexos: calidad de datos y adaptaciones; decisiones adoptadas; respuesta a
los comentarios de revisión (sección original, respuesta, ubicación nueva);
reproducibilidad.

Preguntas: la de factibilidad (¿permite la encuesta el análisis, con qué
cobertura?) más las seis preguntas estratégicas de
`docs/vision-y-arquitectura.md`. Hipótesis solo donde se formuló antes de
ver el dato (efecto distributivo de un vehículo de consumo transversal).

**Datos externos por conseguir:** consumo promedio de sal en el país;
yodación de la sal de los cubos de caldo (etiqueta y fabricante); factores
de contenido de harina en pan, pastas y galletas.

**Decisiones adoptadas el 2026-10-03** (reversibles por parámetro):

- Agrupación en dos niveles; herencia de composición desde la variedad con
  más registros del grupo, marcada como heredada.
- Clasificación MDD-W (FAO 2021) usada para análisis por grupos; el indicador
  no se reporta por no ser aplicable a adquisiciones del hogar.
- Línea base 2018: harina de trigo, harina de maíz y sal fortificadas; arroz
  y aceite sin fortificar; azúcar como escenario de sensibilidad.
- Escenarios (revisado el 2026-10-04, por comentario de revisión): sin
  fortificación, niveles OMS y norma nacional. La propuesta nacional de
  reglamento de arroz se añade como fila adicional. El aceite no se modela.
- Disponibilidad neta como estimación principal solo si reduce la cola de
  más de 6.000 kcal sin producir una energía mediana implausible.
- Sal y yodo (revisado el 2026-10-04): la sal no figura en la Sección 2 y
  solo el 13,3% de los hogares la registra en el diario (mediana de 26,5 g
  por EMA y día entre quienes la registran): la encuesta mide frecuencia de
  compra, no consumo. El aporte de yodo se modela como escenario poblacional:
  consumo promedio de sal de fuente externa por el rango de la norma
  (20–50 mg/kg). No se estima distribución por hogar ni riesgo.
- Precisión (revisado el 2026-10-04): en proporciones, la celda se marca si
  tiene menos de 50 hogares o la semiamplitud del intervalo supera 10 puntos;
  el coeficiente de variación penaliza prevalencias bajas bien estimadas y se
  reserva para medias (umbral 30%). La provincia no es dominio de estimación.
- Valores de referencia: EAR de OMS/FAO; enfoque probabilístico en hierro.

**Supuestos pendientes de documento:** vigencia en 2018 y niveles del
reglamento de harina de maíz; aplicación efectiva de la norma de azúcar.

**Corrección:** la norma de azúcar es la NORDOM 602 (10–25 mg/kg de
vitamina A), no "NORDOM 606, 5–25 mg/kg" como figura más abajo.

**Sustituye a:** la "DECISIÓN ABIERTA (2026-09-10)" sobre línea base (Fase 0)
y la lista de "Decisiones a llevar a la reunión" (Fase 5). Ambas quedan como
registro histórico; rigen las decisiones del 2026-10-03.

**Criterios de trabajo vigentes:**

- *Avanzar con los datos como están, declarando la cobertura de cada cifra.*
- *Volver atrás solo cuando el arreglo es acotado, no requiere criterio nuevo y
  bloquea algo que ya se está por mostrar* — los tres a la vez.
- *Antes de escribir un entregable, fijar para quién es y qué decisión habilita.*
- *Verificar siempre que un archivo se reemplazó antes de renderizar:*
  `any(grepl("texto nuevo", readLines(ruta)))`.
- *Una afirmación que dejó de ser cierta es peor que un comentario mal
  redactado.* Al cambiar algo, revisar qué documentación lo daba por imposible.


## Fase 0 — Cerrar la base de datos (prerrequisito, en curso)

- [x] **HITO (2026-09-12): crosswalk Sec 3A cerrado, porción comestible completa y pipeline verificado de punta a punta.**

  1. **Cargados los 154 mapeos revisados + 15 correcciones manuales** (`99_aplicar_correcciones_crosswalk.R`). Sec 3A pasa de 253 a **407 alimentos mapeados de 769** (89.2% de los registros). Las 15 correcciones salieron de revisar uno por uno el bloque que `data/eda/revision_154_sugerencias.csv` había marcado "OK": 9 eran errores del tipo ya anticipado (parte del alimento, estado de preparación, grado de procesamiento) y 6 venían marcadas DUDOSA/NO. Ejemplos: Cereza → acerola (en RD "cereza" es acerola: 1600 vs 7 mg vit C/100g); Jamón ahumado apuntaba a jamón de **pavo**; Hígado de pollo apuntaba a **paté** envasado; Macarrones a pasta **enlatada** con queso. **Tasa real de error de la sugerencia automática: 9/148 = 6.1%** — cifra citable para justificar por qué la revisión manual no era opcional. Trazabilidad fila por fila en `data/eda/log_merge_crosswalk_2026-09-11.csv`.

  2. **+154 filas de porción comestible** (`98_completar_PC_lote154.R`, `food_factors.xlsx` 253 → 407). El merge anterior dejó 154 alimentos con `enhance_id` pero sin PC, así que **no entraban al cálculo pese a estar mapeados**: la cobertura efectiva seguía en 86.5%, no en 89.2%. Los 154 eran todos INCAP y todos tenían `EDIBLE` en la tabla — extracción determinista, sin criterio. Log en `data/eda/log_PC_lote154_2026-09-12.csv`. Mismo patrón que el lote de 109 del 10-09.

  3. **BUG SILENCIOSO corregido: `validado` con tres representaciones distintas** (`97_normalizar_tipos_crosswalk.R`). Al reescribir el crosswalk con `writexl` tras leerlo con `col_types="text"`, la columna quedó con "TRUE" (265 filas), "VERDADERO" (154, las recién cargadas) y "1" (1 fila). `01_import.R` filtra con `validado == TRUE`, así que **las 154 filas nuevas se habrían descartado sin aviso**: el pipeline habría corrido sin un solo error y reportado la cobertura anterior. Lo que lo atrapó fue un error *distinto* y ruidoso (tipos incompatibles en el join de Sec 2) que obligó a abrir el archivo. **Regla adoptada: no reescribir un Excel de entrada leyéndolo con `col_types="text"`** — convierte a texto columnas numéricas y booleanas y rompe supuestos aguas abajo. **Nota incómoda y útil: este fallo estaba anticipado por escrito en esta misma hoja desde el 10-09** (ver backlog del 10-09, "Tipado explícito en las lecturas de Excel", que recomienda `filter(validado %in% c(TRUE, 1))` en lugar de `== TRUE`). La hoja hizo su trabajo; falló el no consultarla antes de actuar. **Regla de proceso: antes de tocar un archivo de entrada, releer el backlog de Fase 0.**

  4. **CORRECCIÓN IMPORTANTE (2026-09-12, tras el primer render de R1): 89.2% es cobertura del *crosswalk*, NO del cálculo.** Son dos métricas distintas y en los mensajes de trabajo de ese día se usaron como si fueran la misma. La cifra citable en la presentación es la segunda: **Sec 3A entra al cálculo al 76.0%** (260,014 de 342,046 filas) y **Sec 2 al 90.7%** (43,393 de 47,837). El 89.2% mide qué proporción de los *registros* tiene alimento mapeado; el 76.0% mide cuántas *observaciones* tienen además FC, PC y no son atípicas — que es lo que exige la fórmula. **Si se presenta 89.2% como cobertura del análisis y alguien recalcula, la cifra se cae.** Regla derivada: al citar cobertura, decir siempre *de qué* (crosswalk / cálculo) y *de qué sección*.

  5. **Corrida completa verificada (12-09).** Sec 3A: 342,046 filas, 36,841 sin `enhance_id` (89.2% mapeado), 36,841 sin PC — **los dos números coinciden, confirmando que ya no queda alimento mapeado sin porción comestible**. Sec 2: 47,837 filas, 62 sin mapeo y 62 sin PC. Outliers: Sec 2 = 11, Sec 3A = 45. EMA: 8,892/8,892 hogares, mediana 3.04 **(sin ponderar; la mediana ponderada es 3,09 — ver el hito del diseño muestral)**. **Gramos por EMA: 303,407 registros** (era 296,969 el 10-09 y 254,905 el 08-09).

  6. **Cambió el cuello de botella.** Sec 3A tiene 48,684 filas sin factor de conversión contra 36,841 sin mapeo. **De aquí en adelante, el trabajo de cobertura rinde más en la tabla de FC que en el crosswalk.** Esto invierte la conclusión del 10-09, que decía que todo lo que quedaba por ganar estaba en el crosswalk: era cierto entonces, ya no.

- [x] **HITO (2026-09-10): dos bugs de corrupción silenciosa corregidos + guardas de integridad en el pipeline + cobertura de PC ampliada.** Origen: auditoría externa independiente (réplica del pipeline en Python), revisada y verificada punto por punto contra los archivos reales antes de aplicar nada.

  1. **Fan-out de 17,698 filas en Sec 3A (crítico).** En `data_raw_unidades.xlsx` hoja "Cuest. B Sec 3A", Pan sobado y Ají grande (cubanela) con unidad=1 tenían *dos* filas de FC cada uno (la mediana del crudo y el peso-por-unidad agregado el 08-09). El `left_join()` por `descripcion`+unidad duplicaba cada fila del crudo que coincidía: 9,131 de Pan sobado + 8,567 de Ají cubanela. Sec 3A pasaba de 342,046 a 359,744 filas y esos dos alimentos quedaban doble-contados aguas abajo. **Toda corrida posterior al 2026-09-08 y anterior a hoy produjo resultados corruptos.** Corregido retirando el FC de las dos filas viejas (45 g y 90.7 g), con el valor original conservado en `nota` y `validacion = RETIRADO_duplicado_clave`.
  2. **Las 3 filas de peso-por-unidad de Sec 2 nunca se aplicaron.** HUEVOS, PANES y GALLETAS SALADAS se agregaron el 08-09 sin la columna `variedad`, que es la clave del join de Sec 2. Se perdían 4,242 filas (2,637 + 1,090 + 515), incluido el 100% de los huevos comprados por unidad. **Corrige la afirmación del 08-09 ("ya funciona con la lógica existente sin tocar código"): era cierto para Sec 3A (une por `descripcion`) y falso para Sec 2 (une por código numérico).** Completadas `variedad` (15/1/3) y `frecuencia_datos`, verificadas contra las otras filas del mismo alimento.
  3. **Guardas de integridad en `01_import.R`.** Los tres errores de esta semana son del mismo tipo: una fila mal escrita en un Excel que el pipeline acepta en silencio. Se agregó `verificar_tabla_join()`, que **detiene la corrida** (`stop()`, no `warning()`) si una tabla de join tiene claves duplicadas o filas con FC y clave vacía; más `stopifnot()` de que el crudo no crece al unir (47,837 y 342,046). Confirmado en la corrida de hoy: "OK -- Sec 2: 82 filas" / "OK -- Sec 3A: 619 filas".
  4. **+109 filas de PC en `food_factors.xlsx` (144 → 253).** Se detectó que 109 alimentos ya tenían `enhance_id` validado pero no tenían fila de porción comestible, perdiendo ~8,760 filas del crudo por una ausencia puramente mecánica (71 con `EDIBLE` de INCAP; 38 de FNDDS a 1.00 por la convención ya documentada en la hoja). **Efecto estructural: "sin enhance_id validado" y "sin PC/edible" ahora son idénticos (Sec 3A: 46,012; Sec 2: 62) — el PC dejó de ser un cuello de botella independiente y todo lo que queda por ganar está en el crosswalk.** Corrige el ítem del 08-09 sobre las 54,772 filas sin PC.

  **Cifras de la corrida del 2026-09-10 (post-fix, `01`→`04`):**
  Sec 2: 47,837 filas | universal 22,316 | específica 21,108 | sin FC 4,413 | con FC sin PC 20 | **entran al cálculo 43,404 (90.7%)**.
  Sec 3A: 342,046 filas | universal 107,095 | específica 186,268 | sin FC 48,683 | con FC sin PC 39,742 | **entran al cálculo 253,621 (74.1%)**.
  Outliers marcados: Sec 2 = 11, Sec 3A = 45. Hogares con EMA: 8,892/8,892, mediana 3.04 sin ponderar.
  **Gramos por EMA: 296,969 registros** (era 289,249 antes de cargar el lote de 109, y 254,905 en el hito del 08-09 — cifra que quedó desactualizada al día siguiente).
  Commits: `8c243ce` (bloques 1-3), `be0fd32` (food_factors).

  **Regla adoptada hoy:** toda cifra del log va fechada y con la corrida de la que salió. Todo resultado de consumo o ingesta se cita junto a su % de cobertura (hoy: Sec 2 90.7%, Sec 3A 74.1%).

- [x] **HITO (2026-09-12): primer render de `R1_calidad_datos.qmd` con datos reales.** Reporte autogenerado (ninguna cifra escrita a mano), infraestructura compartida en `scripts/_comun.R`. Bug corregido en el camino: `pct()` no estaba vectorizada y fallaba dentro de `mutate()` — al vivir en el archivo común, se arregló una vez para los cinco reportes.

  **Resultado que desbloquea R3: los cuatro vehículos de fortificación están cubiertos casi al 100%.** Aceite 99.6% (Sec 2) / 97.2% (Sec 3A); Arroz 99.1% / 98.7%; Azúcar 100% / 99.6%; Harina de trigo 99.1% (Sec 3A). **R3 es defendible sin salvedad**, pese a que la cobertura general de Sec 3A sea 76%. Tiene sentido: los vehículos son básicos, se compran en unidades estándar y están bien representados en INCAP. Esto responde la pregunta abierta del 11-09 sobre si el hueco del 24% afectaba a los alimentos que importan. **No afecta.**

  **Estado del crosswalk según el reporte:** 769 filas, 407 con código, 308 con `tipo_equivalencia` (181 directa, 106 sustituto_por_criterio, 5 requiere_revision, 1 categoria_compuesta, **114 sin declarar** — el pendiente ya anotado).

- [ ] **PRIORIDAD ALTA DE COBERTURA — peso por unidad de plátano y guineo (decisión 2026-09-12: documentada y pospuesta, NO abandonada).** El primer render de R1 identificó exactamente dónde se pierde el 24% de Sec 3A. El motivo dominante es **falta de FC: 48,683 filas** (contra 33,303 sin mapeo). Y la cola está concentrada en pocos alimentos, todos ya anotados en el pendiente de "peso por unidad":

  | Alimento | Filas sin FC | Sección |
  |---|---|---|
  | Plátano verde | 7,690 | Sec 3A |
  | Guineo verde (guineíto) | 5,577 | Sec 3A |
  | Aguacate | 2,417 | Sec 3A |
  | Tomate Barceló o Bugalú | 1,982 | Sec 3A |
  | PLÁTANO VERDE | 1,836 | Sec 2 |
  | Plátano maduro | 1,815 | Sec 3A |
  | Ají gustoso o cachucha | 1,616 | Sec 3A |
  | GUINEITO VERDE | 1,513 | Sec 2 |
  | Apio planta, apio gusto | 1,449 | Sec 3A |
  | Naranja agria | 1,394 | Sec 3A |
  | Guineo maduro (banano) | 1,313 | Sec 3A |

  **Solo plátano y guineo (las cuatro variantes) suman ~16,400 filas — subirían Sec 3A de 76% a ~81%.** Es pesaje de mercado, metodología ya probada por el consultor (ají cubanela, cilantro), ~30 minutos de trabajo. **Decisión del 12-09: se pospone en favor de `05_ingesta_micronutrientes.R`**, porque el `05` es compromiso firme para el 16 y nunca ha corrido. Retomar en cuanto el `05` esté corriendo, o el domingo 14 si hay margen. *Cilantro (220g/bolsa) y ají cubanela (288g) ya están medidos en campo — mismo procedimiento.*

- [ ] **Dos alimentos sin mapeo que pesan mucho, con caminos distintos:**
  - **Caldo de pollo (Sopita Concentrada): 18,084 filas**, la mayor pérdida individual del proyecto por falta de mapeo. Ya hay dato de campo propio (etiqueta Knorr verificada: 1 cubito = 10g, 2,320mg sodio, 30kcal) pero **sin `ENHANCE_ID` completo** porque la etiqueta no trae el perfil de micronutrientes. Opciones: buscar equivalente en FNDDS, o declararlo excluido con justificación. **No dejarlo sin decisión escrita.**
  - **Agua purificada: 7,774 filas.** Nutricionalmente aporta cero, pero cuenta como observación y deprime la cobertura reportada. **Considerar una categoría explícita `sin_aporte_nutricional`** en vez de dejarla como "sin mapeo": cambia la lectura del indicador sin alterar ningún resultado, y es más honesto que ambas cosas se cuenten juntas.

- [ ] **Detalle menor de R1:** la tabla de atípicos muestra 0% por redondeo (45 de 260,059). Dar más decimales.

- [x] **HITO (2026-09-12): primera corrida de `05_ingesta_micronutrientes.R`. Hay ingesta aparente de micronutrientes por primera vez en el proyecto.** El script ya estaba escrito y versionado desde `8c243ce` (la hoja decía "sin empezar" — desactualizado); solo nunca se había corrido. Bug corregido para que corriera: los encabezados de FNDDS traen saltos de línea **dentro** del nombre (el de hierro es literalmente `Iron` + salto + `(mg)`), así que escribirlos literales fallaba. Ahora se resuelven **por patrón** con `stop()` si el patrón no identifica exactamente una columna — un cambio de formato en la fuente falla ruidosamente en vez de devolver la columna equivocada.

  **Cobertura de composición, por nutriente (no es uniforme, y eso es un hallazgo):** energía 100%, hierro 96.4%, folato 92.3%, **vitamina A 85.5%** de los gramos consumidos. La tabla de composición no cubre todos los nutrientes por igual, así que la vitamina A está más subestimada que la energía. **Se reporta siempre por nutriente, nunca como una cifra global.**

  **Ojo con el 100% de energía:** es 100% *de las filas que llegaron al `05`*, que ya venían filtradas por FC + mapeo + PC. La cadena completa es **76% (Sec 3A) × 100% (composición)**. La cifra citable sigue siendo 76%.

- [x] **HITO (2026-09-12): validación empírica del período de medición (PM).** Era una preocupación abierta: el formulario `docs/Formulario ENGIH B` declara un diseño, y los datos muestran otra cosa. **Resuelto con evidencia, no con lectura del PDF.**

  Los datos: Sec 3A tiene 8,731 hogares; solo 5,330 (61%) tienen registro en los 7 días. El resto tiene menos (1 día: 159 hogares; 2: 247; 3: 342; 4: 514; 5: 793; 6: 1,345). Hay además valores imposibles de `dia` (0, 12, 13, 14, 15, 16, 17, 18, 28), poquísimos registros pero existen y hay que declararlos.

  **La pregunta que decidía todo:** un hogar con 3 días de registro, ¿fue observado 3 días, o fue observado 7 y no compró nada en 4? Si fuera lo segundo, dividir entre 3 inflaría su consumo un 133%.

  **Test aplicado: energía mediana por número de días observados.** Resultado **plano** — 1 día: 2,050 kcal; 2: 2,120; 3: 1,935; 4: 2,168; 5: 2,149; 6: 2,085; 7: 2,189. Si el denominador estuviera inflando, los hogares de 1 día mostrarían ~7× más. No lo hacen. **Queda validado usar `dias_observados_hogar` como PM**, y la corrección que se hizo el 08-09 sobre el `PM = 1` era correcta.

  **Respuesta citable ante la pregunta "¿cuál es el período de medición?":** *el diseño declara 7 días, los datos muestran registro incompleto en el 39% de los hogares, y verifiqué contra los datos cuál interpretación se sostiene — la ingesta mediana es invariante al número de días observados, lo que confirma que el denominador es correcto.*

- [x] **HITO (2026-09-12): Sección 2 y Sección 3A NO son intercambiables ni sumables sin criterio. Cuantificado.** Daniel indicó explícitamente trabajar con **Sec 2** y Santiago con **Sec 3A**. Verificado que **ninguna de las dos indicaciones era errónea: las dos hacen falta.**

  | Variante | Hogares | Energía mediana | Energía media | Hierro | Folato | Vit. A | >6000 kcal |
  |---|---|---|---|---|---|---|---|
  | Sec 2 sola | 6,216 | **1,173** | 1,466 | 7.83 | 559 | 30.9 | 78 |
  | Sec 3A sola | 8,653 | **1,200** | 1,741 | 7.29 | 248 | 136 | 271 |
  | **Sec 2 + Sec 3A** | 8,774 | **2,153** | 2,755 | 14.2 | 811 | 173 | 572 |

  **Ninguna sección por separado es fisiológicamente plausible** (~1,200 kcal/EMA/día es la mitad del requerimiento). **La única variante creíble es la suma.** Las secciones son mayormente *complementarias*, no redundantes: capturan alimentos distintos (Sec 2 inventario de despensa, Sec 3A compras diarias), y se nota en el perfil — folato 559 vs 248, vitamina A 31 vs 136. Cada una aporta nutrientes distintos porque captura alimentos distintos.

  **Pero hay solapamiento parcial y real en almacenables.** En los 572 hogares con energía > 6,000 kcal, el arroz aparece **tres veces** en el top 15 (Arroz selecto y Arroz corriente en Sec 3A; ARROZ en Sec 2, este último con 386 hogares), y lo mismo aceite (posiciones 4 y 7), azúcar (5 y 9) y leche (8, 11, 12). **Tres de los cuatro vehículos de fortificación están afectados.**

  **Descomposición de la cola (78 + 271 = 349, pero la suma da 572):** **223 hogares (39% de la cola) nacen del solapamiento**; los otros 349 ya estaban en los datos crudos, sobre todo en Sec 3A — son **compras al por mayor** (un saco de arroz en un día), fenómeno real de las encuestas de adquisición, no un error del pipeline.

  **Decisión documentada:** reportar **la suma** como estimación principal (única plausible); **declarar el solapamiento con su magnitud** como limitación conocida que sobrestima arroz, aceite, azúcar y leche; **proponer la disponibilidad neta** (`cantidad_inicial + adquisiciones − cantidad_final`) como refinamiento para almacenables — los datos existen, `cantidad_inicial` y `cantidad_final` están en Sec 2. **Llevar a Daniel y Santiago como decisión suya, con esta tabla como evidencia.** No elegir una sección por cuenta propia: contradiría a uno de los dos supervisores.

  Salida reproducible: `data/clean/comparacion_variantes_seccion.csv`. El `04` conserva ahora la columna `seccion` (antes se perdía en el `bind_rows`), y el `05` produce las tres variantes con `stop()` si esa columna falta.

- [ ] **La media NO es la cifra a citar; la mediana sí.** Energía: mediana 2,153 vs media 2,755 kcal — la media está inflada por la cola. Regla para todos los reportes: **mediana como estimador central, y la media se muestra al lado para que la diferencia sea visible en vez de escondida.**

- [ ] **Control de atípicos a nivel de HOGAR (brecha real detectada 2026-09-12).** La detección actual de `03_transform.R` trabaja **por alimento**: un hogar puede acumular varios valores altos sin que ninguno sea individualmente extremo. Por eso pasan 572 hogares con energía implausible (máximos absurdos: 63,864 kcal, 439 mg de hierro, 65,351 µg de vitamina A) y 2 hogares en 0. **Agregar una guarda a nivel de hogar** sobre energía por EMA/día. No inventar un filtro arbitrario: la disponibilidad neta debería absorber buena parte, y lo que quede se declara.

- [ ] **`SUPUESTO "por 100 g" — VALIDADO empíricamente (2026-09-12).** El `05` lo declaraba como no verificado contra la documentación de INCAP/FNDDS. La energía mediana da **2,153 kcal/EMA/día**, fisiológicamente plausible: un error de factor 10 o 100 en cualquier eslabón de la cadena habría dado 200 o 20,000. Queda validado por consistencia. *Sigue pendiente confirmarlo contra la documentación fuente, pero ya no es un supuesto ciego.*

- [ ] **Hallazgo que refuerza la decisión de línea base, ahora con evidencia cuantitativa.** El perfil de la variante sumada es **folato alto (811 µg DFE, EAR ~320) y vitamina A baja (173 µg RAE, EAR ~500)** — exactamente la dirección que predice el problema del crosswalk: el arroz (alimento #1 de la dieta) mapeado a "enriquecido" con 386 µg folato/100g infla el folato; el azúcar mapeada a "sin fortificar" con vitamina A = 0 la deprime. **Deja de ser una observación teórica del crosswalk y pasa a ser efecto medible.** Frase para la reunión: no "el crosswalk asume un escenario que no corresponde a la norma", sino "asume ese escenario, y el efecto medible es folato sobrestimado y vitamina A subestimada, en estas magnitudes".

- [ ] **118 hogares sin ingesta** (8,774 de 8,892 con EMA). Tienen EMA calculado pero ninguna fila de consumo que sobreviviera los filtros. No es un error, pero hay que saber por qué antes de presentar.

- [x] **HITO (2026-09-12): `R3_cobertura_vehiculos.qmd` escrito y renderizado.** Cubre el numeral 4.2 de los TdR e implementa los indicadores 1 y 2 del sistema de evaluación.

  **Cobertura de vehículos (sin ponderar, sobre 8,774 hogares analizados):** Arroz **87.7%** (7,693 hogares), Aceite **87.3%** (7,662), Azúcar **78.6%** (6,900), Harina de trigo **8.0%** (700). Consumo mediano entre consumidores, en g/EMA/día: arroz 207.8, azúcar 48.0, aceite 41.9, harina 31.9. En los cuatro la media supera a la mediana (asimetría por compras al por mayor) — **se cita la mediana, con la media al lado**.

  **R3 es independiente de la decisión de línea base**, porque la cobertura pregunta *si el hogar consume arroz*, no si ese arroz estaba fortificado. Por eso sus cifras son estables aunque la línea base siga sin resolverse.

- [x] **HALLAZGO MAYOR (2026-09-12): la harina de trigo casi no se consume como producto en RD — 8% de los hogares, y CERO hogares en la Sección 2.** No es un vacío de datos: es el patrón de consumo dominicano. La harina llega al hogar **ya procesada**, sobre todo como pan.

  **Consecuencia de política, y es el argumento más fuerte de R3:** la norma dominicana obliga a fortificar la harina **en el molino**, y esa harina llega a la población dentro del pan. Un indicador construido sobre "harina de trigo" mide el consumo de un **insumo intermedio**, no la exposición al nutriente añadido. Medido así, se concluiría que el programa de fortificación de harina alcanza al 8% de los hogares.

  **Decisión adoptada (del consultor, no delegada — es definición de indicador, no cuestión nutricional):** el vehículo se define como **harina de trigo y sus derivados de consumo directo**, reportando ambas cifras. Resultado: **8.0% → 85.7%** (700 → 7,521 hogares). Los derivados que más pesan: Pan sobado (10,055 filas), Pan de agua (6,221), Galletas saladas (3,283 + 1,270 de Sec 2), Fideos (1,703).

  **Dos limitaciones declaradas en el propio reporte:** (a) la norma es obligatoria para harina de panificación pero **voluntaria** para pastas y galletas, así que la cifra ampliada es un **techo**; (b) sin **factores de receta** (cuánta harina contiene cada producto) la definición ampliada sirve para *alcance poblacional* pero **no** para estimar gramos de harina consumidos. Esos factores no están en la ENGIH — línea de trabajo identificada.

  **Trampa evitada, verificada:** el patrón ingenuo de derivados de trigo captura falsos positivos graves — **"Pasta de tomate" con 12,150 registros**, "Ajo en pasta", "Harinas de maíz", "Maicena", "Buen pan o castaña" (fruta de pan, no trigo) y los derivados de maíz. Con exclusiones explícitas quedan 67 alimentos y 26,935 registros; **sin ellas la cifra se infla ~47%**. Inclusiones y exclusiones viven en `_comun.R` (`TRIGO_INCLUIR` / `TRIGO_EXCLUIR`), auditables y modificables en un solo lugar.

- [x] **Bug corregido en `_comun.R` (2026-09-12): `pct()` colapsaba con denominador escalar.** Estaba escrito con `ifelse()` y la condición sobre `n`; `ifelse()` devuelve un resultado del largo de la **condición**, así que con `n` escalar (un total de hogares) todas las filas mostraban el mismo porcentaje. **En R1 no se notó** porque allí `n` siempre era una columna. Reescrita sin `ifelse()`. **Lección: una función compartida se prueba con denominador escalar Y vectorial antes de darla por buena.**

- [x] **HITO (2026-09-12): `R2_modelo_base.qmd` escrito y renderizado. Los TRES reportes de compromiso firme están terminados.** R2 cubre los numerales 1.3, 1.4 y 8.2 de los TdR: la fórmula `Q × FC × PC / PM` con la fuente de cada término, la validación empírica del período de medición, el EMA con su distribución, la comparación de las tres variantes de sección, y los supuestos del EMA en tabla (incluido el provisional de 600 kcal/día para menores de 1 año, marcado como pendiente de contrastar con FAO/WHO/UNU 2004).

  **Resultado limpio y algo inesperado: el EMA por miembro se mantiene en ~1.00 en todos los tamaños de hogar**, de 1 a 8 miembros (1.04, 1.09, 1.01, 1.00, 1.00, 0.99, 1.00, 0.99). La composición etaria promedio de los hogares dominicanos es notablemente estable: los hogares grandes NO tienen proporcionalmente más menores. **Implicación honesta para la presentación:** en el agregado nacional la diferencia entre EMA y per cápita es pequeña; el ajuste importa para comparar hogares individuales y para desagregar por quintil. Decirlo así es más creíble que sobrevender el método.

  **Aporte por sección (mediana de gramos por EMA/día):** Sec 2 = 25.3 con 43,393 filas; Sec 3A = 11.6 con 260,014 filas. Coherente con que son instrumentos distintos: el inventario registra cantidades grandes de pocos alimentos, las compras diarias muchos alimentos en cantidades pequeñas.

  **Alimentos de mayor alcance (hogares consumidores):** Pollo fresco 5,811; Cebolla roja 5,349; Huevos de granja 5,004; ACEITE 4,920; Pasta de tomate 4,597; ARROZ 4,595 (mediana 163.9 g/EMA/día). *Nota: "Pasta de tomate" aparece aquí legítimamente, y es el mismo alimento excluido del vehículo trigo por el filtro `TRIGO_EXCLUIR`. Si alguien ve ambas tablas, la explicación es el filtro auditable en `_comun.R`.*

- [x] **HITO (2026-09-12): README reescrito como puerta de entrada para revisión externa.** El anterior decía "Fase activa: Fase 0" con fecha 05-09 y estaba escrito para uso propio. El nuevo está pensado para quien abre el enlace sin contexto: los tres reportes con su numeral de TdR, los tres hallazgos principales antes de cualquier detalle técnico, el pipeline en cinco líneas, los comandos exactos para reproducir, la estructura de carpetas con su criterio, una sección sobre trazabilidad de decisiones, y las limitaciones y decisiones pendientes sin maquillar. **Se quitó el bloque "Estado actual / Qué hacer ahora"**: era útil internamente pero delataba trabajo en curso a quien revisa, y ese contenido ya vive en esta hoja.

- [ ] **Pulir R2 (pendiente del consultor, 2026-09-12).** El contenido está validado; falta una pasada de forma. *Definir qué se quiere cambiar antes de abrirlo, para no rehacerlo por rehacerlo.*

- [ ] **Limpieza del repositorio — ampliada con lo detectado el 12-09:**
  - Los HTML renderizados (`scripts/R1_calidad_datos.html`, `R2_modelo_base.html`, `R3_cobertura_vehiculos.html`) **están versionados y no deberían**: son regenerables, igual que `data/clean`. Mover a `output/` con `_quarto.yml` (`output-dir: output`) y añadir `output/` al `.gitignore`.
  - Los reportes viven en `scripts/` junto al pipeline. Separarlos en `reports/`: `scripts/` es el flujo de datos, `reports/` son los entregables.
  - `.RDataTmp*` al `.gitignore` (la regla actual no lo atrapa por falta de comodín).
  - Scripts de uso único ya ejecutados y commiteados: `96`, `97`, `98`, `99`.
  - `food_factors_BACKUP_2026-09-10.xlsx` y `lote_PC_109.csv` (ambos redundantes).

- [x] **HITO (2026-09-12): `R4_escenarios_fortificacion.qmd` — CUATRO reportes, no tres. Y el hallazgo de política del proyecto.**

  R4 cubre los numerales 4.3 y 4.4 de los TdR (indicador 3 e inicio del 4). **No entrega una cifra única de ingesta, entrega un rango**, porque el resultado depende de un supuesto normativo sin resolver. Se modelan tres escenarios sustituyendo el código de composición de los vehículos y dejando el resto de alimentos intacto.

  | Escenario | Hierro (mg) | Folato (µg DFE) |
  |---|---|---|
  | 0. Sin fortificar | 9.0 | 277 |
  | 1. Solo harina de trigo | 9.2 | 284 |
  | 2. Harina y arroz | **16.2** | **1,017** |

  **HALLAZGO DE POLÍTICA — es el resultado más importante del proyecto.** Fortificar solo la harina casi no mueve la aguja (+0.2 mg de hierro, +7 µg de folato). Incluir el arroz multiplica el folato por 3.7 y casi duplica el hierro. **La diferencia NO está en el contenido de nutrientes** —arroz enriquecido 4.36 mg Fe / 386 µg folato, harina enriquecida 4.64 / 291, prácticamente iguales— **sino en el ALCANCE**: arroz 87.7% de los hogares con 207.8 g/EMA/día; harina 8% con 31.9 g.

  **Frase para la presentación:** *la eficacia de un programa de fortificación depende tanto del alcance del vehículo como del nutriente añadido. Un vehículo correctamente fortificado pero de consumo minoritario produce un efecto poblacional limitado.* Y la pregunta que se deriva: si el arroz no está normado, hay un vehículo con 87.7% de cobertura sin aprovechar.

  **Salvedad obligatoria, ya escrita en el reporte:** el escenario 1 **subestima** el efecto real de la harina, porque la harina llega vía pan (85.7% de los hogares según R3) y eso no se captura sin **factores de receta**. Se lee como **piso**, no como magnitud real. La conclusión sobre el alcance se mantiene; lo que falta es cuantificar el aporte por derivados.

  **Qué NO se modeló y por qué:** INCAP tiene 18 aceites y **ninguno con vitamina A**, así que no existe par fortificado/no fortificado para construir el escenario. Limitación de la tabla de composición, no del análisis. **No se sustituyó por un valor supuesto.** El azúcar sí tiene versiones fortificadas en INCAP (70215002, 70215034, 70215085), pero su inclusión depende de que exista norma aplicable.

  **Decisión metodológica clave:** cuáles vehículos están sujetos a fortificación obligatoria en RD, con qué nutrientes y niveles, se establece en instrumentos legales. **Eso se verifica con la contraparte, no se deduce ni se busca en fuentes secundarias** — la pregunta previsible es "¿en qué decreto?", y esa respuesta debe poder darse. Por eso se modelan los tres escenarios: cuando el marco se confirme, basta seleccionar el correspondiente y volver a renderizar. El cálculo ya está hecho.

  **Dos bugs corregidos antes de dar R4 por bueno:** (a) el filtro de aceites usaba rango de `enhance_id` y capturaba entradas de FNDDS que no eran aceites — daba "45 aceites, vitamina A máxima 1,172", **contradiciendo la conclusión del propio texto en la misma página**. Corregido a filtro por nombre dentro de INCAP: 18 aceites, 0 con vitamina A. (b) un `cat()` imprimía su propia sintaxis. **Lección: una tabla que contradice el texto que la acompaña es peor que no tener tabla.**

- [x] **HITO (2026-09-12): repositorio limpio y reorganizado** (`95_limpiar_repositorio.R`, ya ejecutado y eliminado). `scripts/` contiene solo el pipeline (`01`→`05`); `reports/` contiene `_comun.R` y los cinco `.qmd`. Los HTML renderizados salen a `output/` y **ya no se versionan**: son regenerables, igual que `data/clean` — *el repositorio contiene lo que genera resultados, no los resultados*. Creado `_quarto.yml` con `output-dir: output`. Completado el `.gitignore` (`output/`, `*.html`, `*_files/`, `*.knit.md`, `.RDataTmp*`). Eliminados los scripts de uso único `96`–`99`, el backup redundante de `food_factors` y `lote_PC_109.csv`.

  **Nota de ubicación para sesiones futuras: `_comun.R` está en `reports/`, NO en `scripts/`.** Los `.qmd` buscan en ambas rutas por compatibilidad, pero la copia válida es la de `reports/`. Tener dos copias produciría resultados distintos según dónde se ejecute.

- [x] **Refactor pendiente: `cargar_composicion()` está duplicada.** *Resuelto el 2026-10-03 (bloque A1b).* Vive en `reports/_comun.R` y la misma lógica está dentro de `scripts/05_ingesta_micronutrientes.R`. Lo correcto es que el `05` escriba la tabla de composición a `data/clean/` y que ambos la lean de ahí. No urge, pero es deuda técnica real: si se corrige un mapeo de columnas en un sitio y no en el otro, los reportes y el pipeline divergen en silencio.

- [x] **HITO (2026-09-13): entregables reorganizados y estructura del repositorio normalizada.**

  **Reorganización (`93_reorganizar_estructura.R`, ejecutado y verificado):** `referencias/` (material externo) separado de `docs/` (documentación del proyecto); `data/eda/` dividido en `data/auditoria/` (registro de decisiones, se conserva) y `data/diagnosticos/` (regenerable). 25 archivos movidos con `git mv` al 100% de similitud — el historial sigue a cada archivo. Pipeline verificado después: 36.840 sin `enhance_id`, 303.408 filas con gramos por EMA, 8.774 hogares. **Idénticas a antes: la reorganización no alteró ningún resultado.**

  **Convención de nombres adoptada:** minúsculas, sin acentos ni espacios; guiones en documentos, guiones bajos en código; prefijo numérico solo donde el orden de ejecución importa. Documentada en el README.

  **Crosswalk depurado (`94_depurar_crosswalk.R`):** eliminadas 7 columnas de andamiaje (`confianza_sugerencia`, `sugerencia_*`, `tipo_equivalencia_IA`, `nota_IA`) en Sec 2 y Sec 3A. Quedan las 5 de resultado. Criterio: **un archivo de entrada debe contener decisiones, no el borrador del que salieron.** El historial de git conserva todo.

  **Postura sobre el método de trabajo (decisión del consultor, 2026-09-13):** transparencia total sobre el uso de herramientas asistidas. El README documenta que el crosswalk se construyó en dos fases —generación asistida de candidatos y revisión manual registro a registro— y declara la tasa de error encontrada (6,1%). *"Es una habilidad que todo profesional hoy debería tener."* Lo que da valor no es el origen del candidato sino el criterio con que se corrigió.

- [x] **HITO (2026-09-13): tres entregables nuevos.**

  1. **`reports/INFORME_factibilidad.qmd`** — el entregable contractual. Salida a HTML **y Word**. Incluye: delimitación de lo que el análisis no puede establecer (antes de cualquier resultado), validación empírica del período de medición, adaptaciones metodológicas, control de calidad, limitaciones, las tres decisiones pendientes con su evidencia, y una **sección de estado y continuidad** con el criterio de alcance y una guía de cinco pasos para que otra persona retome el trabajo. 20 tablas y 3 figuras, todas con título completo y nota de fuente.

  2. **`reports/presentacion_revision.qmd`** — Quarto revealjs, once láminas. Abre enlazando los cinco informes y el repositorio. Sin animaciones (todo aparece a la vez). El trabajo de campo aparece en una lámina, sin presentarse como mérito.

  3. **`reports/dashboard_estado_datos.qmd`** — tablero de calidad de datos.

- [x] **CONVENCIONES EDITORIALES FIJADAS (2026-09-13). Aplicar a todo lo que se produzca de aquí en adelante:**

  - **Títulos de tabla y figura completos:** *"Tabla 3. Cobertura del procesamiento por sección. República Dominicana, 2018"*, con nota de fuente debajo. Configurado en el YAML (`crossref: tbl-title: "Tabla", title-delim: "."`).
  - **Fuentes primarias se citan, NO se atribuyen a "elaboración propia".** Corregido en todo el informe: *"Fuente: ENGIH 2018, Banco Central de la República Dominicana"*. "Elaboración propia" solo aplica a lo efectivamente elaborado (crosswalk, factores de conversión).
  - **Productor de los datos: Banco Central de la República Dominicana** (ejecutor de 4 de las 5 ENGIH del país), con participación de la ONE. **No es la ONE ni el Banco Mundial.** Microdatos públicos: https://www.bancentral.gov.do/a/d/4796-engih-2018
  - **ORCID 0000-0003-2117-9145** junto al nombre en informes y presentación. Sitio personal: https://bioestadisticaedu.com
  - **Tono mesurado en afirmaciones sobre el contexto dominicano.** El consultor no es de RD: se presenta el dato observado y se propone una interpretación marcada como tal (*"una lectura posible es que…"*), no se afirma el patrón de consumo como hecho conocido.
  - **Sin instrucciones de lectura** en documentos ("si dispone de cinco minutos", "empezar por aquí"). El lector decide.

- [ ] **PENDIENTE DE DISEÑO: el dashboard aún no convence (2026-09-13).** Dos iteraciones y sigue *"cargado, abrumador, le falta cultura del detalle"*. Problemas ya identificados y corregidos parcialmente: rótulos de *value box* de 50 caracteres (deben ser 2–3 palabras), etiquetas de eje con frases largas que plotly corta, títulos de tarjeta de 99 caracteres, etapas redundantes en el embudo, explicaciones metidas dentro de los elementos gráficos en vez de en tarjetas aparte. Añadidos estilos propios para el formato `dashboard` en `custom.scss`.

  **Principio adoptado: un tablero existe para DECIDIR algo, no para describir.** El de calidad de datos responde *"¿dónde conviene invertir el esfuerzo que queda?"*, y la tabla de pendientes incluye la **ganancia de cobertura en puntos porcentuales** de resolver cada alimento. Falta una pasada más de diseño.

- [ ] **`reports/dashboard_decision_fortificacion.qmd` — escrito pero SIN RENDERIZAR.** Implementa la especificación de Santiago punto por punto, incluido el que faltaba: **desplazamiento de la distribución respecto al EAR** (curvas de densidad por escenario con línea de corte, y tabla de proporción de hogares por debajo). **Requiere la misma simplificación de diseño que el otro tablero antes de enseñarlo.**

  **Advertencia crítica ya incorporada al propio tablero:** los valores de EAR usados (hierro 8,1 mg; folato 320 µg DFE; vitamina A 500 µg RAE) son **de referencia y están pendientes de confirmación**. El valor aplicable depende de si se adopta FAO/OMS o IOM y, en hierro, de la biodisponibilidad supuesta — además de que la distribución asimétrica del hierro limita el método de punto de corte. **No presentar esos porcentajes sin la salvedad.**

- [ ] **Decisión tomada sobre Shiny: NO.** Un tablero "en construcción pero bonito" es una promesa, no un producto, y un servidor puede fallar en vivo. Se opta por **dashboard estático de Quarto** con gráficos interactivos (plotly) y tablas dinámicas (DT): HTML autocontenido, sin servidor, no puede caerse, y vive en el repositorio.

- [ ] **Borrador de artículo científico — PENDIENTE, no iniciado.** Alcance acordado: introducción con definición del problema científico mediante preguntas e hipótesis, metodología completa (no depende de los resultados), y solo los resultados disponibles. **Es deliberadamente un borrador a medio escribir**, sin nada que no se sostenga. Tono científico, distinto del administrativo del informe de factibilidad y del expositivo de la presentación. Referencia de estilo: `referencias/notas-marco-analitico-tang.docx`.

- [ ] **Menor:** los *warnings* de `big.mark`/`decimal.mark` al compilar el informe (se usa "." para ambos). No afecta resultados; limpiar en la próxima pasada.

- [ ] **BRECHAS FRENTE AL ESTÁNDAR INTERNACIONAL — evaluación crítica (2026-09-13).** El producto actual es sólido *como análisis de factibilidad de medio término*: reproducible, documentado, con limitaciones medidas y no supuestas. **No es todavía publicable** según estándar internacional, y la distancia es concreta y acotada. Se anota para no perderla de vista.

  **1. Diseño muestral complejo — la brecha mayor, y la más barata de cerrar.** Un análisis de encuesta compleja sin `srvyr` no cumple el estándar: las variables (`ESTRATO`, `UPM`, `FACTOR_EXPANSION`) estaban disponibles desde el inicio. Media jornada de trabajo. **Ventaja de haberlo dejado para ahora:** el pipeline está estable y los reportes leen de `reports/_comun.R`, así que se implementa una vez y se propaga a todo.

  **ADVERTENCIA: no es un añadido inocuo.** Las medianas ponderadas difieren de las simples, así que **cambiarán cifras de los reportes**, no solo se añadirán intervalos. Exige volver a renderizar todo y verificar. Planificar como bloque con verificaciones, al estilo de la reorganización del 13-09. **No hacerlo la víspera de una entrega.**

  **2. Validación externa — ausente.** Las estimaciones de consumo no se han contrastado contra ninguna fuente independiente. Que la energía dé 2.153 kcal/EMA/día es plausible, pero no está verificado. Candidatos: **Encuesta Nacional de Micronutrientes de RD**, **hojas de balance de FAO**, la **canasta básica del propio Banco Central**. Si se consiguen, es una tarde de trabajo y da un argumento fuerte. Si no, se declara como pendiente.

  **3. Control de atípicos a nivel de hogar.** 45 filas marcadas sobre 300.000 y 572 hogares implausibles declarados pero no resueltos. Técnicamente barato, pero requiere decidir y justificar un umbral. **Hacerlo DESPUÉS de resolver el tratamiento de las dos secciones**: la disponibilidad neta probablemente absorba buena parte de esos hogares y entonces el umbral correcto sería otro.

  **Orden recomendado:** `srvyr` primero (es lo único que cambia lo que se puede afirmar) → después validación externa → disponibilidad neta → atípicos por hogar. Cada uno depende del anterior.

  **4. Retrabajo evitable — lección de proceso.** Hubo que rehacer el README, la presentación y el dashboard (dos veces). Causa: se empezó a producir antes de definir **audiencia y propósito** de cada pieza. Regla adoptada: antes de escribir un entregable, fijar para quién es y qué decisión o acción habilita.

- [x] **HITO (2026-09-13/14): DISEÑO MUESTRAL COMPLEJO INCORPORADO. Cerrada la brecha más seria frente al estándar internacional.**

  **Etapa 1 (`92_incorporar_diseno_muestral.R`).** `01_import.R` conservaba solo `factor_expansion`; se añadieron `estrato`, `upm`, `quintil`, `des_estrato` y `grupo_region`, y `04_equivalente_adulto.R` los lleva al nivel de hogar con `first()` — **el diseño es propiedad del hogar, no de la persona: sumarlo multiplicaría el peso por el número de miembros**. Se deriva además `zona` (urbano/rural) desde `des_estrato`. Verificación: las tres cifras de control quedaron idénticas (36.840 / 303.408 / 8.774), confirmando que solo se arrastraron variables. El `04` imprime ahora: **8 estratos, 933 UPM, 5 quintiles, 0 hogares sin factor de expansión**.

  **Etapa 2 (`91_helper_diseno_muestral.R`).** En `reports/_comun.R`: `cargar_ema_hogar()`, `diseno_muestral()`, `estimar()` y `estimar_proporcion()`.

  **Criterio adoptado (decisión del consultor, que es bioestadístico):** medias ponderadas con varianza por **linealización de Taylor** (lo estándar en `survey`/`srvyr`) y **mediana ponderada al lado como descriptivo, sin intervalo**. Se descartó bootstrap de réplicas por innecesario. **Se descartó también aplicar estimadores robustos a los 572 hogares implausibles:** no son ruido estadístico sino un problema identificado con causa conocida (solapamiento entre secciones) — se resuelve con datos, no se tapa con método. Principio: *adaptarse a lo que los datos llevan, sin torturarlos.* PCA descartado: con 4 nutrientes correlacionados por volumen, el primer componente sería "cantidad total" y no aportaría.

  **RESULTADO TRANQUILIZADOR: el ponderar casi no mueve las estimaciones puntuales.** Energía mediana ponderada 2.148 kcal vs 2.153 sin ponderar — **5 kcal de diferencia**. La muestra está bien balanceada respecto al consumo y las cifras anteriores no estaban sesgadas. **Lo que se gana no es corregir, es poder acompañar cada cifra de un intervalo correcto.** Media ponderada 2.732 kcal (IC 2.661–2.802): ±5%, razonable con 933 UPM.

- [x] **HITO (2026-09-14): `reports/R5_equidad.qmd` — el hallazgo más importante del proyecto.**

  **1. El gradiente social existe y es afirmable.** Razón entre quintil 5 y quintil 1, en medianas ponderadas: **Vitamina A ×2,10 · Energía ×1,44 · Hierro ×1,36 · Folato ×1,27**. En los cuatro nutrientes **los IC de los quintiles extremos NO se solapan**: la desigualdad es sostenible estadísticamente.

  **2. Las pendientes NO son iguales, y eso pedía explicación.** El folato es el nutriente más equitativamente distribuido y la vitamina A el menos — gradiente casi el doble de empinado. **Hipótesis:** el folato viene de cereales básicos sujetos a fortificación (consumo transversal); la vitamina A de frescos no fortificados (consumo ligado al gasto). **Planteada como predicción falsable:** sin fortificación, el gradiente del folato debería empinarse.

  **3. Segunda evidencia independiente, por zona.** De los cuatro nutrientes, **el único con diferencia urbano-rural sostenible es el folato, y es MAYOR en zona rural** (medianas 869,0 vs 799,4; IC sin solapar). Energía, hierro y vitamina A se solapan y **no son afirmables** — advertencia explícita en el reporte contra afirmar lo que las estimaciones puntuales sugieren y los intervalos no respaldan.

  **4. LA PRUEBA — la predicción se cumple.** Razón Q5/Q1 del folato según escenario:

  | Escenario | Q1 | Q5 | Razón |
  |---|---|---|---|
  | Sin fortificar | 256,5 | 311,3 | **1,21** |
  | Solo harina | 261,3 | 316,7 | **1,21** |
  | Harina y arroz | 955,9 | 965,5 | **1,01** |

  **Fortificar el arroz aplana el gradiente social casi por completo.** Fortificar solo harina no lo mueve — coherente con su cobertura del 8%. En el escenario con arroz la distribución deja incluso de ser monótona (el Q3 supera al Q5).

  **5. EL MECANISMO, verificado — y NO es el que parecía.** Consumo de arroz por EMA/día, medianas ponderadas: Q1 = 188,3 · Q2 = 202,8 · Q3 = 201,9 · Q4 = 201,9 · Q5 = 205,1. **Los hogares pobres NO consumen más arroz: consumen prácticamente lo mismo que el resto.** Y esa uniformidad basta. Si la cantidad es similar en toda la distribución, el nutriente añadido entra en cantidades absolutas similares; como la ingesta total de los quintiles altos es mayor por otras vías, el aporte del vehículo representa una **fracción mayor de la dieta de los hogares pobres**, reduciendo la desigualdad relativa.

  **6. Implicación general — es lo que hace el hallazgo citable.** La condición NO es que el alimento se consuma *más* entre los pobres, sino que se consuma **de forma transversal**. Condición mucho menos exigente, que cumplen los alimentos básicos de consumo generalizado. **La fortificación de un vehículo transversal tiene efecto distributivo progresivo:** añade un argumento de EQUIDAD al de cobertura.

  **Para la reunión:** hasta ahora el argumento sobre el arroz era de *alcance* (88% de los hogares). Ahora hay un segundo argumento, independiente y más fino: **llega especialmente a quien más lo necesita.**

  **Salvedad declarada en el propio reporte:** los escenarios asignan un único código de composición a todas las variedades de arroz. Adecuado para contrastar la **dirección** del efecto; puede afectar a la **magnitud**. La cuantificación precisa requiere resolver la línea base.

- [ ] **Pendientes menores de esta sesión:**
  - `fmt()` e `ic()` (formato español: miles con punto, decimales con coma, aplicado también dentro de los intervalos construidos con `paste0`) **viven dentro de R5 y deberían estar en `reports/_comun.R`** para que los demás reportes los usen. No se movieron para no tocar el archivo común, que usan seis documentos.
  - **REGLA TÉCNICA APRENDIDA:** en bloques con `results: asis` que generen markdown, usar **`knitr::asis_output()`, nunca `cat()`**. `cat()` escribe por partes al flujo de salida y rompe las negritas — el texto sale cortado justo donde va el valor. Apareció en R4, se dio por resuelto sin estarlo, y se diagnosticó correctamente en R5.
  - **R1 a R4 siguen sin intervalos de confianza.** Ahora que `_comun.R` tiene el diseño muestral, conviene incorporarlos — especialmente R3 (cobertura de vehículos), donde los porcentajes deberían ir con IC.
  - `03_transform.R` imprime un IC de cobertura ponderada con la advertencia de que está subestimado. **Esa advertencia ya no aplica**: corregir para que use el diseño.

- [ ] **CIFRA QUE CAMBIÓ AL PONDERAR (2026-09-14): la mediana del EMA es 3,09, no 3,04.** Es el efecto anunciado al incorporar `srvyr` — no solo añade intervalos, mueve estimaciones puntuales. La muestra sobre-representa ligeramente hogares pequeños; al corregirlo, el EMA sube.

  **Verificar que todos los entregables digan 3,09** (media ponderada 3,24; IC 3,20–3,28). La presentación y el informe de factibilidad pueden conservar la cifra antigua. **Dos documentos con cifras distintas para lo mismo es lo primero que un revisor nota.**

  *Las demás estimaciones apenas se movieron:* energía mediana 2.148 ponderada vs 2.153 sin ponderar.

- [x] **HITO (2026-09-14): validación externa incorporada al informe de factibilidad.** Cierra la segunda brecha frente al estándar internacional.

  **Vía 1 — estructura de la dieta.** El IDIAF publicó un análisis de la misma ENGIH 2018 a partir de las ponderaciones del IPC del Banco Central, es decir, **midiendo gasto y no cantidad física**. Ocho de sus diez alimentos de mayor peso figuran entre los de mayor volumen en este análisis. Los dos que faltan tienen explicación: agua purificada (excluida por no aportar nutrientes) y salami (alto en gasto, bajo en gramos). El orden de los dos primeros se invierte —arroz y pollo— por el precio unitario. **Dos procedimientos independientes sobre la misma fuente producen la misma estructura de la dieta**; un error sistemático en la cadena de conversión no daría ese resultado. Referencia: del Rosario P. *El consumo de alimentos en República Dominicana*. IDIAF, 2021. ISBN 978-9945-448-30-6.

  **Vía 2 — orden de magnitud.** FAO sitúa la disponibilidad energética de RD por encima de 3.000 kcal/persona/día; la estimación propia es ~2.150 kcal/EMA/día, **cerca del 70%**. Es la dirección correcta y el rango documentado para encuestas de hogares (70–90%), por el extremo que corresponde a un país con más de 7 millones de visitantes anuales.

  **Lo que NO establece, declarado en el propio informe:** que las cifras absolutas sean correctas. Eso requeriría una encuesta de consumo individual sobre la misma población.

- [ ] **PRESENTACIÓN — reconvertida en REPORTE DE AVANCE (2026-09-14). Formato adoptado, se actualizará en cada revisión.**

  **Motivo del cambio:** la reunión siempre empieza con *"Maicel, muéstranos en qué has avanzado"*. Una presentación cerrada con narrativa pulida no encaja con esa situación. El formato de reporte de avance sí, y además resuelve el problema de tono: si el documento es un estado vivo, no hay motivo para escribirlo con efectos retóricos, y las dudas genuinas dejan de ser algo que disimular.

  **Estructura (18 láminas):** marco metodológico → desarrollo del procedimiento (con enlaces al repositorio) → documentación disponible → qué entra al análisis → vehículos → escenarios y equidad → definiciones pendientes → verificaciones pendientes → trabajo pendiente → líneas en curso.

  **Convenciones editoriales fijadas para todo el proyecto:**
  - **Las fuentes primarias NO se citan en cada tabla.** La ENGIH es fuente primaria y el análisis es propio: se declara una vez en el marco metodológico. **Solo se citan fuentes secundarias** (IDIAF, FAO). Esto liberó el espacio que estrangulaba las tablas.
  - Tampoco se escribe "elaboración propia" en ningún pie.
  - Notas al pie con prefijo **NOTA:** en negrita.
  - Títulos de tabla y figura completos, con lugar y año. Unidades en los encabezados. Alineación por tipo de dato.
  - **Enlaces a elementos concretos del repositorio** en cada sección, para que los revisores puedan auditar por su cuenta al recibir la presentación por correo.
  - Un elemento visual por lámina; si hay dos, se separan en dos láminas.

  **Función `tabla()` en `reports/_comun.R`** (script `88_helper_tablas.R`): devuelve `gt` en HTML y `flextable` en Word, con la nota al pie **dentro del objeto**. Constantes `FUENTE_ENGIH`, `NOTA_DISENO`, `NOTA_EMA`.

  **REGLA TÉCNICA aprendida (costó tres iteraciones):** `kable()` NO se auto-imprime si le sigue otra expresión en el mismo bloque, y `print()` sobre un objeto `kable` emite el markdown como texto crudo. **Las notas al pie van dentro del objeto (gt/flextable) o fuera del bloque como markdown — nunca como llamada a función después del `kable()`.**

- [x] **HITO (2026-09-14): depuración del repositorio, primera pasada.**

  **Comentarios reescritos** en `reports/_comun.R` (20 bloques, script `87`) y en el pipeline (7 bloques, script `86`). Criterio: **un comentario dice lo que el código no dice**. Se eliminan justificaciones de diseño, advertencias en mayúsculas y frases de cierre; se conservan los datos concretos (sin las exclusiones la cifra del trigo se infla 47%; los 19 aceites de INCAP tienen VITA_RAE = 0).

  **Referencias personales sustituidas** (script `85`, 11 sustituciones). Una fuente se cita por su título, no por quien la entregó — menos aún en un repositorio que revisan esas mismas personas. Se cita el documento metodológico, que está en `referencias/`.

  **Encabezado de `03_transform.R` corregido — el problema más serio.** Afirmaba que faltaban las variables de diseño muestral, que estarían en el Cuestionario A, y que se usaba `ids = ~1`. **Las tres cosas dejaron de ser ciertas el 13-09.** Un desfase así es peor que un comentario mal redactado: presenta como limitación algo ya resuelto. También se depuró su lista de pendientes, que incluía tareas ya hechas.

  **Verificado tras cada cambio:** pipeline completo con las cifras de control intactas (36.840 / 303.408 / 8.774) y R5 renderizando.

- [ ] **LIMPIEZA FINAL DEL REPOSITORIO — lo que queda, en orden:**

  1. **Buscar más desfases como el de `03_transform.R`**: afirmaciones que dejaron de ser ciertas. Sospechosos: encabezados de `01`, `02`, `04` y `05`; `docs/vision-y-arquitectura.md`; y las secciones de limitaciones de R1 a R5, que pueden seguir diciendo que no se reportan intervalos de confianza.
  2. **Archivos de `media/` con doble extensión** (`aji_cubanela02.jpg.jpg`, `platano_verde00.jpg02.jpeg`), junto con las rutas que los referencian.
  3. **Eliminar los nueve scripts de uso único** (`85` a `93`) — al final del todo. Sus resultados están aplicados y el historial los conserva.
  4. **Verificar que `data/clean/` y `output/` siguen ignorados.**

- [ ] **REVISIÓN DE TONO — pendiente en los seis documentos (identificado 2026-09-14).** El texto de los informes está escrito como si hubiera que explicarle el método al lector. **La audiencia son dos expertos en fortificación y un oficial de nutrición: saben más del dominio que el consultor.** El registro actual resulta condescendiente y no corresponde a un reporte científico.

  **Tres tics concretos a eliminar** (ejemplos reales de R4):

  1. **Explicar lo que el lector ya sabe.** *"La tabla de composición asigna a cada alimento un perfil nutricional."* Es una definición dirigida a quien no conoce el método.
  2. **Redundancia entre tabla y prosa.** *"El arroz enriquecido aporta más de cinco veces el hierro…"* cuando la tabla con los valores exactos está inmediatamente arriba. El redondeo verbal además empobrece el dato.
  3. **Meta-comentario sobre el propio trabajo.** *"Cuando el marco normativo se confirme, basta seleccionar el escenario: el cálculo ya está hecho."* Son notas de implementación, no resultados.

  **Criterio de corrección: decir solo lo que el dato no dice.** El remedio no es acortar sino sustituir. Ejemplo de reescritura del punto 2: *"La diferencia entre versiones enriquecida y sin enriquecer es de 3,6 mg de hierro y 377 µg de folato por 100 g. La asignación de una u otra determina el resultado."* — aporta magnitudes exactas y consecuencia, sin narrar la tabla.

  **Alcance:** informe de factibilidad, R1 a R5 y la presentación. Es trabajo de redacción cuidadosa; no hacerlo con prisa.

- [ ] **REGLA TÉCNICA (2026-09-14): no usar `n`, `x` ni `i` como variable de bucle dentro de `mutate()` o `summarise()`.** El contexto de evaluación de dplyr es el data frame, así que una columna con ese nombre enmascara la variable. Caso real en R4: `estimar()` devuelve una columna `n` (hogares) que tapó la variable del `lapply`, y `NUT_ETIQ[[n]]` recibió un entero en vez de un nombre — error `subscript out of bounds` a mitad del render.

- [ ] **Pendiente menor:** varios archivos de `media/` tienen doble extensión (`aji_cubanela02.jpg.jpg`, `platano_verde00.jpg02.jpeg`). Funcionan, pero desentonan. Corregir junto con las rutas que los referencian en la presentación, no por separado.

- [ ] **DECISIÓN ABIERTA (2026-09-10) — línea base de fortificación. Corresponde al equipo (Daniel/Carlos/Santiago), NO se automatiza.** El crosswalk actual no representa ningún escenario real de política pública dominicana:
  - **Arroz:** RD **no** tiene norma de fortificación de arroz, pero el crosswalk manda ARROZ (var. 7), Arroz selecto (66) y Súper-selecto (65) a `70213002` "Arroz blanco enriquecido" (Fe 4.36, folato 386/100g). Solo Arroz corriente (67) va a `70213004` sin enriquecer. **Sobrestima** Fe y folato del alimento #1 de la dieta.
  - **Harina de trigo:** fortificación **obligatoria desde 2009** (Fe, ácido fólico, complejo B), pero el crosswalk manda Harina de trigo (58) a `70213038` "s/enriquecer" (Fe 1.17, folato 26). **Subestima.**
  - **Azúcar:** fortificada con vitamina A (NORDOM 606, 5–25 mg/kg), pero AZUCARES (29) va a `70215001` sin fortificar (vit A = 0) y Azúcar blanca refinada (458) a `70215036`. **Subestima** vitamina A.
  - Fuentes: informe ENM 2009 RD (MSP/CESDEM) y FFI (Food Fortification Initiative) — la fortificación de harina para pastas y galletas es **voluntaria**, hay que declararlo por escenario.
  - **Tractable sin datos nuevos:** INCAP ya tiene las entradas pareadas — arroz `70213002`/`70213004`, harina `70213039`/`70213038`, azúcar `70215002`/`70215001` (esta última con VITA_RAE = 1000 vs 0). Se implementa como una **capa de escenarios que intercambia el `enhance_id` por vehículo**, conservando `enhance_id_base` para volver al estado observado.
  - **A decidir:** (a) confirmar "norma RD 2018" como línea base; (b) qué se asume para pan/pastas/galletas; (c) verificar si "Arroz selecto/súper-selecto" venía realmente enriquecido en el mercado dominicano de 2018 ("seleccionado" en RD alude a calidad de grano, no a fortificación). El escenario mixto actual **nunca** se reporta como línea base.

- [ ] **Backlog abierto por la jornada del 2026-09-10:**
  - **Los 154 mapeos del crosswalk Sec 3A** con `validado=1`, `enhance_id` vacío y nota "Confirmado": el ID ya está en `sugerencia_ID` y los 154 tienen `EDIBLE` en INCAP. Lista generada en `data/eda/revision_154_sugerencias.csv`. Requiere revisión manual (~40 min) antes de copiar: las sugerencias automáticas fallan en parte del alimento, estado de preparación y grado de procesamiento (detectadas: Remolacha → "hojas crudas"; Yogurt bebible → "leche descremada").
  - **Tipado explícito en las lecturas de Excel.** `readxl` adivina el tipo de columna y puede convertir valores válidos en `NA` sin avisar (hoy: 768 avisos de coerción en `validado`, benignos; en el crosswalk de Sec 2, 27 de 29 celdas de `enhance_id` están guardadas como texto). Usar `filter(validado %in% c(TRUE, 1))`, `na = c("", "NA", "N/A")` y un chequeo que falle si `as.numeric()` genera NAs nuevos en columnas clave.
  - **Migrar el join de Sec 3A** de `descripcion` a `id_variedad` (ya anotado; hoy se completó `id_variedad` en las dos filas de peso-por-unidad para preparar el terreno).
  - **Diseño muestral: el descargo de `03_transform.R` está desactualizado.** `Sociodemograficas_e_ingresos.xlsx` hoja "Base" **sí** trae `ESTRATO` (8), `UPM` (933), `FACTOR_EXPANSION` y `TRIMESTRE`. `svydesign(strata = ESTRATO, ids = UPM, weights = FACTOR_EXPANSION)` es implementable ya; `srvyr`/`survey` están en el entorno.
  - **"Docena" (código 52) se usa como factor universal de conteo, no de masa.** `diccionario_conversion` le asigna FC = 12 y la unidad universal tiene prioridad sobre la tabla específica, así que una docena devuelve "12", no gramos. Afecta ~217 filas de Sec 3A y 1 de Sec 2 (0.06%), pero con subestimación sistemática de ~40x en esos ítems. Decidir: mover Docena a "Alimento-específico" o crear FC por alimento (12 × peso por unidad).
  - **Archivos referenciados que no existen en el repo:** `data_raw_unidades_ACTUALIZADO.xlsx` (el contenido reconstruido vive directamente en `data_raw_unidades.xlsx`) y `notas_estrategicas_personales.md` (citado en un comentario de `01_import.R`). Documentado para no volver a buscarlos.
  - **README desactualizado** ("Fase activa: Fase 0", última actualización 05-09).

- [x] **HITO (2026-09-08): primera corrida completa y exitosa de `01_import.R` → `02_eda.R` → `03_transform.R`, de punta a punta, en la historia del proyecto.** Con datos parciales pero honestos (crosswalk Sec3A al 50%, `food_factors.xlsx` cubriendo 144/770 alimentos): Sec2 con 11 filas marcadas outlier, Sec3A con 41; ejemplo de cobertura ponderada real (arroz blanco enriquecido, enhance_id 70213002): 30% (IC 28.9-31.1%). En el camino se corrigieron 3 bugs reales que nunca se habían detectado porque estos scripts nunca se habían corrido completos hasta hoy (ver bugs documentados más abajo). El aviso de diseño muestral (IC probablemente subestimado, faltan variables de conglomerado/estrato) sigue pendiente, documentado en el propio script.
- [x] **HITO (2026-09-08): `04_equivalente_adulto.R` ahora une el consumo diario (`03_transform.R`) con `EMA_hogar` y calcula `Gramos_por_EMA_dia`** — 254,905 de 254,905 registros de consumo válidos (Sec2+Sec3A, sin outliers) con gramos-por-EMA calculado (100%, esperado dado que el 100% de los hogares ya tenía EMA). Esto NO es todavía la "ingesta aparente de micronutrientes por EMA" completa (falta multiplicar por composición nutricional, ver `05_ingesta_micronutrientes.R` abajo) — es la pieza intermedia que deja ese paso final mucho más simple. Salida: `data/clean/data_gramos_por_ema.csv`.

- [x] **Resuelto/entendido (2026-09-08):** 54,772 filas de Sec 3A quedan "sin PC/edible" — **confirmado: no es un bug, `food_factors.xlsx` (la tabla de EDIBLE) es un archivo separado del crosswalk, y solo cubre 144 de los 770 alimentos.** No se toca con la validación del crosswalk porque son tablas distintas. Pendiente real: ampliar `food_factors.xlsx` a más alimentos (626 sin cubrir) cuando llegue el momento de esa fase — no es urgente para Fase 0.
- [x] **Dos bugs reales corregidos en `01_import.R`/`02_eda.R` (2026-09-08), encontrados corriendo el pipeline completo por primera vez:**
  1. `EDIBLE` de Sec2 en `food_factors.xlsx` estaba guardado como texto con coma decimal ("1,00"); `as.numeric()` directo lo convertía todo a NA. Corregido con reemplazo de coma por punto antes de convertir.
  2. `02_eda.R` estaba desactualizado desde el 16 de agosto: usaba nombres de columna viejos (`id`, `cantidad`, `alimento`, `unidad_medida`) que ya no existen, y leía los CSV con `read_csv2()` (asume coma decimal) cuando `01_import.R` los escribe con `write_delim()` (punto decimal) — corrompía `Q` y otras columnas numéricas a texto en cada corrida. Reescrito completo, ahora corre limpio y el detector de atípicos por alimento funciona (confirmado: Cebolla roja, Pollo fresco, Ajo, Aceite de soya encabezan atípicos en Sec 3A, resultado con sentido real).

**Primer corrido real de `01_import.R` (2026-09-05, Dr. Monzón):**
```
Sec 2   -- 47,837 filas | universal: 22,316 | específica: 16,866 | SIN FC: 8,655
Sec 3A  -- 342,046 filas | universal: 107,095 | específica: 0 | SIN FC: 234,951
```
Sec 2 pasó de ~0 filas resueltas por tabla específica a 16,866 en esta sesión. Las 5 filas `PROVISIONAL_baja_confianza` (ACEITE+Botella/Lata, CHOCOLATE+Paquete/Frasco, PANES+Funda) fueron validadas por criterio de mercado del Dr. Monzón — ver `data_raw_unidades.xlsx`, columna `nota`.

**Confirmado con el pipeline real corriendo (2026-09-05):**
```
Sec 2   -- 47,837 filas | universal: 22,316 | específica: 16,866 | SIN FC: 8,655
Sec 3A  -- 342,046 filas | universal: 107,095 | específica: 155,770 | SIN FC: 79,181
```
Sec 3A superó la proyección (155,770 vs. ~113,700 esperados) — probablemente por reutilización automática del FC vía el mecanismo `coalesce(presentación, base)` del script cuando algunos hogares sí reportaron presentación explícita para un alimento y otros no.

- [x] **"Peso por unidad" — 52,416 de 87,836 filas resueltas (60%).** Agregadas a `data_raw_unidades.xlsx` (mecanismo: código "Unidad"=1 como si fuera presentación, ya funciona con la lógica existente del pipeline sin tocar código): HUEVOS/Huevos criollos/Huevos de granja=53g (huevo mediano, fuente: normas de gradación Argentina SENASA + Colombia), PANES/Pan sobado/Pan de agua=50g (fuente: UMPIH + ProCompetencia 2017, mercado del pan RD), GALLETAS SALADAS=3g (fuente: USDA FoodData Central), Cebolla roja=148g (USDA), Ajo=3g asumiendo 1 unidad=1 diente (USDA), **Ají cubanela=288g (2026-09-09, dato de campo propio: pesaje real en mercado, 5 unidades=1440g).** Quedan sin resolver: Cilantro (220g/bolsa ya medido en campo, falta decidir si aplica igual a "Cilantrico o verdura"), Plátano verde, Guineo verde.
  - [x] **Bug real encontrado por el usuario (2026-09-09), corregido:** al agregar HUEVOS/PANES/GALLETAS SALADAS el 2026-09-08, la fila se armó con 7 valores en vez de 8 (se olvidó la columna `frecuencia_datos`), corriendo todo el contenido una columna a la izquierda — `FC` quedó con el texto `"ALTA_CONFIANZA_fuente_externa"` en vez del número, y `variedad` quedó con texto ("HUEVOS" etc.) mezclado con los códigos numéricos del resto de la tabla. **Esto explica también el error de `left_join()` ("id_variedad es double, variedad es character") que le salió al correr `01_import.R`** — misma causa raíz, ya resuelta al corregir las 3 filas por nombre de columna en vez de por posición.
- [x] **Resuelto:** `crosswalk_tablas_composicion.xlsx`, pestaña `Cuest. B Sec 3A`, columna `validado` — las 6 filas con número en vez de booleano ya se corrigieron a mano. De esas 6, dos (id 2936 "Impuesto a vivienda de lujos", id 2392 "Pulseras de metales preciosos") resultaron ser errores de captura reales del crudo ENGIH (1 hogar cada uno, no alimentos) — **eliminadas de la tabla el 2026-09-06**. Se revisaron otras 24 filas con palabras similares (alcohol, tabaco): son categorías legítimas de la sección, sin `ENHANCE_ID` a propósito por no aportar a la fortificación — no se tocan.
- [x] Sec 3A completo — resuelto 2026-09-05. Misma metodología que Sec 2, aplicada a 2,008 combinaciones reales (antes la tabla solo tenía 721, cubriendo el 36%). De 1,372 genuinamente alimento-específicas: 546 con FC asignado (97.9% de las observaciones pendientes), 68 combos (0.66%, incluye variantes menores de "Sopita Concentrada") quedan para revisión manual, 758 sin evidencia (1.5%, cola de muy baja frecuencia). La hoja `Cuest. B Sec 3A` de `data_raw_unidades_ACTUALIZADO.xlsx` fue reconstruida completa (2,008 filas, mismo formato que Sec 2: `id_variedad`, `descripcion`, `unidad_no_estandar`, `FC`, `frec_sec3` corregida, `validacion`, `nota`). Detalle: `data/eda/FC_propuesto_sec3a.csv`.
  - [ ] 68 combos en `REVISAR_MANUAL_alta_dispersion` (ver `data/eda/FC_propuesto_sec3a.csv`) — mayormente n pequeño (3-25 hogares) o rango amplio sin patrón claro de mercado, baja prioridad por impacto (762 observaciones de 342,046 filas totales).
  - [x] **"Sopita Concentrada" — cerrado con dato real (2026-09-08), pendiente solo de aprobación final de Daniel/Carlos.** Con trabajo de campo real (fotos propias en el mercado, `media/fotos_investigacion_mercado/`) y una etiqueta de Knorr Caldo de Pollo verificada en H-E-B: **1 cubito = 10g → 2,320mg sodio, 30kcal (23,200mg sodio/100g, 62x más que el caldo diluido que se iba a usar por error).** Confirma con datos reales el diagnóstico teórico de la mañana. Limitación honesta: la etiqueta solo trae sodio/macros, no el perfil completo de micronutrientes — no hay `ENHANCE_ID` completo todavía, pero para sodio/energía (lo más relevante de este producto) ya hay dato citable. Detalle completo en `crosswalk_tablas_composicion.xlsx`, columna `notas` de esa fila.
  - [ ] El join de producción en `01_import.R` sigue siendo por `descripcion` (texto), no por `id_variedad` — se verificó que hoy no hay colisiones, pero sigue siendo fràgil a futuro (un cambio de tilde/mayúscula en cualquiera de los dos archivos rompe el match sin avisar). Considerar migrar el join a `id_variedad` cuando haya tiempo.


- [ ] Completar validación del crosswalk Sec 3A — **420/769 hechas (55%), actualizado 2026-09-08.** Quedan 349. Nuevos sin match: Conconete, Jamón bolo, Pan camarón, Cojinúa (es un pez, no cebollín), Bija en polvo, Pico y pala de pollo, Sardinas en agua y sal, Sazón líquido, Compota, Malagueta, Queso de hoja, Extracto de malta, Dorado, Rulo, Masitas, Paletas+mentas, Sopa china -- lista completa para preguntarle a Daniel. Sin match real ni en INCAP ni en FNDDS tras búsqueda (21 en total): Sazón líquido (mayor frecuencia pendiente, 1756), Compota, Malagueta, Queso de hoja, Extracto de malta, Dorado, Rulo, Masitas, Paletas+mentas (categoría combinada), Sopa china instantánea, más 12 menores — **preguntarle a Daniel si conoce fuente para estos** en vez de seguir buscando a ciegas. Nota: algunos matches de "media"/"baja" confianza automática resultaron correctos al verificar (ej. Huevos criollos, Pimienta en polvo, Chuleta de cerdo) — la etiqueta de confianza automática no predice bien la calidad, hay que seguir revisando una por una.
- [ ] Resolver los ~68 `id_variedad` de Sec 3A ausentes del diccionario oficial (¿versión distinta, o residual real?)
- [ ] Decidir si cubrir los 16 códigos `VARIEDAD` de Sec 2 fuera del crosswalk de 30 (afecta 0.13% de filas — prioridad baja)
- [x] Completar factores FC "Alimento-específico" de **Sec 2** — resuelto 2026-09-05. De 196 combinaciones: 43 ya resueltas por unidad universal, 34 fuera del crosswalk de 30 alimentos (bajo impacto, ver abajo), 119 genuinamente alimento-específicas. De esas 119: 79 con FC asignado con evidencia del propio crudo (`contenido_empaque_presentacion`, mediana por combinación), cubriendo 95.9% de las observaciones; 40 sin evidencia suficiente (1% de las observaciones, baja prioridad). Metodología completa en `data/eda/FC_propuesto_sec2.csv`. Archivo actualizado: `data/raw/data_raw_unidades_ACTUALIZADO.xlsx` (reemplaza a `data_raw_unidades.xlsx` una vez validado).
  - [ ] Sec 3A (721 combinaciones) — pendiente, misma metodología: filtrar por unidad universal real (`FC` no nulo en `diccionario_conversion`, cuidado con códigos que aparecen en la tabla pero sin valor), calcular FC empírico vía `contenido_empaque_presentacion`, clasificar por dispersión.
  - [ ] 5 combinaciones marcadas `PROVISIONAL_baja_confianza` en Sec 2 (ACEITE+Botella, ACEITE+Lata, CHOCOLATE+Paquete, CHOCOLATE+Frasco, PANES+Funda) — decidir con conocimiento de mercado local si el patrón bimodal amerita desagregar en dos presentaciones distintas, o si se acepta la mediana tal cual.
  - [ ] 40 combinaciones `SIN_EVIDENCIA` en Sec 2 (1% de las observaciones pendientes, principalmente unidades de conteo: Unidad, Pieza, Cajita) — requieren peso de referencia externo. Baja prioridad, no bloquean el avance.
  - [ ] Confirmar tabla completa de códigos de unidad (fuente: `docs/Formulario ENGIH B. Gastos diarios del hogar.pdf`, sección "CÓDIGOS DE UNIDADES DE MEDIDA Y DE PRESENTACIÓN", 120 códigos en total, solo ~35 transcritos hasta ahora) — el código 113 en SALAMI no calza con la transcripción parcial actual, sin resolver
  - [x] **Verificado (2026-09-08):** el caso "GALLETAS DULCES+Botellón" (18,900g aplicado a un hogar) SÍ es atrapado por la detección de outliers existente en `03_transform.R` (agrupa por `enhance_id`, umbral 5×P99.5) — cálculo real: 10,800 g/día vs. umbral de 2,602 g/día. No corrompe los agregados finales, se excluye automáticamente. **Hallazgo importante derivado:** esa defensa depende de tener `enhance_id` validado por alimento — en Sec 3A, 622/770 filas del crosswalk aún no lo tienen, así que para la mayoría de Sec 3A la detección de outliers está efectivamente comprometida (mezclaría alimentos no relacionados bajo `enhance_id=NA`). Razón adicional (no solo nutricional) para priorizar cerrar la validación del crosswalk de Sec 3A.
- [ ] Corregir el bug de escala ×1000 en las 15 filas de FC específico ya rellenas en Sec 2 — **resuelto de facto**: esas 15 filas correspondían todas a unidades ya cubiertas por la tabla universal (nunca se usaban) y se limpiaron al regenerar el archivo.

**Protocolo de validación de FC** (cualquier combinación sospechosa, Sec 2 o Sec 3A): (1) extraer la fila cruda completa (vivienda/hogar); (2) revisar si la unidad base y cantidad_inicial/final ya tienen sentido físico por sí solas; (3) revisar si la misma vivienda repite otras respuestas atípicas; (4) documentar la decisión (validado / corregido, dejando el valor original / sin evidencia) — nunca sobrescribir sin dejar rastro.
- [x] Corregir la codificación de texto rota en 168 filas de la hoja FC de Sec 3A — **verificado resuelto (2026-09-08): 0 filas con codificación rota ahora.** Se resolvió como efecto secundario de reconstruir `data_raw_unidades.xlsx` desde cero el primer día de trabajo.
- [x] **Resuelto (2026-09-08):** colisión de `ENHANCE_ID` 70211110 — confirmado que era error de tipeo en la fuente (maíz colisionaba con sal de mesa; 0 duplicados en el resto de la tabla, y el maíz ya tenía "hermanos" bien numerados: 70211111, 70211188). Sin uso previo en ningún script (`05_ingesta_micronutrientes.R` sigue vacío, no había corrupción activa todavía). Reasignado el elote enlatado a `99211110` (prefijo 99 = corrección nuestra, no código oficial INCAP — verificar el código real contra la publicación fuente si se necesita este alimento más adelante). La sal (3 alimentos del crosswalk que ya usaban este ID) queda intacta.
- [x] **Resuelto (2026-09-08):** "Guandules verdes desgranados" y "Guandules verdes en cáscara" compartían el mismo `ENHANCE_ID` (70211088, EDIBLE=0.48 — correcto solo para la versión con cáscara). Creada fila nueva `99211088` (copia de 70211088 con EDIBLE=1.0, mismo prefijo 99 = corrección nuestra) y actualizado el crosswalk para que "desgranados" apunte ahí. "En cáscara" sigue en 70211088 sin cambios.
- [ ] Decidir arquitectura para los ítems de fuente FNDDS en el join final (su ID no es nativo de INCAP)

- [ ] **114 filas con `enhance_id` pero sin `tipo_equivalencia`** (detectado 2026-09-11). Heredadas de la fase inicial, anteriores al merge del 12-09 — no las introdujo ese merge. No bloquean el cálculo (el join usa `enhance_id`), pero sí la defensa metodológica: sin ese campo no se puede declarar si la equivalencia fue directa o por criterio. Trabajo mecánico, sin decisiones nuevas.
- [ ] **13 filas con `validado = TRUE` pero sin `enhance_id`** (detectado 2026-09-12: 420 validadas vs. 407 con código). Inconsistencia menor, no afecta el pipeline porque exige ambas cosas.
- [ ] **README desactualizado — ahora es urgente, no cosmético.** Dice "Fase activa: Fase 0" con fecha 05-09. **El enlace del repo se va a compartir con los supervisores**, y el README es el primer archivo que abren. Debe explicar el pipeline en cinco minutos: qué hace cada script, cómo reproducir las cifras, dónde están documentadas las decisiones. Lo más barato y más visible del repo.
- [ ] **Bug de "Docena" (código 52) — abierto desde el 10-09 y puede aparecer en R1.** El diccionario universal le asigna FC = 12 (un conteo, no gramos) y la tabla universal tiene prioridad sobre la específica, así que una docena de huevos devuelve 12 en vez de ~600 g. Afecta ~217 filas de Sec 3A y 1 de Sec 2 (0.06%), con subestimación sistemática de ~40x en esos ítems. No invalida los agregados por su tamaño, pero **puede verse en R1 como valores anómalamente bajos en alimentos comprados por docena**. Mejor declararlo que improvisar si lo notan en la presentación.
- [ ] **VERIFICAR antes del 16: el módulo demográfico de la ENGIH.** Fase 2 anota que el consumo aparente por AFE con mujeres 15-49, embarazadas y lactantes **requiere un módulo demográfico aún sin descargar**. Eso cambia cómo se declara la limitación de embarazo/lactancia en R1 y R2: no es lo mismo "la encuesta no captura el dato" que "está en un módulo que no se incorporó en esta etapa". La segunda es honesta y deja la puerta abierta; la primera sería incorrecta si el módulo existe.
- [ ] **Aplicar el diseño muestral complejo con `srvyr`** (`ESTRATO` 8 niveles, `UPM` 933, `FACTOR_EXPANSION`). Las tres variables están disponibles y el paquete está en el entorno. Mientras no se aplique, **todos los intervalos de confianza están subestimados**, incluido el que ya imprime `03_transform.R`. Los TdR lo piden explícitamente (numeral 3.3).
- [ ] **Unificar nomenclatura EMA / AFE / AWE.** Mismo constructo con tres nombres: los TdR dicen AFE, la presentación de Daniel dice EMA, el módulo 24 del repo `fortificacion` dice AWE. **Adoptar EMA** (término del material en español, y el que usa quien revisa). Ojo: **AME (Adult Male Equivalent) sí es un concepto distinto** y no debe fusionarse. Mencionarlo de entrada en la presentación, antes de que lo marquen en revisión.
- [ ] **Afinar la detección de atípicos.** La corrida del 12-09 marca 45 filas en Sec 3A de más de 300,000 — tasa muy baja. El umbral es deliberadamente conservador (marca sin eliminar), lo cual es defendible, pero hay que poder explicar el criterio si preguntan.
- [ ] **Limpieza del repositorio (después del 16-09, no antes).** El enlace se comparte con los supervisores. Quitar archivos redundantes con commits, no con borrado manual, para que todo quede en el historial. Identificados: `food_factors_BACKUP_2026-09-10.xlsx` (redundante, git ya es el respaldo), `lote_PC_109.csv` (lote ya incorporado), `.RDataTmp*` (agregar al `.gitignore`: la regla actual no lo atrapa por falta de comodín), y los scripts de uso único `96`, `97`, `98`, `99` una vez commiteados sus resultados.

- [ ] **Idea para el cierre de Fase 0 (anotada 2026-09-08, no ejecutar antes):** informe de estado del proyecto (crosswalk, FC, pipeline, hallazgos), con gráficos, para supervisores. **Condición para hacerlo bien:** debe generarse automáticamente desde los datos reales (script Quarto/R que lea el estado y corra el pipeline), nunca texto escrito a mano — si no, duplica `HOJA_DE_RUTA_PROYECTO.md` como fuente de verdad y puede desactualizarse. No es prioridad mientras Fase 0 siga abierta.

## Fase 1 — Pipeline de scripts (01 → 06)

**ESTRATEGIA ACORDADA (2026-09-09), para no perderla en una sesión nueva: avanzar por fases con los datos como están, no perfeccionar datos antes de avanzar.** El crosswalk al 55%/peso-por-unidad al 60% son suficientes para intentar `05_ingesta_micronutrientes.R` ya — no esperar a que estén completos. El pulido de datos (resto del crosswalk, cilantro/plátano/guineo, `VISION_Y_ARQUITECTURA_PROYECTO.md` desactualizado) se retoma después, documentado y sin bloquear el avance — la cobertura máxima sigue siendo la meta, solo pospuesta, no abandonada. **Si una conversación nueva por defecto propone "sigamos afinando datos", es la señal de que se perdió esta estrategia — corregir hacia 05/06.**

- [x] `01_import.R` — Q, FC (3 niveles), `enhance_id`, PC ensamblados. Corriendo limpio contra datos reales desde 2026-09-08.
- [x] `02_eda.R` — corregido y confirmado corriendo limpio (2026-09-08): overlap de hogares, estandarización de unidades, missingness, atípicos por alimento, cobertura del diario. Ver HITO arriba.
- [x] `03_transform.R` — corregido y confirmado corriendo limpio (2026-09-08): `Q × FC × PC / PM`, outliers marcados, ejemplo de cobertura ponderada real. Ver HITO arriba. Queda pendiente afinar: disponibilidad neta para alimentos almacenables, y el aviso de diseño muestral (IC subestimado).
- [x] **`04_equivalente_adulto.R` — completo y conectado con consumo diario (2026-09-08).** EMA por persona (fuente: FAO/WHO/UNU 2004, Tablas 4.2/4.3/5.2, no el documento de Daniel que solo las cita) y por hogar (8,892/8,892 con EMA, mediana 3.04 sin ponderar / **3,09 ponderada**), unido con `03_transform.R` → `Gramos_por_EMA_dia` (**303,407 registros** en la corrida del 12-09; las cifras de 254,905 y 296,969 son de corridas anteriores y quedaron desactualizadas al ampliarse la cobertura). **Limitaciones documentadas en el propio script:** sin ajuste embarazo/lactancia (dato no existe en la ENGIH), peso fijo por sexo (65/55kg, no individual), menores de 1 año con valor provisional (600 kcal, sin verificar contra FAO sección 3).
- [ ] `05_ingesta_micronutrientes.R` — join con INCAP/FNDDS completos (~65 nutrientes) sobre `data_gramos_por_ema.csv` (ya listo); consumo aparente de energía, macro y micronutrientes por EMA. **Único script del pipeline básico sin empezar** — pendiente por la complejidad de armonizar esquemas INCAP/FNDDS, no por falta de piezas previas (esas ya están).
- [ ] `06_report.qmd` — reporte reproducible base.

## Fase 2 — Marco analítico ampliado (Tang et al. 2021)

- [ ] **Especificación de Santiago (transcripción de audio, 2026-09-09) — objetivo real del análisis, para no perder el detalle:**
  1. **Cobertura:** proporción de la población que consume el vehículo fortificado (arroz, harina, o el conjunto de vehículos, como en Costa Rica).
  2. **Contribución del alimento fortificado a la ingesta de micronutrientes clave** (hierro, ácido fólico, y otros según la dieta promedio) — comparar ingesta basal (dieta sin fortificar) vs. ingesta con fortificación añadida.
  3. **Método: desplazamiento de la distribución respecto al EAR.** La ingesta se modela como distribución (aprox. normal); el EAR es el punto de corte que marca a la población con ingesta deficiente (cola izquierda de la curva). Al fortificar, toda la curva se desplaza a la derecha — una proporción de la población deja de estar por debajo del EAR. Esto es el método de punto de corte/probabilidad ya usado en MIMI, aplicado antes/después de fortificación.
  4. **Escenarios a modelar** (esto hace mucho más concreto el punto ya anotado abajo de "sin fortificar/norma actual/óptima"):
     - (a) Sin fortificación — línea base, ver qué nutrientes son deficientes.
     - (b) Fortificación según norma vigente en RD.
     - (c) Fortificación según estándar OMS.
     - (d) **Fortificación complementaria de otros alimentos** cuando el vehículo principal no puede llevar más nutriente por razones técnicas (ej. el arroz se oscurece y la gente lo rechaza si se le agrega más hierro) — usar los datos de consumo aparente ya construidos (`data_gramos_por_ema.csv`) para evaluar cuánto ayudaría fortificar, por ejemplo, la leche también.
  - **Implicación para 05_ingesta_micronutrientes.R:** cuando se construya, necesita poder simular "ingesta + X mg de nutriente por gramo de vehículo consumido" para cada escenario, no solo la ingesta real observada — es una capa de simulación sobre el consumo aparente, no solo un cálculo directo.
- [ ] Cobertura de vehículos de fortificación (arroz, aceite, harina, azúcar, sal) — % de hogares consumidores, por quintil de gasto, región, urbano/rural
- [ ] Consumo aparente por AME **y** AFE (mujeres 15-49, embarazadas/lactantes) — **requiere el módulo demográfico de ENGIH (aún sin descargar)**: trae composición del hogar (embarazadas, niños menores, etc.) y hay que conectarlo en `01_import.R` antes de poder calcular esto
- [ ] Densidad de nutrientes (por 1000 kcal) — separar calidad de dieta de cantidad de dieta
- [ ] Equidad — comparaciones por quintil, urbano/rural, región
- [ ] Escenarios de fortificación (sin fortificar / norma actual / cumplimiento perfecto / optimizada) para arroz, aceite, harina — **ver especificación detallada de Santiago arriba**
- [ ] Aporte de alimentos consumidos fuera del hogar, si ENGIH lo captura con suficiente detalle (requiere factores de receta — evaluar viabilidad antes de comprometerse)

## Fase 3 — Dashboard

- [ ] Definir audiencia y decisiones que debe soportar (¿uso interno WFP? ¿Ministerio de Salud/SESPAS?)
- [ ] Seleccionar indicadores clave (cobertura, prevalencia de inadecuación, densidad, equidad)
- [ ] Prototipo (herramienta a decidir: Shiny, Quarto dashboard, u otra)
- [ ] Iterar con retroalimentación de Carlos Rodas y Daniel Hernández
- [ ] **Revisión editorial/creativa antes de presentar (no antes — solo cuando haya contenido real que pulir):** pasada de Claude como editor crítico sobre `06_report.qmd` y los materiales de presentación — tono, concisión, que no "suene a transcripción de IA" (frases repetitivas, exceso de explicación). Los documentos internos (`HOJA_DE_RUTA`, `VISION`) NO se tocan para esto — su densidad técnica es correcta para lo que son, un log de trabajo, no un entregable.

## Fase 4 — Artículo

- [ ] Definir estructura (Tang et al. 2021 como modelo de referencia)
- [ ] Métodos: crosswalk, FC, PC, AME/AFE, escenarios de fortificación
- [ ] Resultados: cobertura, consumo aparente, densidad, equidad, escenarios
- [ ] Discusión y limitaciones (HCES vs. consumo individual; ver caveats metodológicos ya identificados en las notas del proyecto)

---

*Próximo paso inmediato: "peso por unidad" (Sec 2 ~8,655 filas, Sec 3A ~79,181 filas) empezando por Cebolla roja, Huevos de granja, Pan sobado, Cilantrico, Ají cubanela, Ajo, Plátano verde. En paralelo, cuando haya tiempo: los 49 candidatos de Sec 2 y los 68+758 de Sec 3A marcados para revisión manual.*

---

## Fase 5 — Presentación del 2026-09-16

**Encuadre.** No es entrega final: el contrato corre hasta el 2026-10-25 y los TdR condicionan formalmente los productos 8.1–8.6 al resultado del análisis preliminar (numeral 4). Esta reunión es el **hito de factibilidad** — el dictamen sobre si la ENGIH 2018 permite implementar la metodología. Conviene decirlo en el primer minuto.

**Estructura en tres actos:**

1. **¿Sirven estos datos?** Cobertura, factores de conversión, porción comestible, atípicos, adaptaciones metodológicas. Responde los numerales 4.1–4.3 y 7 de los TdR. Establece la regla que rige toda la presentación: ninguna cifra se cita sin su cobertura. Aquí van los problemas resueltos (fan-out de 17,698 filas, guardas de integridad, trabajo de campo en el mercado, cereza→acerola) como evidencia de dato auditado, no como anécdotas.
2. **El modelo de base.** `Q × FC × PC / PM` primero, EMA después — el mismo orden de las dos presentaciones de Daniel, y en su orden cronológico (dic-2025, ago-2026). Es mostrarle su metodología implementada sobre datos dominicanos reales.
3. **Hacia lo que le sirve al PMA.** La especificación de Santiago en su orden: cobertura de vehículos, contribución del alimento fortificado, desplazamiento respecto al EAR, escenarios. Cierra con replicabilidad: el paquete va a Perú, RD y Cuba, y los TdR (numerales 9, 10, 12) piden código modular y adaptable.

**Frontera explícita** al final del Acto 2: *hasta aquí entregable cerrado; de aquí en adelante línea de trabajo abierta con decisiones pendientes que corresponden a los supervisores.* Decirlo en voz alta protege los dos primeros actos de lo que falte en el tercero, y convierte el final abierto en una solicitud de decisión en vez de un vacío.

**Reportes, clasificados por defendibilidad.** Un reporte es defendible cuando cada cifra sale de datos reales, se reporta con su cobertura, y no depende de una decisión sin resolver.

| | Reporte | TdR | Estado |
|---|---|---|---|
| R1 | Calidad y preparación de los datos | 4.1–4.3, 7 | Compromiso firme |
| R2 | Modelo de base: consumo diario y EMA | 1.3, 1.4, 8.2 | Compromiso firme |
| R3 | Cobertura de vehículos fortificables | 8.1 | Compromiso firme |
| R4 | Ingesta aparente de micronutrientes | 8.3 | Solo como dos escenarios en paralelo |
| R5 | Desplazamiento respecto al EAR y escenarios | 8.3 | Método especificado, no ejecutado |

**R3 es inmune a la decisión de línea base**: la cobertura pregunta si el hogar consume arroz, no si ese arroz estaba fortificado. Por eso es compromiso firme aunque la línea base siga sin resolverse.

**R4 nunca se presenta como cifra única.** Se corre sin fortificar y con norma RD en paralelo; el rango entre ambos *es* la demostración de por qué la decisión importa y por qué les corresponde a los supervisores.

**Dashboards.** D1 (estado del pipeline, sin ninguna cifra nutricional, autogenerado) primero; D2 (resultados, cuatro paneles = los cuatro indicadores del TdR 4.1–4.4) después del `05`. **Antes de D2 hay que definir audiencia** — uso interno del PMA o Ministerio de Salud — porque decide si se muestran intervalos y limitaciones o mensajes de política. Pregunta para Santiago. Argumento de utilidad: el numeral 11 de los TdR pide recursos de aprendizaje interactivos, así que el dashboard **no es un extra, es un activo del módulo 4** y la plantilla de visualización del sistema de evaluación, probada en un país y lista para adaptar a los otros dos.

**Infraestructura compartida:** `scripts/_comun.R` centraliza rutas, carga, definición de vehículos de fortificación y la regla de elegibilidad (`marcar_elegible()`). Al mejorar los datos o cambiar una definición se toca ahí y todos los reportes quedan consistentes — es lo que impide que R1 diga 89.2% y R3 diga otra cosa. **Ningún reporte lleva cifras escritas a mano.**

**Resuelto (2026-09-11):** la aparente discrepancia entre H-AR (presentación de Daniel) y EAR con enfoque probabilístico (TdR numeral 1.6). La especificación de Santiago transcrita en Fase 2 ya fija **EAR con punto de corte**, alineado con los TdR. No es pregunta abierta.

**Decisiones a llevar a la reunión, no a resolver por cuenta propia:**
1. Línea base de fortificación (ver "Decisión abierta" en Fase 0).
2. Si se suman Sección 2 y Sección 3A, o se reporta solo 3A — una es inventario (stock) y la otra adquisiciones (flujo), y sumarlas puede ser doble conteo en almacenables. Evidencia a llevar: correr ambas por separado y comparar magnitudes contra la ENM.
3. Fuentes para los 21 alimentos sin equivalencia en INCAP ni FNDDS.

**Orden de trabajo (de mayor a menor valor, para que lo que no quede hecho sea lo menos importante):** R1 → `05` → R2 y R3 → R4 en dos escenarios → README. D1, D2 y R5 son lo primero que se sacrifica.

**Infraestructura de trabajo (fin de semana del 12–14):** dos máquinas. PC-A (trabajo, dentro de OneDrive del PMA — riesgo conocido de cuelgue en `.git/objects`) y PC-B (prestada, se devuelve el lunes 15). Regla: **PC-B escribe, PC-A solo lee**; `git pull` al empezar, `git push` al terminar. **PC-A debe quedar verificada (paquetes, Quarto, identidad de git) antes de devolver PC-B**, porque el último día y medio de preparación ocurre ahí. Es el único riesgo del fin de semana sin arreglo posible.
