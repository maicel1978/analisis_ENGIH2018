# diagnostico_procedencia.R
#
# P3. Residuo del patron provincial: la hipotesis abierta de produccion propia.
#
# La hoja de ruta registraba la hipotesis como "comprobable si la ENGIH
# registra la procedencia de la adquisicion". La registra. El Excel original
# tiene en la Seccion 3A la variable QUIEN_PAGO1, con estas categorias
# (hoja "Diccionario de variables"):
#
#   1  El hogar                                  7  Regalo de ONG
#   2  Produccion propia del hogar                8  Regalo de Inst. Publica
#   3  Retiro del negocio del hogar               9  Transferencia de Inst. Publicas
#   4  Pago en especie                           10  Regalo de empresas
#   5  Regalo de otro hogar en el extranjero     11  Seguro de salud
#   6  Regalo de otro hogar nacional             99  Otra forma
#
# Y tambien el destino de lo adquirido (DESTINO_NEGOCIO, DESTINO_OTRO_HOGAR,
# DESTINO_IGLESIA_ONG) y la participacion del hogar (PORCENTAJE_HOGAR).
#
# 01_import.R lee esas columnas y las descarta en el transmute del paso 6.2, de
# modo que ninguna llega al calculo. Este script NO modifica el pipeline: relee
# el Excel solo para estas columnas y cruza por hogar con la energia ya
# calculada. Las cifras de control no se tocan.
#
# Pregunta: los hogares con mas adquisicion no comprada registran mas energia
# por EMA, y se concentran en las provincias de mayor energia registrada?
#
# Advertencia de lectura: la participacion se mide en MONTO, no en gramos. Es
# un sustituto. Si el resultado es afirmativo, el paso siguiente es arrastrar
# quien_pago1 por el pipeline y medirlo en energia.
#
# Requiere haber corrido 01, 04, 05 y 07.
#
# Uso: source(here::here("scripts", "diagnostico_procedencia.R"))

library(dplyr); library(readr); library(readxl); library(janitor); library(here)
library(srvyr)

leer <- function(...) read_delim(here(...), delim = ";", show_col_types = FALSE,
                                locale = locale(decimal_mark = "."), guess_max = 100000)

REGISTROS_SEC3A <- 342046   # cifra de control de la Seccion 3A
NO_COMPRADO     <- c(2, 3)  # produccion propia y retiro del negocio del hogar
BAJAS <- c("SAMANA", "SAN JOSE DE OCOA", "MARIA TRINIDAD SANCHEZ")

# --- 1. Releer solo las columnas de procedencia -----------------------------
# 33 columnas en la hoja; se conservan 6. La 14 no tiene nombre en el origen.
tipos <- c("text", "text", rep("skip", 10), "numeric", rep("skip", 14),
           "numeric", "skip", "numeric", "skip", "numeric", "skip")
stopifnot(length(tipos) == 33)

proc <- read_excel(here("data", "raw", "Registros_Cuestionario_B.xlsx"),
                   sheet = "Cuest. B Sec 3A", col_types = tipos) |>
  clean_names()

if (nrow(proc) != REGISTROS_SEC3A) {
  stop("La Seccion 3A trae ", nrow(proc), " registros y se esperaban ",
       REGISTROS_SEC3A, ". La lectura por posicion no corresponde: detener.",
       call. = FALSE)
}
stopifnot(all(c("quien_pago1", "destino_negocio", "porcentaje_hogar",
                "monto_total_mensual") %in% names(proc)))

por_hogar <- proc |>
  mutate(id_hogar_unico = paste(vivienda, hogar, sep = "_"),
         monto = coalesce(monto_total_mensual, 0)) |>
  group_by(id_hogar_unico) |>
  summarise(
    monto_total   = sum(monto),
    monto_propio  = sum(monto[quien_pago1 %in% NO_COMPRADO]),
    monto_regalo  = sum(monto[quien_pago1 %in% c(5, 6)]),
    monto_negocio = sum(monto[destino_negocio == 1]),
    reg_no_cien   = sum(porcentaje_hogar != 100, na.rm = TRUE),
    .groups = "drop") |>
  mutate(pct_propio  = if_else(monto_total > 0, 100 * monto_propio  / monto_total, NA_real_),
         pct_regalo  = if_else(monto_total > 0, 100 * monto_regalo  / monto_total, NA_real_),
         pct_negocio = if_else(monto_total > 0, 100 * monto_negocio / monto_total, NA_real_))

# --- 2. Cruce con la energia ya calculada -----------------------------------
hogar <- leer("data", "clean", "data_ema_hogar.csv")
ing   <- leer("data", "clean", "data_ingesta_micronutrientes_hogar.csv") |>
  filter(variante == "Sec 2 + Sec 3A") |>
  select(id_hogar_unico, energia_kcal)

