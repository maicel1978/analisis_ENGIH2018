# Hallazgos y problemas — Auditoría del proyecto ENGIH 2018 (2026-09-10)

> **Documento de entrega para sesión de trabajo con IA.** Autocontenido: no requiere ningún otro archivo de la auditoría.
>
> **Estado del repo al que aplica:** `main` @ commit `d84fd4a` ("Actualizar arquitectura e ingesta de micronutrientes", 2026-09-09). Todos los problemas descritos aquí están **abiertos en ese estado**.
>
> **Método de la auditoría:** réplica independiente del pipeline 01_import → 02_eda → 03_transform → 04_equivalente_adulto → 05_ingesta en Python (pandas/openpyxl), reproduciendo función por función la lógica de los scripts R sobre los mismos archivos de `data/raw/`. Cuando una cifra de la documentación y la réplica coinciden, la cifra está verificada por dos caminos independientes. También se inspeccionaron directamente los Excel de referencia y el crudo.

---

## 0. Reglas para la IA que recibe este documento

1. **Verificar antes de actuar:** cada afirmación de aquí incluye su evidencia (archivo, hoja, columna, conteos). Re-verificar contra los datos antes de corregir; nada debe aplicarse "porque este documento lo dice".
2. **Preservar valores originales:** toda corrección a un Excel conserva el valor original (columna `nota`/`validacion` o historial de git) con justificación — principio 6 de `VISION_Y_ARQUITECTURA_PROYECTO.md`.
3. **No decidir lo que corresponde al equipo:** la sección 5 lista decisiones metodológicas que NO deben automatizarse (línea base de fortificación, supuestos de pan/pastas, aprobación de entradas nuevas).
4. **Fechar toda cifra:** la lección principal de esta auditoría es que las cifras sin fecha mienten (el "254,905" documentado era correcto para el 08-09 y dejó de serlo al día siguiente).
5. **Regla de honestidad:** todo resultado de consumo/ingesta se cita junto con su % de cobertura de filas (hoy: Sec 2 ≈ 90.7%, Sec 3A ≈ 71.9% — ver §6).

---

## 1. Qué está verificado y es CONFIABLE (no re-auditar)

| Cifra documentada | Fuente de la documentación | Verificado por réplica independiente |
|---|---|---|
| Crudo Sec 2: 47,837 filas | HOJA_DE_RUTA | ✅ 47,837 |
| Crudo Sec 3A: 342,046 filas | HOJA_DE_RUTA | ✅ 342,046 |
| Sec 2 FC: universal 22,316 / específica 16,866 / sin FC 8,655 (corrida 05-09) | HOJA_DE_RUTA | ✅ las tres exactas (para ese estado de datos) |
| Sec 3A FC universal: 107,095 (corrida 05-09) | HOJA_DE_RUTA | ✅ exacto |
| Crosswalk Sec 3A: 420/769 filas validadas | HOJA_DE_RUTA | ✅ 420/769 |
| `food_factors` cubre 144 de 770 alimentos (Sec 3A) | HOJA_DE_RUTA | ✅ 144 |
| 8,892/8,892 hogares con EMA, mediana 3.04 | HOJA_DE_RUTA / 04 | ✅ 8,892, mediana 3.04, 28,394 personas, 0 sin EMA |
| Sec 2: 11 outliers (hito 08-09) | HOJA_DE_RUTA | ✅ 11 (42 en Sec 3A en estado actual) |
| Cobertura arroz 70213002: 30.0% (IC 28.9–31.1) | 03_transform.R | ✅ 30.0%; con diseño muestral completo (ESTRATO/UPM, disponibles) da 28.9–31.1% |
| Codificación rota Sec 3A: 0 filas | HOJA_DE_RUTA | ✅ 0 filas con "Ã" |
| EMA: fórmula FAO/WHO/UNU 2004 correctamente aplicada | 04 | ✅ verificada hasta la fuente primaria (BMR 14.818×55+486.6)×1.76 = 2290.8 |

