# Informe de auditoría externa: documentación vs. datos — 2026-09-10

**Qué es esto:** verificación independiente de cada cifra publicada en `README.md`, `HOJA_DE_RUTA_PROYECTO.md`, `VISION_Y_ARQUITECTURA_PROYECTO.md` y los comentarios de los scripts, contra los archivos de datos reales del repo. Método: réplica completa del pipeline 01→05 en Python (`scripts/audit/verificacion_cruzada_pipeline.py`), que reproduce la lógica de R función por función sobre los mismos insumos. Si una cifra de la documentación y una cifra de esta réplica coinciden, la cifra está verificada dos veces por caminos independientes.

**Lectura de 1 minuto:** la documentación es notablemente honesta y precisa — **11 de 13 cifras clave verificadas coinciden exactamente** (incluyendo las desagregadas por nivel de FC y el IC de cobertura del arroz). Pero la auditoría encontró **2 bugs activos que corrompían resultados silenciosamente desde el 2026-09-08** (ya corregidos en esta misma sesión, ver §3), **1 error metodológico conceptual de alto impacto aún sin decidir** (§4: el crosswalk apunta los vehículos de fortificación a entradas que no corresponden a la RD real de 2018 — cambia la conclusión de folato de 23% a ~60% de aparente inadecuación), y **3 datos "faltantes" que en realidad ya están en el repo** (§5: variables de diseño muestral, 154 mapeos confirmados sin copiar, módulo demográfico "sin descargar" que está descargado).

---

## 1. Cifras documentadas vs. verificadas

| Afirmación documentada | Dónde | Verificado | Estado |
|---|---|---|---|
| Crudo Sec 2: 47,837 filas | HOJA_DE_RUTA | 47,837 | ✅ exacto |
| Crudo Sec 3A: 342,046 filas | HOJA_DE_RUTA | 342,046 | ✅ exacto |
| Sec 2 FC universal 22,316 / específica 16,866 / sin FC 8,655 (run 05-09) | HOJA_DE_RUTA | 22,316 / 16,866 / 8,655 | ✅ exacto (las tres) |
| Sec 3A FC universal 107,095 (run 05-09) | HOJA_DE_RUTA | 107,095 | ✅ exacto |
| Crosswalk Sec 3A: 420/769 validadas (55%) | HOJA_DE_RUTA | 420/769 | ✅ exacto |
| `food_factors` cubre 144 de 770 alimentos | HOJA_DE_RUTA | 144 | ✅ exacto |
| 8,892/8,892 hogares con EMA, mediana 3.04 | HOJA_DE_RUTA | 8,892, mediana 3.04 | ✅ exacto |
| Sec 2: 11 filas outlier (hito 08-09) | HOJA_DE_RUTA | 11 | ✅ exacto |
| Cobertura arroz 70213002: 30.0% (IC 28.9–31.1) | 03_transform.R | 30.0% (IC diseño completo 28.9–31.1) | ✅ exacto |
| Codificación rota Sec 3A: 0 filas | HOJA_DE_RUTA | 0 filas con "Ã" | ✅ exacto |
| 254,905 registros con gramos-por-EMA (hito 08-09) | HOJA_DE_RUTA | 289,249 en estado actual* | ⚠️ no contradictorio* |
| Sec 3A: 155,770 filas vía FC específica (run 05-09) | HOJA_DE_RUTA | 203,966 al 10-09 | ⚠️ ver H1 y §2 |

\* El 254,905 es del 08-09, **antes** de añadir los pesos-por-unidad (huevos 53 g, pan 50 g, cebolla 148 g, ajo 3 g, ají 288 g). Con ellos, la cobertura creció: hoy son 289,249 filas válidas. El número documentado era correcto para su fecha; simplemente ya no es el actual. **Lección para el log: fechar toda cifra.**