d <- hogar |> inner_join(ing, by = "id_hogar_unico") |>
  inner_join(por_hogar, by = "id_hogar_unico") |>
  mutate(tramo = cut(pct_propio, c(-Inf, 0, 25, 50, Inf),
                     labels = c("Nada", "Hasta 25%", "25 a 50%", "Mas de 50%")))

message("\nHogares cruzados: ", nrow(d), " de ", nrow(hogar), " con EMA.")

dis <- d |> as_survey_design(ids = upm, strata = estrato,
                             weights = factor_expansion, nest = TRUE)

# --- 3. La energia registrada crece con la adquisicion no comprada? ---------
message("\n== Energia registrada por EMA y dia, segun participacion de la ",
        "produccion propia y el retiro del negocio ==")
print(as.data.frame(
  dis |> group_by(tramo) |>
    summarise(hogares = unweighted(n()),
              expandidos = survey_total(1, vartype = NULL),
              energia = survey_median(energia_kcal, vartype = NULL),
              .groups = "drop") |>
    mutate(pct_hogares = round(100 * expandidos / sum(expandidos), 1)) |>
    select(tramo, hogares, pct_hogares, energia)), digits = 4)

message("\nCorrelacion entre la participacion no comprada y la energia, por hogar: ",
        sprintf("%.3f", cor(d$pct_propio, d$energia_kcal, use = "complete.obs")))

# --- 4. Se concentra en las provincias de mayor energia registrada? ---------
prov <- dis |> group_by(des_provincia) |>
  summarise(hogares     = unweighted(n()),
            energia     = survey_median(energia_kcal, vartype = NULL),
            pct_con     = 100 * survey_mean(pct_propio > 0, vartype = NULL, na.rm = TRUE),
            part_propio  = 100 * survey_ratio(monto_propio,  monto_total, vartype = NULL),
            part_regalo  = 100 * survey_ratio(monto_regalo,  monto_total, vartype = NULL),
            part_negocio = 100 * survey_ratio(monto_negocio, monto_total, vartype = NULL),
            .groups = "drop")

riesgo <- leer("data", "clean", "riesgo_inadecuacion.csv") |>
  filter(dominio == "Provincia", hogares == "Todos",
         nutriente == "folato_mcg_dfe", metodo == "Punto de corte") |>
  select(des_provincia = nivel, riesgo = pct_inadecuado)
prov <- inner_join(prov, riesgo, by = "des_provincia")

message("\n== Correlaciones entre provincias (32) ==")
for (v in c("pct_con", "part_propio", "part_regalo", "part_negocio")) {
  message(sprintf("  %-13s con la energia %6.2f   con el riesgo %6.2f", v,
                  cor(prov[[v]], prov$energia), cor(prov[[v]], prov$riesgo)))
}

message("\n== Diez provincias de mayor energia registrada ==")
print(as.data.frame(
  prov |> arrange(desc(energia)) |> slice_head(n = 10) |>
    transmute(des_provincia, hogares, energia = round(energia),
              pct_con = round(pct_con, 1), part_propio = round(part_propio, 1),
              part_regalo = round(part_regalo, 1), riesgo = round(riesgo, 1))))

message("\n== Las tres de menor riesgo frente al resto ==")
print(as.data.frame(
  d |> mutate(zona = if_else(des_provincia %in% BAJAS, "Las tres", "Resto del pais")) |>
    as_survey_design(ids = upm, strata = estrato, weights = factor_expansion, nest = TRUE) |>
    group_by(zona) |>
    summarise(hogares = unweighted(n()),
              pct_con = 100 * survey_mean(pct_propio > 0, vartype = NULL, na.rm = TRUE),
              energia_todos = survey_median(energia_kcal, vartype = NULL),
              .groups = "drop")), digits = 4)

message("\n== Energia por tramo, dentro y fuera de las tres provincias ==")
print(as.data.frame(
  d |> mutate(zona = if_else(des_provincia %in% BAJAS, "Las tres", "Resto del pais")) |>
    as_survey_design(ids = upm, strata = estrato, weights = factor_expansion, nest = TRUE) |>
    group_by(zona, tramo) |>
    summarise(hogares = unweighted(n()),
              energia = survey_median(energia_kcal, vartype = NULL),
              .groups = "drop")), digits = 4)

write_delim(prov, here("data", "clean", "procedencia_por_provincia.csv"), delim = ";")
message("\nSalida en data/clean/procedencia_por_provincia.csv")
message("Lectura: la participacion esta medida en MONTO, no en gramos. Si el ",
        "resultado\nes afirmativo, el paso siguiente es arrastrar quien_pago1 ",
        "por el pipeline\ny medirlo en energia.")