**Verificaciones estructurales (útiles para 05_ingesta):**
- Los 1,466 `ENHANCE_ID` de INCAP y los 7,083 `Food code` de FNDDS son **conjuntos disjuntos** (intersección vacía): se pueden combinar con `bind_rows` sin colisión. Ninguno falta en su tabla.
- Las 4 columnas de nutrientes iniciales existen con esos nombres exactos: INCAP `ENERC_KCAL`, `FE`, `FOLDFE`, `VITA_RAE`; FNDDS `Energy (kcal)`, `Iron\n(mg)` (¡con salto de línea real en el nombre!), `Folate, DFE (mcg_DFE)` (NO usar "Folate, food" ni "Folate, total"), `Vitamin A, RAE (mcg_RAE)`. Ambas tablas son **por 100 g**. Unidades idénticas para estos 4.
- Ningún `enhance_id` validado del crosswalk apunta a un ID inexistente en su tabla de fuente (0 huérfanos). La columna `fuente` es consistente con la tabla real donde vive cada ID.
- Los 144 alimentos de `food_factors` (Sec 3A) están todos dentro de los 253 con crosswalk validado → **el PC (porción comestible) es el cuello de botella real de cobertura**, no el crosswalk.

---

## 2. PROBLEMAS ACTIVOS (abiertos en `main` @ d84fd4a), por severidad

### P1 — BUG crítico: fan-out de 17,698 filas duplicadas en Sec 3A

**Dónde:** `data/raw/data_raw_unidades.xlsx`, hoja **"Cuest. B Sec 3A"**, y el `left_join` de FC específico en `scripts/01_import.R` (unión por `descripcion` + `id_unidad_medida_presentacion`).

**Qué pasó:** al añadir las filas de "peso por unidad" (unidad código 1) el 08/09-09, dos alimentos quedaron con la **clave duplicada** en esa hoja:
- **Pan sobado** + unidad 1: fila antigua FC=45 g (mediana del crudo, N=9) Y fila nueva FC=50 g (UMPIH/ProCompetencia).
- **Ají grande (cubanela)** + unidad 1: fila antigua FC=90.7 g (mediana del crudo, N=5) Y fila nueva FC=288 g (pesaje de campo propio, 5 unidades=1,440 g).

**Efecto:** `left_join()` de dplyr contra claves duplicadas **duplica cada fila del crudo que coincide**: 9,131 filas de Pan sobado + 8,567 de Ají cubanela = **17,698 filas espurias**. Sec 3A pasa de 342,046 a 359,744 filas tras el join, y el consumo de esos dos alimentos queda **doble-contado** en 03/04/todo lo aguas abajo. Es silencioso: no da error, no cambia los mensajes de conteo de FC de forma obvia (la cobertura "mejora").

**Advertencia sobre cifras documentadas:** los números del run 05-09 (155,770 específica) NO están corruptos (eran anteriores a las filas nuevas). Toda corrida posterior al 08-09 sin corregir esto produce resultados corruptos.

**Corrección recomendada (en los datos, con trazabilidad):**
1. En la hoja "Cuest. B Sec 3A", quitar el FC de las DOS filas antiguas (Pan sobado id_variedad=2 FC=45; Ají cubanela id_variedad=392 FC=90.7), conservando el valor original en la columna `nota` y marcando `validacion` (p.ej. `RETIRADO_duplicado_clave`). Las filas de peso-por-unidad (más recientes, con fuente documentada) quedan como vigentes.
2. Añadir en `01_import.R` un check que **detenga la corrida** si cualquier tabla usada en un join tiene claves duplicadas (y también filas con FC pero clave vacía — ver P2). Verificación mínima en R:
```r
sec3a_fc_especifico |> count(descripcion, id_unidad_medida_presentacion) |> filter(n > 1)  # debe ser 0 filas
nrow(sec3a_data) == 342046  # tras todos los joins, el crudo NO puede crecer
```
3. Regla de oro para el futuro: **toda fila nueva en un Excel de join se escribe por nombre de columna y se comprueba primero que la clave no exista** (este mismo patrón de error ya había ocurrido el 09-08 con las columnas corridas).