**Verificaciones estructurales adicionales (no estaban documentadas, se verificaron para 05):** los 1,466 `ENHANCE_ID` de INCAP y los 7,083 códigos FNDDS **no colisionan** (unión segura); todas las tablas de join (crosswalk, food_factors) están **sin claves duplicadas** tras la corrección de §3; ningún `enhance_id` validado apunta a un ID inexistente en su tabla de fuente (0 huérfanos); el 100% de los 144 alimentos con PC tienen crosswalk validado.

---

## 2. Hallazgos nuevos (ordenados por impacto)

### H1 — BUG ACTIVO (corregido 2026-09-10): fan-out de 17,698 filas en Sec 3A
Al añadir las filas de peso-por-unidad (08/09-09), dos alimentos quedaron con **clave duplicada** `(descripcion, unidad=1)` en la hoja "Cuest. B Sec 3A" de `data_raw_unidades.xlsx`:
- *Pan sobado*: fila antigua FC=45 g (mediana crudo) **y** fila nueva FC=50 g (UMPIH).
- *Ají grande (cubanela)*: fila antigua FC=90.7 g (mediana crudo, N=5) **y** fila nueva FC=288 g (pesaje de campo propio).

El `left_join()` de `01_import.R` duplicaba **cada registro del crudo** de esos dos alimentos comprados "por unidad": 9,131 filas de pan sobado y 8,567 de ají → **17,698 filas espurias** (Sec 3A pasaba de 342,046 a 359,744 filas) y **doble conteo** de su consumo en todo lo aguas abajo (03, 04, gramos por EMA). Los números del "run 05-09" (155,770 específica) no estaban corruptos; sí lo habría estado **cualquier corrida posterior al 08-09** — no hay evidencia de que se haya corrido completo desde entonces, por lo que probablemente ningún resultado publicado llegó a contaminarse.

**Corrección aplicada:** se retiró el FC de las dos filas antiguas (valor original conservado en la columna `nota`, principio 6 del proyecto); las filas de peso-por-unidad (decisión más reciente, con fuente) quedan como vigentes. Verificado post-fix: 0 claves duplicadas, Sec 3A = 342,046 filas exactas.

### H2 — BUG ACTIVO (corregido 2026-09-10): las 3 filas de peso-por-unidad de Sec 2 eran inertes
Las filas HUEVOS=53 g, PANES=50 g, GALLETAS SALADAS=3 g se añadieron el 08-09 **sin la columna `variedad`** (la clave del join de Sec 2). Nunca se aplicaban: los 2,732 registros de HUEVOS de Sec 2 quedaban 0% resueltos (lo mismo PANES y GALLETAS). La afirmación de la hoja de ruta —"ya funciona con la lógica existente del pipeline sin tocar código"— era **falsa para Sec 2** (para Sec 3A sí funcionaba, por unirse por `descripcion`).

**Corrección aplicada:** `variedad` llenada (15/1/3, tomado de las propias filas del mismo alimento en la tabla) + frecuencia real calculada del crudo. Impacto: Sec 2 sin FC baja de 8,655 → **4,413 filas** (4,242 filas recuperadas).

**Prevención:** `01_import.R` ahora tiene `verificar_claves_join()`, que **detiene la corrida** si cualquier tabla de join tiene claves duplicadas o filas con FC y clave vacía (aplica a las 2 tablas FC, el crosswalk y food_factors). Este tipo de bug ya no puede volver a pasar en silencio.

### H3 — ERROR METODOLÓGICO DE ALTO IMPACTO (PENDIENTE DE DECISIÓN, no corregido): la línea base de fortificación está invertida respecto a la RD real
Verificado contra el programa nacional (Informe ENM 2009, repositorio MSP; FFI, informe RD) y contra las entradas reales de la tabla INCAP:

| Vehículo | Programa real RD ~2018 | Entrada INCAP a la que apunta el crosswalk hoy | Consecuencia |
|---|---|---|---|
| Arroz | **NO fortificado** (sin norma de arroz) | `70213002` "enriquecido" (Fe 4.36, folato 386 mcg/100 g) — para ARROZ, Arroz selecto, Súper-selecto. ("Arroz corriente" sí apunta a la s/enriquecer `70213004`) | **Sobrestima** Fe y folato del alimento #1 de la dieta |
| Harina de trigo | **Fortificación obligatoria desde 2009** (45 mg/kg Fe fumarato ferroso, 1.8 mg/kg ácido fólico) | `70213038` "**s/enriquecer**" (Fe 1.17, folato 26) | **Subestima** Fe y folato |
| Azúcar | **Fortificada con vitamina A** (NORDOM 606: 5–25 mg/kg) | `70215001`/`70215036` "**s/fortificar**" (vit A = 0) | **Subestima** vitamina A |
| Sal | Yodada (NORDOM 14) | `70211110` (no evaluado para los 4 nutrientes actuales) | irrelevante por ahora |

Es decir: el "resultado actual" del pipeline no corresponde a **ningún** escenario real — es un mixto. Cuantificado con la réplica Python (mediana hogar por EMA, ponderado):

| Escenario | Hierro (mg) | %hog <EAR 8.1 | Folato (mcg) | %hog <EAR 320 | Vit A (mcg) | %hog <EAR 500 |
|---|---|---|---|---|---|---|
| (a) sin fortificación | 8.7 | 44.8% | 266 | 60.3% | 163 | 86.9% |
| (b) norma RD 2018 (arroz sin fortificar) | 8.9 | 44.3% | 274 | 59.3% | 326 | **60.3%** |
| (c) crosswalk actual (mixto) | 13.8 | 24.8% | **794** | **23.3%** | 163 | 86.9% |

La diferencia (c) vs (a/b) en folato es **~3 veces la mediana** — no es un matiz, es otra conclusión. La buena noticia: la tabla INCAP ya tiene todas las entradas pareadas (70213002/70213004 arroz; 70213039/70213038 harina; 70215002/70215001 azúcar), así que **los escenarios de Santiago se implementan como una capa de intercambio de `enhance_id` por vehículo**, sin datos nuevos. Esa capa ya está implementada en `05_ingesta_micronutrientes.R` (Paso 6) y en la réplica Python.

**Decisión pendiente del equipo (no se cambió el crosswalk sin aprobación):** (1) confirmar la línea base (b) como "situación 2018"; (2) decidir qué asumen pan/pastas/galletas (en RD la fortificación de harina para pastas/galletas es *voluntaria*, no obligatoria — FFI); (3) verificar si "Arroz selecto/súper" realmente venían enriquecidos en el mercado dominicano de 2018 (el crosswalk actual lo asume; "corriente" no).

### H4 — 154 mapeos "confirmados" nunca copiados a `enhance_id` (9,172 registros del crudo)
En el crosswalk Sec 3A hay 154 filas con `validado=TRUE`, nota que dice *"Confirmado: sugerencia automática revisada contra INCAP y es correcta"* — y **`enhance_id` vacío**. El trabajo de validación está hecho; falta copiar el valor (está en `sugerencia_ID`). Incluye alimentos frecuentes: Huevos criollos (396 registros), Jugo envasado de manzana (483), Pimienta en polvo (330), Mango (327), Pan integral (319), Carne molida de res (306)...

**Archivo de trabajo generado:** `data/eda/pendiente_llenar_enhance_id_confirmados.csv` (154 filas, ordenadas por frecuencia, con flags en las ~2 sugerencias que conviene revisar antes de copiar — p.ej. "Remolacha → hojas crudas", "Yogurt natural → descremado"). **No copiar ciegamente:** revisar la lista (30–45 min) y llenar.

