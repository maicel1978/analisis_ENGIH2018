# Hoja de ruta — Proyecto ENGIH 2018 (Consumo y Nutrición, WFP)

**Congelada el:** 2026-09-03
**Última actualización:** 2026-09-12
**Objetivo final:** artículo científico + dashboard de apoyo a decisiones, siguiendo el marco ampliado de Tang et al. (2021) sobre la base metodológica de Imhoff-Kunsch (2012).

Este documento fija el alcance acordado hasta ahora. Cualquier cambio de alcance debería reflejarse acá explícitamente antes de asumirse en el trabajo diario — si algo cambia, se edita esta hoja, no se improvisa por fuera de ella.

---

## PRIORIDAD ACTUAL (leer esto primero, antes que Fase 0 de abajo)

**Al 2026-09-12 (noche): pipeline `01`→`05` completo, R1 y R3 renderizados. Lo que sigue, en este orden:**

1. **Re-renderizar R3** con el `pct()` corregido y verificar que los porcentajes ya no se repiten (Arroz 87.7 / Aceite 87.3 / Azúcar 78.6 / Harina 8.0). Re-renderizar R1 también (usa la misma función).
2. **R2 — modelo de base: consumo diario y EMA.** Único reporte de compromiso firme que falta. Sale de datos ya calculados: es sobre todo redacción. Debe explicar `Q × FC × PC / PM`, el EMA (8,892/8,892 hogares, mediana 3.04), y el asunto de las dos secciones con la tabla de tres variantes.
3. **README.** Primer archivo que abren los supervisores al recibir el enlace.
4. **Verificar PC-A** antes de devolver PC-B: `git pull`, paquetes (`dplyr readr tidyr readxl writexl here knitr srvyr`), `quarto::quarto_version()`, identidad de git, y que el repo **no** esté en OneDrive.

**Estado de los entregables:** R1 hecho, R3 hecho (pendiente re-render), R2 pendiente, R4 y R5 **descritos y no ejecutados** según lo acordado. D1 y D2 fuera de alcance para esta entrega.

**Cambio de fecha (2026-09-12): la fecha real de cierre es el domingo por la noche**, no el martes 16. El martes es margen. Criterio derivado: ya no se trata de *qué alcanzo a terminar*, sino de **qué queda tan bien documentado que se entienda sin el consultor presente**. Lo que no se ejecute (R4, R5, D1, D2, desglose por quintil) se entrega **descrito**, con método definido, variables verificadas y una nota de qué falta para correrlo. Después, llevar a Daniel/Carlos la decisión sobre la línea base de fortificación (ver "Decisión abierta" al final de Fase 0), que sigue siendo el hallazgo metodológico más importante sin resolver.

**Fecha límite dura: reunión del 2026-09-16.** Ver "Fase 5 — Presentación" al final de este documento para el alcance comprometido y lo que queda explícitamente fuera.

*(Anterior, 2026-09-10: revisar y cargar los 154 mapeos confirmados + correr el `05`. El primero quedó hecho el 12-09; el segundo sigue vigente.)*

*(Anterior, 2026-09-09: avanzar por fases con los datos como están, no perfeccionar datos antes de avanzar. Sigue vigente, con el matiz aprendido el 12-09: **se justifica volver atrás cuando el arreglo es acotado, no requiere criterio nuevo y bloquea algo que ya se está por mostrar — los tres a la vez.** Si falta alguno, se anota y se sigue. Ejemplo real: completar el PC de 154 alimentos costó 30 minutos y subió la cobertura efectiva de 86.5% a 89.2% antes de publicarla en R1; postergarlo habría obligado a rehacer el reporte.)*

**Al 2026-09-10: lo que sigue es (1) revisar y cargar los 154 mapeos confirmados del crosswalk Sec 3A, y (2) correr `05_ingesta_micronutrientes.R` por primera vez** — el script ya está escrito y versionado. Después de eso, llevar a Daniel/Carlos la decisión sobre la línea base de fortificación (ver "Decisión abierta" al final de Fase 0), que hoy es el hallazgo metodológico más importante sin resolver: el crosswalk actual asume arroz fortificado y harina/azúcar sin fortificar, que es lo inverso a la norma dominicana de 2018.

*(Anterior, 2026-09-09: empezar `05_ingesta_micronutrientes.R` (Fase 1), NO seguir la lista de pendientes de Fase 0 — esa lista es real pero se retoma después, ver "ESTRATEGIA ACORDADA" en Fase 1. Sigue vigente como criterio.)*

**Para no caer en un ciclo infinito intentando mapear los ~65 nutrientes de una vez:** empezar con solo 4 — **Energía, Hierro, Ácido fólico, Vitamina A** (los que Santiago nombró explícitamente + los que ya tienen benchmark de comparación, la ENM 2009/2024 mencionada más abajo). Conseguir esos 4 corriendo de punta a punta primero. Ampliar a más nutrientes después de tener ese resultado, no antes.