**Cómo verificar el fix:** tras regenerar, Sec 3A debe tener exactamente 342,046 filas post-join; FC: universal 107,095 / específica 186,268 / sin FC 48,683.

### P2 — BUG crítico: las 3 filas de "peso por unidad" de Sec 2 son inertes

**Dónde:** `data/raw/data_raw_unidades.xlsx`, hoja **"Cuest. B Sec 2"**, filas de HUEVOS (FC=53), PANES (FC=50) y GALLETAS SALADAS (FC=3), añadidas el 08-09.

**Qué pasó:** esas filas se crearon **sin la columna `variedad`**, que es la clave del join de Sec 2 (`left_join(sec2_fc_especifico, by = c("id_variedad" = "variedad", ...))`). Nunca se aplican. La afirmación en HOJA_DE_RUTA ("ya funciona con la lógica existente del pipeline sin tocar código") es **incorrecta para Sec 2** (para Sec 3A sí funcionó, porque esa hoja se une por `descripcion`).

**Impacto medido:** 2,637 filas de HUEVOS (variedad 15) + 1,090 de PANES (variedad 1) + 515 de GALLETAS SALADAS (variedad 3) compradas "por Unidad" quedan sin FC = **4,242 filas sin resolver**. En particular, TODOS los registros de HUEVOS de Sec 2 (2,732) están a 0% resueltos.

**Corrección recomendada:** llenar `variedad` en esas 3 filas (15 / 1 / 3 — valores tomados de las propias filas del mismo alimento en la misma tabla) y, si se quiere, `frecuencia_datos` (2,637 / 1,090 / 515). Verificación post-fix: Sec 2 sin FC baja de 8,655 a **4,413**; FC específica sube a 21,108.

### P3 — ERROR METODOLÓGICO CRÍTICO (decisión del equipo, NO automatizar): la línea base de fortificación está invertida respecto a la RD real de 2018

**Dónde:** `data/raw/crosswalk_tablas_composicion.xlsx` — mapeos de arroz, harina de trigo y azúcar.

**Evidencia (verificada contra el programa nacional y contra las entradas reales de la tabla INCAP):**

| Vehículo | Programa real RD ~2018 | A dónde apunta el crosswalk hoy | Efecto |
|---|---|---|---|
| Arroz | **NO fortificado** (no existe norma de arroz) | ARROZ (Sec2 var. 7), Arroz selecto (66) y Súper-selecto (65) → `70213002` "Arroz blanco… **enrio.**" (Fe 4.36, folato 386 mcg/100g). Solo "Arroz corriente" (67) → `70213004` s/enrio (Fe 0.80, folato 9) | **Sobrestima** Fe/folato del alimento #1 de la dieta |
| Harina de trigo | **Fortificación OBLIGATORIA desde 2009** (NORDOM: 45 mg/kg Fe fumarato ferroso, 1.8 mg/kg ácido fólico, tiamina, riboflavina, niacina) | Harina de trigo (58) → `70213038` "Harina de trigo, **s/enriquecer**" (Fe 1.17, folato 26) | **Subestima** Fe/folato |
| Azúcar | **Fortificada con vitamina A** (NORDOM 606: 5–25 mg/kg) | AZUCARES (Sec2 var. 29) → `70215001` "s/fortificar" (vit A=0); Azúcar blanca refinada (458) → `70215036` (vit A=0) | **Subestima** vitamina A |
| Sal | Yodada (NORDOM 14) | 70211110 | irrelevante para los 4 nutrientes actuales |

