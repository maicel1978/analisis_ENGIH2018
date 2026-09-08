# 04_equivalente_adulto.R
#
# Calcula el Equivalente de Mujer Adulta (EMA) por persona y lo agrega
# por hogar, para poder normalizar la ingesta aparente de micronutrientes
# entre hogares de distinta composición demográfica (Weisell & Dop, 2012).
#
# Formula (documento de Daniel, "Modelo de Base - Equivalente de Mujer
# Adulta (EMA)", agosto 2026, docs/20260903 Modelo de Base - Equivalente
# de Mujer Adulta (EMA).pdf):
#
#   Ingesta_aparente_m = Sum(cantidad_consumida x composicion_micronutrientes) / EMA_hogar
#
#   EMA_hogar = Sum(EMA_i) para cada miembro i del hogar
#   EMA_i = requerimiento_energetico_i / 2291 kcal
#           (2291 kcal = requerimiento de 1 mujer adulta 18-30 anos,
#            55kg, actividad fisica moderada PAL=1.76, no embarazada,
#            no lactando -- FAO/WHO/UNU 2004)
#
# IMPORTANTE: el documento de Daniel CITA las tablas de requerimiento
# energetico por edad/sexo (FAO/WHO/UNU 2004, Tablas 4.2, 4.3, 5.2) pero
# no incluye los numeros. Los valores de este script se sacaron
# directamente de la fuente primaria:
#
#   FAO/WHO/UNU. 2004. Human energy requirements: Report of a Joint
#   FAO/WHO/UNU Expert Consultation. Roma, 17-24 octubre 2001.
#   https://www.fao.org/4/y5686e/y5686e00.htm
#   - Ninos y adolescentes (1-18 anos), actividad fisica MODERADA:
#     Tabla 4.2 (ninos), Tabla 4.3 (ninas), seccion 4.4
#   - Adultos (>=18 anos): ecuaciones de Schofield 1985 para TMB
#     (Tabla 5.2), multiplicadas por PAL=1.76 (actividad moderada,
#     seccion 5.3)
#
# Verificacion propia: BMR mujer 18-30, 55kg (14.818*55+486.6=1301.6
# kcal) x PAL 1.76 = 2290.8 kcal =~ 2291 kcal -- coincide exactamente
# con el valor de referencia del documento de Daniel. La formula esta
# bien aplicada.
#
# LIMITACIONES DOCUMENTADAS (no resueltas en esta version, ver mas abajo):
#   1. El modulo sociodemografico de la ENGIH (Sociodemograficas_e_ingresos.xlsx)
#      NO PREGUNTA embarazo ni lactancia -- confirmado revisando la hoja
#      "Diccionario de variables" completa, no se encontro ninguna variable
#      de este tipo. Este script NO aplica el ajuste de +275 kcal
#      (embarazo) ni +505/460 kcal (lactancia) que menciona el documento
#      de Daniel, porque no hay como identificar a esas mujeres en los
#      datos. Esto subestima levemente el requerimiento de esos hogares.
#   2. Para adultos (>=18 anos) se usa un peso FIJO por sexo (65kg
#      hombres, 55kg mujeres -- las mismas hipotesis del documento de
#      Daniel), no el peso real de cada persona, porque la ENGIH no
#      registra peso individual.
#   3. Infantes menores de 1 ano: la Tabla 4.2/4.3 de FAO/WHO/UNU 2004
#      empieza en 1-2 anos. Para edad=0 se usa un valor provisional
#      (ver mas abajo) que HAY QUE REVISAR con la seccion 3 del mismo
#      informe (requerimientos de lactantes) antes de dar el resultado
#      por bueno para ese grupo de edad.
#
# Todas estas limitaciones se documentan tambien en HOJA_DE_RUTA_PROYECTO.md.


# Configuración general -------------------------------------------------
library(conflicted)
library(readr)
library(dplyr)
library(here)
conflicts_prefer(dplyr::filter)