**Antes de escribir el join:** revisar los nombres exactos de columna en `food_composition_INCAP.xlsx` (ej. `ENERC_KCAL`, `FE`, `FOLDFE`, `VITA_RAE`) vs. `food_composition_FNDDS.xlsx` (nombres en inglés tipo "Energy (kcal)", "Iron, Fe (mg)") — **no son los mismos nombres ni necesariamente las mismas unidades** (mg vs mcg, por ejemplo). Construir la tabla de equivalencia de columnas primero, como un paso explícito y verificado, no asumido.

---

## Fase 0 — Cerrar la base de datos (prerrequisito, en curso)

- [x] **HITO (2026-09-12): crosswalk Sec 3A cerrado, porción comestible completa y pipeline verificado de punta a punta.**

  1. **Cargados los 154 mapeos revisados + 15 correcciones manuales** (`99_aplicar_correcciones_crosswalk.R`). Sec 3A pasa de 253 a **407 alimentos mapeados de 769** (89.2% de los registros). Las 15 correcciones salieron de revisar uno por uno el bloque que `data/eda/revision_154_sugerencias.csv` había marcado "OK": 9 eran errores del tipo ya anticipado (parte del alimento, estado de preparación, grado de procesamiento) y 6 venían marcadas DUDOSA/NO. Ejemplos: Cereza → acerola (en RD "cereza" es acerola: 1600 vs 7 mg vit C/100g); Jamón ahumado apuntaba a jamón de **pavo**; Hígado de pollo apuntaba a **paté** envasado; Macarrones a pasta **enlatada** con queso. **Tasa real de error de la sugerencia automática: 9/148 = 6.1%** — cifra citable para justificar por qué la revisión manual no era opcional. Trazabilidad fila por fila en `data/eda/log_merge_crosswalk_2026-09-11.csv`.

  2. **+154 filas de porción comestible** (`98_completar_PC_lote154.R`, `food_factors.xlsx` 253 → 407). El merge anterior dejó 154 alimentos con `enhance_id` pero sin PC, así que **no entraban al cálculo pese a estar mapeados**: la cobertura efectiva seguía en 86.5%, no en 89.2%. Los 154 eran todos INCAP y todos tenían `EDIBLE` en la tabla — extracción determinista, sin criterio. Log en `data/eda/log_PC_lote154_2026-09-12.csv`. Mismo patrón que el lote de 109 del 10-09.

  3. **BUG SILENCIOSO corregido: `validado` con tres representaciones distintas** (`97_normalizar_tipos_crosswalk.R`). Al reescribir el crosswalk con `writexl` tras leerlo con `col_types="text"`, la columna quedó con "TRUE" (265 filas), "VERDADERO" (154, las recién cargadas) y "1" (1 fila). `01_import.R` filtra con `validado == TRUE`, así que **las 154 filas nuevas se habrían descartado sin aviso**: el pipeline habría corrido sin un solo error y reportado la cobertura anterior. Lo que lo atrapó fue un error *distinto* y ruidoso (tipos incompatibles en el join de Sec 2) que obligó a abrir el archivo. **Regla adoptada: no reescribir un Excel de entrada leyéndolo con `col_types="text"`** — convierte a texto columnas numéricas y booleanas y rompe supuestos aguas abajo. **Nota incómoda y útil: este fallo estaba anticipado por escrito en esta misma hoja desde el 10-09** (ver backlog del 10-09, "Tipado explícito en las lecturas de Excel", que recomienda `filter(validado %in% c(TRUE, 1))` en lugar de `== TRUE`). La hoja hizo su trabajo; falló el no consultarla antes de actuar. **Regla de proceso: antes de tocar un archivo de entrada, releer el backlog de Fase 0.**

  4. **CORRECCIÓN IMPORTANTE (2026-09-12, tras el primer render de R1): 89.2% es cobertura del *crosswalk*, NO del cálculo.** Son dos métricas distintas y en los mensajes de trabajo de ese día se usaron como si fueran la misma. La cifra citable en la presentación es la segunda: **Sec 3A entra al cálculo al 76.0%** (260,014 de 342,046 filas) y **Sec 2 al 90.7%** (43,393 de 47,837). El 89.2% mide qué proporción de los *registros* tiene alimento mapeado; el 76.0% mide cuántas *observaciones* tienen además FC, PC y no son atípicas — que es lo que exige la fórmula. **Si se presenta 89.2% como cobertura del análisis y alguien recalcula, la cifra se cae.** Regla derivada: al citar cobertura, decir siempre *de qué* (crosswalk / cálculo) y *de qué sección*.

  5. **Corrida completa verificada (12-09).** Sec 3A: 342,046 filas, 36,841 sin `enhance_id` (89.2% mapeado), 36,841 sin PC — **los dos números coinciden, confirmando que ya no queda alimento mapeado sin porción comestible**. Sec 2: 47,837 filas, 62 sin mapeo y 62 sin PC. Outliers: Sec 2 = 11, Sec 3A = 45. EMA: 8,892/8,892 hogares, mediana 3.04. **Gramos por EMA: 303,407 registros** (era 296,969 el 10-09 y 254,905 el 08-09).

  6. **Cambió el cuello de botella.** Sec 3A tiene 48,684 filas sin factor de conversión contra 36,841 sin mapeo. **De aquí en adelante, el trabajo de cobertura rinde más en la tabla de FC que en el crosswalk.** Esto invierte la conclusión del 10-09, que decía que todo lo que quedaba por ganar estaba en el crosswalk: era cierto entonces, ya no.