### H5 — Datos "faltantes" que ya están en el repo
1. **Variables de diseño muestral.** `03_transform.R` documenta: *"No tenemos el Cuestionario… las variables de diseño muestral… solo promedios ponderados correctos, NO errores estándar con diseño completo"*. **Falso hoy:** `Sociodemograficas_e_ingresos.xlsx` (hoja "Base") contiene `ESTRATO` (8 estratos: 4 regiones × urbano/rural), `UPM` (933 unidades primarias), `FACTOR_EXPANSION`, `TRIMESTRE`, provincia/municipio/distrito. Verificado: `svydesign(strata=ESTRATO, ids=UPM, weights=FACTOR_EXPANSION)` es implementable ya — y para el ejemplo del arroz da IC 28.9–31.1% (prácticamente igual al `ids=1` actual, pero metodológicamente defendible y publicado sin el descargo).
2. **Módulo demográfico "aún sin descargar"** (HOJA_DE_RUTA, Fase 2, para AFE). Ya está: mismo archivo, 28,394 personas en 8,892 hogares con sexo (`A402`) y edad (`A403`) — es el que ya usa `04_equivalente_adulto.R` para el EMA. Lo que sí falta para AFE de embarazadas/lactantes es la *variable* embarazo/lactancia, que la ENGIH no pregunta (limitación real, bien documentada en 04).
3. **Región/urbano-rural para equidad** (Fase 2): `DES_ESTRATO`/`GRUPO_REGION`/`ID_PROVINCIA` ya disponibles — el análisis por quintil/región/zona no está bloqueado por datos.

### H6 — "Docena" (código 52) se usa como FC universal de conteo, no de masa
`diccionario_conversion` define Docena → FC=12. Para huevos vendidos por docena eso da *cantidad de unidades*, no gramos (necesitaría ×53 g). Hoy afecta 217 filas de Sec 3A (Chinola 108, Limón 28, Naranja 22, Cangrejo 12...) y 1 de Sec 2 — impacto pequeño (0.06% de filas) pero sistemático: **subestima** esos alimentos ~40×. Decisión pendiente menor: mover Docena a "Alimento-específico" o añadir FC por alimento (12 × peso unidad).

### H7 — Sopita Concentrada: el alimento con más registros del crudo está excluido del cálculo
18,087 filas (la mayor exclusión individual). Tiene FC resuelto (cubito = 11 g, mediana del crudo) pero **sin PC ni enhance_id** — no entra al cálculo de nutrientes. Es además el producto con trabajo de campo propio (etiqueta verificada: 10 g/cubito, 2,320 mg sodio) y el foco de sodio del proyecto. Quick win de Fase 1: PC=1.0 + entrada FNDDS de caldo concentrado (y el perfil de sodio ya medido).

### H8 — Documentación huérfana / desactualizada (higiene del proyecto vivo)
- `README.md` "Última actualización: 05-09" mientras la hoja de ruta registra trabajo hasta el 09-09 (el README manda: actualizar siempre — hecho en esta sesión).
- `01_import.R` referencia `notas_estrategicas_personales.md` — **no existe** en el repo (¿archivo local no versionado? Si existe localmente, subirlo o quitar la referencia).
- `HOJA_DE_RUTA` referencia `data_raw_unidades_ACTUALIZADO.xlsx` como "archivo actualizado… reemplaza a data_raw_unidades.xlsx" — **no existe**; el contenido reconstruido vive en `data_raw_unidades.xlsx` (presumiblemente renombrado in situ). Documentar para no confundir a una sesión futura.
- Git: **1 solo commit** en toda la historia del repo. El principio 6 del proyecto ("conservar el valor original… o historial de git") no tiene historial que lo respalde. No es recuperable lo pasado, pero sí corregible hacia adelante (commits atómicos por cambio de datos/decisión).
- `VISION_Y_ARQUITECTURA` §5 dice que las salidas limpias "no comiteadas a git — regenerables" ✅ consistente con `.gitignore` (`data/clean/`).

### H9 — Riesgo de reproducibilidad (no es dato, es infraestructura)
El pipeline depende de `dlookr` (02_eda.R), paquete que fue removido de CRAN y resubmetido; sin `renv` (lockfile) ni registro de versión de R, una reinstalación puede romper el pipeline. El propio script lo advierte. Mitigación barata: `renv::init()` + commit del lockfile.