# Paso 1: Cargar datos sociodemográficos (ya generados en 01_import.R) --
sociodemografia_data <- read_delim(
  here("data", "clean", "data_sociodemografia.csv"),
  delim = ";",
  show_col_types = FALSE
)

# Paso 2: Tabla de requerimiento energético por edad y sexo -------------
# Fuente: FAO/WHO/UNU 2004, Tablas 4.2 (ninos), 4.3 (ninas), actividad
# fisica MODERADA. edad_desde/edad_hasta en anos completos; una persona
# con "edad" completa N cae en la fila donde edad_desde <= N < edad_hasta.
tabla_ninos <- tribble(
  ~edad_desde, ~edad_hasta, ~sexo,       ~kcal_dia,
  1,  2,  "Masculino", 948,
  2,  3,  "Masculino", 1129,
  3,  4,  "Masculino", 1252,
  4,  5,  "Masculino", 1360,
  5,  6,  "Masculino", 1467,
  6,  7,  "Masculino", 1573,
  7,  8,  "Masculino", 1692,
  8,  9,  "Masculino", 1830,
  9,  10, "Masculino", 1978,
  10, 11, "Masculino", 2150,
  11, 12, "Masculino", 2341,
  12, 13, "Masculino", 2548,
  13, 14, "Masculino", 2770,
  14, 15, "Masculino", 2990,
  15, 16, "Masculino", 3178,
  16, 17, "Masculino", 3322,
  17, 18, "Masculino", 3410,
  1,  2,  "Femenino",  865,
  2,  3,  "Femenino",  1047,
  3,  4,  "Femenino",  1156,
  4,  5,  "Femenino",  1241,
  5,  6,  "Femenino",  1330,
  6,  7,  "Femenino",  1428,
  7,  8,  "Femenino",  1554,
  8,  9,  "Femenino",  1698,
  9,  10, "Femenino",  1854,
  10, 11, "Femenino",  2006,
  11, 12, "Femenino",  2149,
  12, 13, "Femenino",  2276,
  13, 14, "Femenino",  2379,
  14, 15, "Femenino",  2449,
  15, 16, "Femenino",  2491,
  16, 17, "Femenino",  2503,
  17, 18, "Femenino",  2503,
)

# Adultos: BMR (Schofield 1985, Tabla 5.2) x PAL 1.76 (moderado).
# Peso fijo por hipotesis del documento de Daniel: 65kg hombres, 55kg
# mujeres. Formulas fuente (kcal/dia): ver comentario de cada fila.
PAL <- 1.76
peso_hombre <- 65
peso_mujer  <- 55

tabla_adultos <- tribble(
  ~edad_desde, ~edad_hasta, ~sexo,       ~kcal_dia,
  18, 30,  "Masculino", (15.057 * peso_hombre + 692.2) * PAL,  # 2940.8
  30, 60,  "Masculino", (11.472 * peso_hombre + 873.1) * PAL,  # 2849.1
  60, 150, "Masculino", (11.711 * peso_hombre + 587.7) * PAL,  # 2374.1
  18, 30,  "Femenino",  (14.818 * peso_mujer  + 486.6) * PAL,  # 2290.8 (referencia EMA=1)
  30, 60,  "Femenino",  (8.126  * peso_mujer  + 845.6) * PAL,  # 2274.9
  60, 150, "Femenino",  (9.082  * peso_mujer  + 658.5) * PAL,  # 2038.1
)

tabla_requerimiento <- bind_rows(tabla_ninos, tabla_adultos)

# Referencia EMA = 1 mujer adulta 18-30, 55kg, PAL 1.76 (documento de
# Daniel dice 2291 kcal exacto; usamos el valor calculado 2290.8 para
# consistencia interna con la tabla de arriba -- la diferencia es
# redondeo, no una discrepancia real).
REFERENCIA_EMA_KCAL <- tabla_adultos |>
  filter(sexo == "Femenino", edad_desde == 18) |>
  pull(kcal_dia)