Fuentes: Informe ENM 2009 RD (repositorio MSP — describe el programa: harina de panificación fortificada, azúcar con vitamina A, sal yodada; "solo la harina de trigo usada en panificación está fortificada"); FFI, informe final del estudio de fortificación RD (obligatoria para harina desde 2009; pastas/galletas **voluntaria**). NOTA: la harina de maíz también se fortifica en RD — el crosswalk la apunta a `70213031` (sin evaluar en esta auditoría para los 4 nutrientes).

**Impacto cuantificado** (réplica Python, mediana hogar por EMA, ponderada por factor de expansión, con P1+P2 corregidos):

| Escenario | Hierro mg (%hog<EAR 8.1) | Folato mcg (%hog<EAR 320) | Vit A mcg (%hog<EAR 500) |
|---|---|---|---|
| (a) Sin fortificación (arroz→70213004, harina→70213038, azúcar→70215001) | 8.7 (44.8%) | 266 (60.3%) | 163 (86.9%) |
| (b) Norma RD 2018 (arroz sin fortificar, harina→70213039, azúcar→70215002) | 8.9 (44.3%) | 274 (59.3%) | 326 (**60.3%**) |
| (c) Crosswalk actual (= mixto, NO es un escenario real) | 13.8 (24.8%) | **794 (23.3%)** | 163 (86.9%) |

La diferencia en folato entre (c) y (a/b) es **~3× la mediana**: no es un matiz, es otra conclusión. El resultado de vitamina A con azúcar fortificada (b) es el efecto de política pública más claro detectado hasta ahora.

**Por qué es tractable:** la tabla INCAP ya tiene las entradas pareadas (70213002/70213004 arroz; 70213039/70213038 harina; 70215002/70215001 azúcar — valores verificados en la tabla real). **Los escenarios de fortificación se implementan como una capa que intercambia el `enhance_id` por vehículo** (sin datos nuevos), conservando un `enhance_id_base` para volver al estado observado.

**Decisiones que corresponden al equipo (Daniel/Carlos/Santiago):**
1. Confirmar (b) como línea base "situación 2018".
2. Qué asumen pan/pastas/galletas: en RD la fortificación de harina para pastas/galletas es VOLUNTARIA (FFI) — hoy mantienen su entrada INCAP tal cual; hay que declararlo por escenario.
3. Verificar si "Arroz selecto/súper-selecto" venían realmente enriquecidos en el mercado dominicano de 2018 (el crosswalk lo asume; "seleccionado" en RD se refiere a calidad de grano, no a fortificación — sospechoso).
4. El escenario (c) solo debe reportarse como "crosswalk actual", nunca como línea base.

### P4 — 154 mapeos validados y confirmados cuyo `enhance_id` nunca se copió (9,172 registros del crudo)

**Dónde:** `data/raw/crosswalk_tablas_composicion.xlsx`, hoja "Cuest. B Sec 3A".

**Evidencia:** 167 filas tienen `validado=TRUE` con `enhance_id` vacío. De esas, **154** tienen en `notas` texto del tipo *"Confirmado: sugerencia automática revisada contra INCAP y es correcta"* — el trabajo de validación está HECHO; el ID correcto vive en la columna **`sugerencia_ID`** y solo falta copiarlo. Los otros 13 no traen nota de confirmación (ej. agua purificada, cigarrillos, hielo — varios no-alimentos).

**Dato adicional verificado que hace el relleno casi mecánico:** los 154 `sugerencia_ID` existen todos en la tabla INCAP y **los 154 tienen valor EDIBLE** en INCAP → se puede rellenar también la hoja "Cuest. B Sec 3A" de `food_factors.xlsx` (PC) desde ahí. OJO: rellenar solo el crosswalk NO los hace entrar al cálculo — **también necesitan fila de PC en food_factors** (el PC es el filtro previo).