- [x] **HITO (2026-09-10): dos bugs de corrupción silenciosa corregidos + guardas de integridad en el pipeline + cobertura de PC ampliada.** Origen: auditoría externa independiente (réplica del pipeline en Python), revisada y verificada punto por punto contra los archivos reales antes de aplicar nada.

  1. **Fan-out de 17,698 filas en Sec 3A (crítico).** En `data_raw_unidades.xlsx` hoja "Cuest. B Sec 3A", Pan sobado y Ají grande (cubanela) con unidad=1 tenían *dos* filas de FC cada uno (la mediana del crudo y el peso-por-unidad agregado el 08-09). El `left_join()` por `descripcion`+unidad duplicaba cada fila del crudo que coincidía: 9,131 de Pan sobado + 8,567 de Ají cubanela. Sec 3A pasaba de 342,046 a 359,744 filas y esos dos alimentos quedaban doble-contados aguas abajo. **Toda corrida posterior al 2026-09-08 y anterior a hoy produjo resultados corruptos.** Corregido retirando el FC de las dos filas viejas (45 g y 90.7 g), con el valor original conservado en `nota` y `validacion = RETIRADO_duplicado_clave`.
  2. **Las 3 filas de peso-por-unidad de Sec 2 nunca se aplicaron.** HUEVOS, PANES y GALLETAS SALADAS se agregaron el 08-09 sin la columna `variedad`, que es la clave del join de Sec 2. Se perdían 4,242 filas (2,637 + 1,090 + 515), incluido el 100% de los huevos comprados por unidad. **Corrige la afirmación del 08-09 ("ya funciona con la lógica existente sin tocar código"): era cierto para Sec 3A (une por `descripcion`) y falso para Sec 2 (une por código numérico).** Completadas `variedad` (15/1/3) y `frecuencia_datos`, verificadas contra las otras filas del mismo alimento.
  3. **Guardas de integridad en `01_import.R`.** Los tres errores de esta semana son del mismo tipo: una fila mal escrita en un Excel que el pipeline acepta en silencio. Se agregó `verificar_tabla_join()`, que **detiene la corrida** (`stop()`, no `warning()`) si una tabla de join tiene claves duplicadas o filas con FC y clave vacía; más `stopifnot()` de que el crudo no crece al unir (47,837 y 342,046). Confirmado en la corrida de hoy: "OK -- Sec 2: 82 filas" / "OK -- Sec 3A: 619 filas".
  4. **+109 filas de PC en `food_factors.xlsx` (144 → 253).** Se detectó que 109 alimentos ya tenían `enhance_id` validado pero no tenían fila de porción comestible, perdiendo ~8,760 filas del crudo por una ausencia puramente mecánica (71 con `EDIBLE` de INCAP; 38 de FNDDS a 1.00 por la convención ya documentada en la hoja). **Efecto estructural: "sin enhance_id validado" y "sin PC/edible" ahora son idénticos (Sec 3A: 46,012; Sec 2: 62) — el PC dejó de ser un cuello de botella independiente y todo lo que queda por ganar está en el crosswalk.** Corrige el ítem del 08-09 sobre las 54,772 filas sin PC.

  **Cifras de la corrida del 2026-09-10 (post-fix, `01`→`04`):**
  Sec 2: 47,837 filas | universal 22,316 | específica 21,108 | sin FC 4,413 | con FC sin PC 20 | **entran al cálculo 43,404 (90.7%)**.
  Sec 3A: 342,046 filas | universal 107,095 | específica 186,268 | sin FC 48,683 | con FC sin PC 39,742 | **entran al cálculo 253,621 (74.1%)**.
  Outliers marcados: Sec 2 = 11, Sec 3A = 45. Hogares con EMA: 8,892/8,892, mediana 3.04.
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
- [x] **`04_equivalente_adulto.R` — completo y conectado con consumo diario (2026-09-08).** EMA por persona (fuente: FAO/WHO/UNU 2004, Tablas 4.2/4.3/5.2, no el documento de Daniel que solo las cita) y por hogar (8,892/8,892 con EMA, mediana 3.04), unido con `03_transform.R` → `Gramos_por_EMA_dia` (**303,407 registros** en la corrida del 12-09; las cifras de 254,905 y 296,969 son de corridas anteriores y quedaron desactualizadas al ampliarse la cobertura). **Limitaciones documentadas en el propio script:** sin ajuste embarazo/lactancia (dato no existe en la ENGIH), peso fijo por sexo (65/55kg, no individual), menores de 1 año con valor provisional (600 kcal, sin verificar contra FAO sección 3).
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