# Placeholder para menores de 1 año -- PENDIENTE DE REVISAR (ver
# limitacion 3 arriba). Valor aproximado de literatura general para
# lactantes, NO verificado contra la seccion 3 de FAO/WHO/UNU 2004.
KCAL_MENOR_1_ANO_PROVISIONAL <- 600

# Paso 3: Asignar requerimiento energético a cada persona ----------------
sociodemografia_data <- sociodemografia_data |>
  mutate(
    sexo_texto = case_when(
      sexo == 1 ~ "Masculino",
      sexo == 2 ~ "Femenino",
      TRUE ~ NA_character_
    )
  )

asignar_kcal <- function(edad, sexo_texto) {
  if (is.na(edad) || is.na(sexo_texto)) return(NA_real_)
  if (edad < 1) return(KCAL_MENOR_1_ANO_PROVISIONAL)
  fila <- tabla_requerimiento |>
    filter(sexo == sexo_texto, edad >= edad_desde, edad < edad_hasta)
  if (nrow(fila) == 0) return(NA_real_)
  fila$kcal_dia[1]
}

sociodemografia_data$kcal_requerido <- mapply(
  asignar_kcal,
  sociodemografia_data$edad,
  sociodemografia_data$sexo_texto
)

sociodemografia_data$EMA_individual <- sociodemografia_data$kcal_requerido / REFERENCIA_EMA_KCAL

# Aviso si hay personas sin poder calcular EMA (edad o sexo faltante/no
# reconocido) -- no se descartan en silencio.
n_sin_ema <- sum(is.na(sociodemografia_data$EMA_individual))
if (n_sin_ema > 0) {
  message("AVISO: ", n_sin_ema, " personas sin EMA calculado (edad o sexo faltante/invalido). Revisar antes de usar el resultado.")
}

# Paso 4: Agregar por hogar ----------------------------------------------
ema_hogar <- sociodemografia_data |>
  group_by(id_hogar_unico) |>
  summarise(
    n_miembros = n(),
    n_sin_ema = sum(is.na(EMA_individual)),
    EMA_hogar = sum(EMA_individual, na.rm = TRUE),
    factor_expansion = first(factor_expansion),
    .groups = "drop"
  )

message(
  "Hogares con EMA calculado: ", sum(ema_hogar$n_sin_ema == 0), " de ", nrow(ema_hogar),
  " (", nrow(ema_hogar) - sum(ema_hogar$n_sin_ema == 0), " hogares con al menos 1 miembro sin EMA)"
)
message(
  "EMA promedio por hogar: ", round(mean(ema_hogar$EMA_hogar, na.rm = TRUE), 2),
  " | mediana: ", round(median(ema_hogar$EMA_hogar, na.rm = TRUE), 2)
)

# Paso 5: Guardar salida --------------------------------------------------
write_delim(sociodemografia_data, here("data", "clean", "data_ema_individual.csv"), delim = ";")
write_delim(ema_hogar, here("data", "clean", "data_ema_hogar.csv"), delim = ";")

# Próximos pasos (NO hechos en este script) ------------------------------
# 1. Revisar KCAL_MENOR_1_ANO_PROVISIONAL contra FAO/WHO/UNU 2004
#    seccion 3 (requerimientos de lactantes) -- ahora mismo es un
#    placeholder, no un valor verificado.
# 2. Cuando 03_transform.R tenga el consumo diario agregado por hogar
#    (Sec 2 + Sec 3A), unir por id_hogar_unico y dividir entre EMA_hogar
#    para obtener la ingesta aparente por EMA (formula completa del
#    documento de Daniel).
# 3. Decidir qué hacer con los hogares que tengan algún miembro sin EMA
#    calculado (n_sin_ema > 0 en data_ema_hogar.csv) -- ahora mismo el
#    EMA_hogar de esos casos está subestimado (solo suma los miembros
#    que sí se pudieron calcular).
