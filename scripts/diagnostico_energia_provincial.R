# diagnostico_energia_provincial.R
#
# Evidencia del hallazgo registrado en docs/hoja-de-ruta.md el 2026-10-10:
# el patron geografico del riesgo de ingesta inadecuada esta gobernado por la
# energia registrada, y no por diferencias en la composicion de la dieta.
#
# No modifica el pipeline: lee data/clean e imprime. Tres bloques:
#
#   1. Con que correlaciona el riesgo provincial: energia, densidad, tamano del
#      hogar. Se repite el contraste con la energia para los seis nutrientes
#      evaluados por punto de corte.
#   2. Mecanismos de procesamiento candidatos: reparto entre la Seccion 2 y la
#      3A, energia excluida por la regla de agotamiento, y dias observados.
#      Ninguno explica el patron.
#   3. Energia por seccion en las tres provincias de menor riesgo frente al
#      resto, que muestra que ambas secciones se inflan por el mismo factor.
#
# Conclusion: la diferencia esta en la adquisicion declarada, no en el
# procesamiento. Como la inflacion es multiplicativa sobre la ingesta total, se
# cancela en la densidad y no en el nivel; de ahi que para comparacion
# geografica se prefiera la densidad de nutrientes a la ingesta absoluta.
#
# Requiere haber corrido 04, 05 y 07.

library(dplyr); library(readr); library(here); library(srvyr)

leer <- function(...) read_delim(here(...), delim = ";", show_col_types = FALSE,
                                 locale = locale(decimal_mark = "."), guess_max = 100000)

# Las tres provincias de menor riesgo de folato en el escenario de linea base.
BAJAS <- c("SAMANA", "SAN JOSE DE OCOA", "MARIA TRINIDAD SANCHEZ")

hogar <- leer("data", "clean", "data_ema_hogar.csv")
ing   <- leer("data", "clean", "data_ingesta_micronutrientes_hogar.csv") |>
  filter(variante == "Sec 2 + Sec 3A")

# --- 1. Que gobierna el patron geografico -----------------------------------
p <- hogar |>
  inner_join(ing |> select(id_hogar_unico, energia_kcal, folato_mcg_dfe),
             by = "id_hogar_unico") |>
  as_survey_design(ids = upm, strata = estrato, weights = factor_expansion, nest = TRUE) |>
  group_by(des_provincia) |>
  summarise(ema      = survey_median(EMA_hogar, vartype = NULL),
            energia  = survey_median(energia_kcal, vartype = NULL),
            folato   = survey_median(folato_mcg_dfe, vartype = NULL),
            .groups = "drop") |>
  mutate(densidad = 1000 * folato / energia)

riesgo <- leer("data", "clean", "riesgo_inadecuacion.csv") |>
  filter(dominio == "Provincia", hogares == "Todos",
         nutriente == "folato_mcg_dfe", metodo == "Punto de corte") |>
  select(des_provincia = nivel, riesgo = pct_inadecuado)

d <- inner_join(p, riesgo, by = "des_provincia")

message("\n== Correlacion con el riesgo de folato, 32 provincias ==")
for (v in c("energia", "densidad", "ema", "folato")) {
  message(sprintf("  %-9s Pearson %6.2f   Spearman %6.2f", v,
                  cor(d[[v]], d$riesgo), cor(d[[v]], d$riesgo, method = "spearman")))
}

message("\n== Correlacion de la energia con el riesgo, por nutriente ==")
leer("data", "clean", "riesgo_inadecuacion.csv") |>
  filter(dominio == "Provincia", hogares == "Todos", metodo == "Punto de corte") |>
  select(des_provincia = nivel, nutriente, pct_inadecuado) |>
  inner_join(p |> select(des_provincia, energia), by = "des_provincia") |>
  group_by(nutriente) |>
  summarise(r = round(cor(energia, pct_inadecuado), 2), .groups = "drop") |>
  arrange(r) |> as.data.frame() |> print()

# --- 2. Mecanismos de procesamiento candidatos ------------------------------
comp <- leer("data", "clean", "composicion_unificada.csv") |> select(enhance_id, energia_kcal)

h <- leer("data", "clean", "data_gramos_por_ema.csv") |>
  left_join(comp, by = "enhance_id") |>
  mutate(e = coalesce(Gramos_por_EMA_dia * energia_kcal / 100, 0)) |>
  group_by(id_hogar_unico) |>
  summarise(e_sec2  = sum(e[seccion == "Sec 2"  & !almacenado]),
            e_sec3a = sum(e[seccion == "Sec 3A" & !almacenado]),
            e_excl  = sum(e[almacenado]), .groups = "drop") |>
  mutate(e_total  = e_sec2 + e_sec3a,
         pct_sec2 = if_else(e_total > 0, 100 * e_sec2 / e_total, NA_real_),
         pct_excl = if_else(e_total + e_excl > 0,
                            100 * e_excl / (e_total + e_excl), NA_real_))

dias <- leer("data", "clean", "data_sec3a_consumo.csv") |>
  distinct(id_hogar_unico, dias_observados_hogar)

mec <- hogar |>
  inner_join(h, by = "id_hogar_unico") |>
  left_join(dias, by = "id_hogar_unico") |>
  as_survey_design(ids = upm, strata = estrato, weights = factor_expansion, nest = TRUE) |>
  group_by(des_provincia) |>
  summarise(energia  = survey_median(e_total, vartype = NULL),
            pct_sec2 = survey_median(pct_sec2, vartype = NULL, na.rm = TRUE),
            pct_excl = survey_median(pct_excl, vartype = NULL, na.rm = TRUE),
            dias     = survey_median(dias_observados_hogar, vartype = NULL, na.rm = TRUE),
            .groups = "drop")

message("\n== Mecanismos de procesamiento: correlacion con la energia provincial ==")
for (v in c("pct_sec2", "pct_excl", "dias")) {
  r <- suppressWarnings(cor(mec[[v]], mec$energia, use = "complete.obs"))
  message(sprintf("  %-9s Pearson %s", v,
                  if (is.na(r)) "sin variacion (constante)" else sprintf("%6.2f", r)))
}

message("\n== Cinco de mayor y cinco de menor energia ==")
print(as.data.frame(mec |> arrange(desc(energia)) |>
  transmute(des_provincia, energia = round(energia), pct_sec2 = round(pct_sec2, 1),
            pct_excl = round(pct_excl, 1), dias = round(dias, 1)) |>
  slice(c(1:5, 28:32))))

# --- 3. Energia por seccion: las tres frente al resto -----------------------
message("\n== Energia por seccion, kcal por EMA y dia ==")
hogar |>
  inner_join(h, by = "id_hogar_unico") |>
  mutate(zona = if_else(des_provincia %in% BAJAS, "Las tres", "Resto del pais")) |>
  as_survey_design(ids = upm, strata = estrato, weights = factor_expansion, nest = TRUE) |>
  group_by(zona) |>
  summarise(sec2  = survey_median(e_sec2,  vartype = NULL),
            sec3a = survey_median(e_sec3a, vartype = NULL),
            total = survey_median(e_total, vartype = NULL), .groups = "drop") |>
  as.data.frame() |> print(digits = 4)