**Cómo regenerar la lista priorizada (los 154, ordenados por frecuencia de registros en el crudo):**
```python
# pandas
import pandas as pd
cw = pd.read_excel("data/raw/crosswalk_tablas_composicion.xlsx", sheet_name="Cuest. B Sec 3A")
v = cw[(cw["validado"] == True) & cw["enhance_id"].isna()
       & cw["notas"].astype(str).str.contains("Confirmado", na=False)]
v = v.sort_values("freq_registros", ascending=False)
# columnas clave: id_variedad, descripcion_engih, sugerencia_ID, sugerencia_nombre, freq_registros
```

**Top 20 (id_variedad | descripcion | sugerencia_ID | freq registros):** 608 Jugo envasado de manzana 70217143 (483) · 287 Huevos criollos (gallina) 70202002 (396) · 532 Pimienta en polvo 70222019 (330) · 312 Mango 70212080 (327) · 9 Pan integral 70214039 (319) · 97 Carne molida de res 70205070 (306) · 3992 Manzana roja 70212190 (278) · 171 Jamón picnic 70207014 (278) · 2473 Azafrán 70222004 (259) · 21 Galletas integrales 70214103 (255) · 80 Trigo 70213038 (227) · 398 Remolacha 70211146 (226 ⚠ ver abajo) · 117 Carne de gallina 70203003 (219) · 214 Tilapia 70208056 (218) · 316 Cereza 70212054 (197) · 4915 Atún en trozo en aceite 70208019 (182) · 297 Aceite de oliva 70216007 (150) · 131 Chuleta de cerdo fresca 70204044 (145) · 277 Yogurt bebible natural 70201040 (142 ⚠ ver abajo) · 57 Maicena/Maicera 70213044 (141).

**Revisar antes de copiar en masa (sugerencias sospechosas detectadas):** id_variedad 398 "Remolacha" → sugerido "Remolacha, **hojas crudas**" (raíz vs hoja: PC y perfil distintos); id_variedad 277 "Yogurt bebible natural" → sugerido "Yogurt, leche **descremada**" (entero vs descremado). Regla: revisar la lista completa (~30-45 min) y marcar/escalar las dudosas, no copiar ciegas.

### P5 — Creencias desactualizadas o falsas en la documentación (corrigen el diagnóstico, no los datos)

1. **"No tenemos las variables de diseño muestral"** (advertencia en `03_transform.R`, repetida en HOJA_DE_RUTA) — **FALSO hoy**: `data/raw/Sociodemograficas_e_ingresos.xlsx`, hoja "Base", ya contiene `ESTRATO` (8 estratos: 4 regiones × urbano/rural), `UPM` (933), `FACTOR_EXPANSION`, `TRIMESTRE`, provincia/municipio/distrito, y `DES_ESTRATO`/`GRUPO_REGION`. La suma de factores de expansión por hogar = 3,214,540 (consistente con ~3.2M hogares RD 2018). `svydesign(strata=ESTRATO, ids=UPM, weights=FACTOR_EXPANSION)` es implementable YA — verificado: para la cobertura del arroz da IC 28.9–31.1% (vs 29.0–31.0% con `ids=1`), o sea el punto no cambia pero el método queda defendible sin descargo.
2. **"Módulo demográfico de ENGIH aún sin descargar"** (HOJA_DE_RUTA, Fase 2, prerrequisito de AFE) — ya está descargado: es el MISMO archivo sociodemográfico que ya usa `04_equivalente_adulto.R`. Lo que de verdad falta para AFE de embarazadas/lactantes es la variable embarazo/lactancia, que la ENGIH no pregunta (limitación real, bien documentada).
3. **"254,905 registros con gramos-por-EMA" (hito 08-09)** — correcto para su fecha, pero desactualizado: con los pesos-por-unidad añadidos (y P1/P2 corregidos) la cifra actual es **289,249**. Lección: fechar toda cifra del log.
4. **`data_raw_unidades_ACTUALIZADO.xlsx`** — referenciado en HOJA_DE_RUTA como "archivo actualizado que reemplaza a data_raw_unidades.xlsx": **no existe en el repo**; el contenido reconstruido vive directamente en `data_raw_unidades.xlsx`. Documentar para no confundir.
5. **`notas_estrategicas_personales.md`** — referenciado en un comentario de `01_import.R`: **no existe en el repo** (¿archivo local sin versionar?).
6. **README desactualizado** ("Fase activa: Fase 0", "última actualización 05-09") mientras la hoja de ruta registra avance hasta el 09-09.
7. **Git: 1 solo commit en toda la historia.** El principio 6 (conservar originales "o historial de git") no tiene respaldo real. Corregir hacia adelante con commits atómicos.
8. **Sec 2 FC específica "16,866"** — cifra correcta del 05-09 pero con fecha: hoy, con P2 corregido, es 21,108.