---

## 3. Correcciones ya aplicadas en esta sesión (2026-09-10)

| # | Cambio | Archivo | Trazabilidad |
|---|---|---|---|
| 1 | `variedad` + frecuencia llenados en las 3 filas de peso-por-unidad de Sec 2 (HUEVOS 15 / PANES 1 / GALLETAS 3) | `data/raw/data_raw_unidades.xlsx` | valores tomados de las filas del mismo alimento en la misma tabla; nota ya existente documenta fuente del peso |
| 2 | FC retirado en las 2 filas duplicadas de Sec 3A (Pan sobado 45 g; Ají cubanela 90.7 g) | ídem | valor original conservado en `nota` + `validacion = RETIRADO_duplicado_clave_2026-09-10` |
| 3 | `verificar_claves_join()`: 6 checks que detienen el pipeline ante claves duplicadas o filas inertes | `scripts/01_import.R` | ver comentarios en el script |
| 4 | `05_ingesta_micronutrientes.R` completado (joins + ingesta por hogar + cobertura + capa de escenarios) | `scripts/05_ingesta_micronutrientes.R` | números esperados documentados al final para contraste contra la réplica Python |

**Ningún valor nutricional ni FC fue inventado.** Las dos correcciones de datos solo reactivan/retiran filas siguiendo decisiones ya documentadas en la hoja de ruta.

## 4. Avance preliminar de 05 (4 nutrientes, primera corrida de punta a punta del objetivo central)

Réplica Python sobre el estado corregido (los mismos números debe producir el script R al correrse; ver "VERIFICACIÓN CRUZADA" al final de `05_ingesta_micronutrientes.R`):

- **Cobertura del cálculo:** Sec 2 = 90.7% de filas; Sec 3A = 71.9%. Top exclusiones: Sopita (18,087), Agua purificada (7,775 — legítimamente excluida, pero conviene una lista explícita de "no alimentos"), Plátano verde (7,690+1,836), Guineo verde (5,577+1,513), Aguacate (2,417), Tomates (2,928), Sazón líquido (1,756).
- **Energía:** mediana 2,102 kcal/EMA/hogar/día (ponderado 2,649) — orden de magnitud plausible vs. hojas de balance FAO. Sanity check ✅.
- **Hierro:** mediana 8.7–13.8 mg según escenario (ver H3).
- **Folato:** 266–794 mcg según escenario — **la conclusión depende entera de la decisión H3**.
- **Vitamina A:** 163 mcg (86.9% bajo EAR) sin fortificación de azúcar → 326 mcg (60.3%) con ella. El efecto de la fortificación del azúcar es el resultado más claro de política pública hasta ahora.
- Principales contribuyentes de hierro (entre lo cubierto): ARROZ, Arroz selecto, habichuelas, Corn Flakes, pan. De folato: arroz, habichuelas, pastas, pan — es decir, **los vehículos fortificables dominan**: exactamente el terreno de la pregunta de Santiago.

**Advertencias obligatorias al citar (nivel hogar-por-EMA, adquisición no consumo, cobertura 72–91%, EAR ilustrativo).** El paso de "% hogares bajo referencia" a "prevalencia de inadecuación individual" requiere el marco de probabilidad (Fase 2) — no usar tal cual.

## 5. Qué NO se tocó

- El crosswalk no se modificó (H3 y H4 son decisiones del equipo, no ediciones automáticas — principios 4 y 8 del proyecto).
- Los pesos-por-unidad pendientes (Cilantro, Plátano verde, Guineo verde) siguen pendientes — ahora priorizados por impacto real de filas en `data/audit/prioridad_relleno_excluidos.csv`.
- Ningún script corrió en R en esta sesión (el sandbox no tiene R): **el script 05 completado debe correrse en RStudio y contrastarse con los números esperados** antes de darlo por bueno. La réplica Python corrió completa y es la evidencia de que la lógica es correcta contra los datos reales.