### P6 — "Docena" (código 52) se usa como factor universal de CONTEO, no de masa

`diccionario_conversion` define Docena → FC=12 y tiene prioridad sobre la tabla específica. Para cualquier alimento, una docena da "12", no gramos (necesitaría 12 × peso-unidad). Hoy afecta 217 filas de Sec 3A (Chinola 108, Limón agrio 28, Naranja/china 22, Cangrejo de mar 12, Mango 10, Jaiba 8, Guineo verde 7, Tilapia 6...) y 1 de Sec 2 — 0.06% de filas, impacto menor pero sistemático (~40× de subestimación en esos ítems). Decisión pendiente: mover Docena a "Alimento-específico" o crear FC por alimento (12 × peso por unidad). NOTA: huevo por docena NO está afectado porque esas filas no usan el código 52.

### P7 — Sopita Concentrada: el alimento con más registros del crudo está fuera del cálculo (18,087 filas)

"Caldo de pollo (Sopita Concentrada)" (id_variedad 569) es la **mayor exclusión individual** del cálculo: tiene FC resuelto (cubito = 11 g, mediana del crudo, N=15,938) pero **sin PC ni enhance_id**. Es además el foco de sodio del proyecto, con trabajo de campo propio ya hecho (etiqueta verificada: 1 cubito = 10 g → 2,320 mg sodio, 30 kcal; fotos en `media/fotos_investigacion_mercado/`).

**ADVERTENCIA CRÍTICA al mapearla:** en el `food_composition_FNDDS.xlsx` de este repo SOLO existen entradas de caldo LÍQUIDO (28340110 "Chicken or turkey broth…" = 6 kcal/100g, 371 mg sodio/100g; 28310110 beef; 75657000 vegetable). Mapear la sopita a alguna de ellas reincidiría en el error "62×" que el proyecto ya detectó y documentó (el cubito concentrado tiene ~23,200 mg sodio/100g, no ~370). Opciones: (a) crear una entrada propia del proyecto (el repo ya usa el prefijo 99 = corrección propia para IDs no oficiales), con sodio/energía de la etiqueta verificada y el resto del perfil de un análogo deshidratado citado; (b) obtener la fila de una TCA con caldo deshidratado. Requiere aprobación de Daniel/Carlos (la aprobación de la sopita ya estaba anotada como pendiente en HOJA_DE_RUTA).

### P8 — Fragilidades estructurales (proceso, no datos)

1. **Join por texto en Sec 3A**: la unión FC-específico es por `descripcion` — cualquier tilde/mayúscula distinta entre el Excel y el crudo rompe el match **sin avisar**. Hoy no hay colisiones, pero es frágil. Migrar a `id_variedad` sigue pendiente (backlog ya anotado).
2. **Excel como fuente de verdad**: los errores de tipeo en Excel ya causaron 2 bugs (columnas corridas el 09-08; claves duplicadas el 08/09-09). Sin checks automáticos, cada fila nueva es un riesgo. Recomendación mínima: los checks de integridad de claves de P1/P2 en el pipeline, y nota en celda para toda edición.
3. **Reproducibilidad**: sin `renv` (lockfile), `dlookr` (usado en 02) tiene historial de salida de CRAN, y no hay registro de versión de R. `sessionInfo` solo se guarda para 02.
4. **Outliers con `enhance_id` NA**: `group_by(enhance_id)` agrupa TODOS los NA juntos, de modo que la detección de outliers (5×P99.5) mezcla alimentos no relacionados para las filas sin crosswalk — en Sec 3A son ~42,000 filas con enhance_id ausente. Además, para Sec 3A la mayoría de alimentos aún no tiene `enhance_id` validado (253/769), así que la defensa está debilitada (riesgo ya anotado en HOJA_DE_RUTA; se cierra al avanzar el crosswalk).
5. **Proyecto unipersonal + sesiones con IA**: riesgo documentado de "perder la estrategia" entre sesiones (la propia HOJA_DE_RUTA lo dice). La señal de alarma acordada 2026-09-09 sigue vigente: si una sesión propone "seguir afinando datos" en vez de avanzar 05/06, corregir rumbo.

---

## 3. Cobertura real del cálculo (la cifra que debe acompañar TODO resultado)

Estado con P1+P2 corregidos (los % sobre main sin corregir son levemente distintos por el fan-out):

- **Sec 2: 43,404 de 47,837 filas entran al cálculo (90.7%)** — excluidas: 4,413 sin FC, 4,371 con FC pero sin PC, ~20 menores.
- **Sec 3A: 245,898 de 342,046 filas (71.9%)** — excluidas: 48,683 sin FC, 47,465 con FC pero sin PC, ~1,100 menores.

**Top exclusiones por alimento (prioridad de relleno, filas Sec2+Sec3A):** Sopita Concentrada 18,087 · Agua purificada 7,775 (no-alimento — decidir exclusión explícita) · Plátano verde 7,690+1,836 · Guineo verde 5,577+1,513 · Aguacate 2,417 · Tomate Barceló/Bugalú 1,982 · Plátano maduro 1,815 · Sazón líquido 1,756 · Ají gustoso/cachucha 1,616 · Apio 1,449 · Naranja agria 1,394 · Guineo maduro 1,313 · Berenjena 1,068 · Margarina 1,013 · Tomates de ensalada 946 · Limón agrio 920 · Cilantro 887 · Tayota 815.

Los pesos-por-unidad ya medidos en campo según HOJA_DE_RUTA pero aún no cargados: **Cilantro (220 g/bolsa), Plátano verde, Guineo verde** — cargarlos con la misma mecánica de unidad=1 (verificando clave no duplicada, ver P1) ataca directamente el 2º, 3º y 4º hueco.

---

## 4. Números de referencia post-corrección (regression checks para validar los fixes)

Tras corregir P1+P2 (y sin ningún otro cambio), una corrida de 01→04 debe producir:

| Métrica | Valor esperado |
|---|---|
| Sec 2 filas tras joins | 47,837 (sin fan-out) |
| Sec 3A filas tras joins | **342,046** (sin fan-out) |
| Sec 2 FC: universal / específica / sin FC | 22,316 / 21,108 / 4,413 |
| Sec 3A FC: universal / específica / sin FC | 107,095 / 186,268 / 48,683 |
| Filas que entran al cálculo | Sec 2: 43,404 (90.7%) · Sec 3A: 245,898 (71.9%) |
| Outliers marcados | Sec 2: 11 · Sec 3A: 42 |
| Hogares con EMA | 8,892 (mediana 3.04), 0 personas sin EMA |
| Registros válidos gramos-por-EMA (sin outliers) | 289,249 |
| Ingesta aparente de energía (mixto actual, escenario c) | mediana 2,102 kcal/EMA/hogar · media ponderada 2,649 |
| Top contribuyente de hierro y folato | ARROZ / Arroz selecto / habichuelas / pastas / pan (los vehículos fortificables dominan — terreno directo de la pregunta de Santiago) |
| Escenarios (mediana hogar por EMA) | ver tabla en P3 |

La mediana de energía (2,102 kcal/EMA) pasa el sanity check de orden de magnitud frente a hojas de balance FAO — el pipeline completo produce números plausibles.

---

## 5. Decisiones que corresponden al EQUIPO HUMANO (no automatizar)

1. **Línea base de fortificación** (P3): aprobar escenario (b) "norma RD 2018" como baseline; decidir supuestos de pan/pastas/galletas; verificar el supuesto "Arroz selecto enriquecido en 2018".
2. **Aprobación final de la Sopita Concentrada** (P7) y de cualquier entrada nueva con prefijo 99.
3. **Los 21 alimentos sin match** en INCAP ni FNDDS (Sazón líquido 1,756 registros es el mayor, Compota, Malagueta, Queso de hoja, Extracto de malta...) — preguntar a Daniel por fuente conocida (ya anotado en HOJA_DE_RUTA).
4. Método de corrección de outliers (hoy solo se marcan) y tratamiento de "Docena" (P6).
5. Si cubrir los 16 códigos VARIEDAD de Sec 2 fuera del crosswalk de 30 (0.13% de filas).

---

## 6. Estrategia recomendada: avanzar y volver a llenar (formalización del acuerdo 2026-09-09)

**Principio:** nada se perfecciona antes de avanzar, pero nada se avanza sin medir lo que se deja atrás.

- **Regla de avance:** un dato faltante nunca bloquea el pipeline; entra al backlog con su impacto medido en filas (la lista de §3 ya es esa priorización).
- **Regla de retorno:** se rellena por impacto medido, no por orden de lista.
- **Regla de honestidad:** todo resultado se publica con su % de cobertura y top exclusiones.
- **Regla de congelamiento:** cada oleada termina con commit(s) atómicos + entrada fechada en HOJA_DE_RUTA + README actualizado.

**Oleadas sugeridas:**
1. **Cerrar 05 y validar (~2-3 días):** corregir P1/P2; correr 01→05 completo; decidir línea base (P3) con Daniel/Carlos; rellenar los 154 (P4) revisando las ~2 sospechosas; cargar Cilantro/Plátano/Guineo; Sopita (P7); `renv::init()`.
2. **Diseño muestral + equidad + reporte v1 (~3-4 días):** `svydesign(ESTRATO, UPM, FACTOR_EXPANSION)` (ya disponible, P5.1); resultados por región/urbano-rural/quintil; `06_report.qmd` con contenido real (4 nutrientes × 3 escenarios, nunca el mixto como baseline).
3. **Ampliar nutrientes + backfill de PC (~1 semana):** de 4 a 10-15 nutrientes (verificando unidades INCAP vs FNDDS por nutriente, como se hizo con folato); ampliar `food_factors` priorizando por §3; disponibilidad neta Sec2+Sec3A para almacenables.
4. **Dashboard y artículo** (molde: Tang et al. 2021; los métodos ya están casi escritos por la documentación acumulada).

---

## 7. Fuentes externas citadas en este documento

- Informe Encuesta Nacional de Micronutrientes 2009, República Dominicana (MSP/CESDEM; repositorio MSP) — estado del programa de fortificación: harina de trigo de panificación, azúcar con vitamina A (NORDOM 606, 5–25 mg/kg), sal yodada; "solo la harina de trigo usada en panificación está fortificada".
- FFI (Food Fortification Initiative), informe final del estudio sobre fortificación de harina en RD — legislación obligatoria de harina de trigo desde 2009 (Fe/folato/complejo B); fortificación de pastas/galletas voluntaria.
- FAO/WHO/UNU 2004, *Human energy requirements* — base del EMA (ya verificada en el proyecto).

---

*Documento generado por auditoría externa independiente (réplica Python del pipeline completo + inspección directa de los Excel y del crudo), 2026-09-10. Existe una implementación de referencia de las correcciones P1/P2 y del 05 completo en la rama `arena/01a08aaa-analisis-engih2018` del remoto (puede consultarse o ignorarse; este documento no depende de ella y describe el estado de `main` @ d84fd4a).*
