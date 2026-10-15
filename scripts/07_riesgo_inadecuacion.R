# 07_riesgo_inadecuacion.R
#
# Riesgo de ingesta inadecuada por nutriente y escenario de fortificacion,
# sobre la estimacion principal (Sec 2 + Sec 3A con regla de agotamiento).
#
# Hierro, folato, zinc, B12 y vitamina A se toman de los escenarios de
# 06_escenarios_fortificacion.R, que parten del alimento sin fortificar. Las
# vitaminas D y E no cambian entre escenarios y se toman de 05.
#
#   - Punto de corte: proporcion de hogares con ingesta por EMA bajo el EAR.
#   - Hierro: enfoque de probabilidad, con la distribucion del requerimiento.
#   - Proporcion de hogares sobre el limite superior tolerable (UL). En folato
#     y vitamina A el limite aplica solo a la forma anadida.
#   - Densidad de nutrientes por 1.000 kcal (mediana).
#
# Cada resultado se calcula con todos los hogares y solo con los de energia
# plausible: las colas de la distribucion determinan estas proporciones.
#
# Todos los escenarios se estiman a nivel nacional. La desagregacion por
# region, zona, quintil y provincia se hace para el escenario de linea base. Region y zona son
# dominios de estimacion de la encuesta; la provincia no lo es, y sus
# estimaciones se marcan como de precision baja cuando hay menos de 50 hogares
# o la semiamplitud del intervalo de confianza supera 10 puntos porcentuales.
# En proporciones el coeficiente de variacion penaliza las prevalencias bajas
# aunque sean precisas; se conserva en la salida como referencia.
#
# Los valores de referencia se leen de data/raw/valores_referencia.csv y
# data/raw/hierro_requerimiento.csv. Para cambiar de referencia se sustituyen
# esos archivos; este script no cambia.
#
# Lo que estas cifras no son: prevalencia de deficiencia. La ingesta es
# aparente, a nivel de hogar y por equivalente de mujer adulta; el reparto
# dentro del hogar se supone proporcional al requerimiento energetico.
#
# Requiere haber corrido 04, 05 y 06.

library(dplyr)
library(tidyr)
library(readr)
library(srvyr)
library(here)

leer <- function(...) {
  read_delim(here(...), delim = ";", show_col_types = FALSE,
             locale = locale(decimal_mark = "."), guess_max = 100000)
}

# El requerimiento de hierro tabulado supone 18% de biodisponibilidad. Para
# otra biodisponibilidad el requerimiento dietetico se escala por 0,18 / b.
BIODISPONIBILIDAD_TABLA  <- 0.18
BIODISPONIBILIDAD_HIERRO <- c(0.10, 0.18)

referencia <- leer("data", "raw", "valores_referencia.csv")
req_hierro <- leer("data", "raw", "hierro_requerimiento.csv")

ingesta <- leer("data", "clean", "data_ingesta_micronutrientes_hogar.csv") |>
  filter(variante == "Sec 2 + Sec 3A")
DOMINIOS <- c(Nacional = "nacional", Region = "grupo_region", Zona = "zona",
              Quintil = "quintil", Provincia = "des_provincia")
SEMIAMPLITUD_MAX <- 10   # puntos porcentuales del intervalo de confianza
HOGARES_MIN <- 50

# Linea base de 2018: norma de harina de trigo aplicada a harina y pan. La
# fortificacion de pastas y galletas es voluntaria (escenario 1b, sensibilidad).
ESCENARIO_BASE <- "1a. Norma nacional: harina y pan"

diseno_hogar <- leer("data", "clean", "data_ema_hogar.csv") |>
  mutate(nacional = "Total", quintil = as.character(quintil)) |>
  select(id_hogar_unico, estrato, upm, factor_expansion, all_of(unname(DOMINIOS)))

escenarios <- leer("data", "clean", "escenarios_ingesta_hogar.csv")
if (!ESCENARIO_BASE %in% escenarios$escenario) {
  stop("El escenario de linea base no existe en escenarios_ingesta_hogar.csv.", call. = FALSE)
}

# Nutrientes que no cambian entre escenarios: se repiten en cada uno.
fijos <- setdiff(referencia$nutriente, unique(escenarios$nutriente))
faltan <- setdiff(fijos, names(ingesta))
if (length(faltan) > 0) {
  stop("Nutrientes de la referencia ausentes en la ingesta: ",
       paste(faltan, collapse = ", "), call. = FALSE)
}
sin_escenario <- ingesta |>
  select(id_hogar_unico, all_of(fijos)) |>
  pivot_longer(all_of(fijos), names_to = "nutriente", values_to = "ingesta") |>
  mutate(anadido = 0)

largo <- bind_rows(
  escenarios |> select(escenario, id_hogar_unico, nutriente, anadido, ingesta),
  expand_grid(escenario = unique(escenarios$escenario), sin_escenario)
) |>
  filter(nutriente %in% referencia$nutriente) |>
  inner_join(ingesta |> select(id_hogar_unico, energia_kcal, energia_plausible),
             by = "id_hogar_unico") |>
  left_join(referencia |> select(nutriente, ear, ul, metodo), by = "nutriente") |>
  inner_join(diseno_hogar, by = "id_hogar_unico") |>
  mutate(
    bajo_ear = as.numeric(ingesta < ear),
    # El limite superior del folato aplica al acido folico sintetico (el
    # anadido esta en ug DFE: se divide por 1,7) y el de la vitamina A, al
    # retinol preformado anadido.
    sobre_ul = as.numeric(case_when(
      nutriente == "folato_mcg_dfe"     ~ anadido / 1.7 > ul,
      nutriente == "vitamina_a_mcg_rae" ~ anadido > ul,
      TRUE                              ~ ingesta > ul
    )),
    densidad = if_else(energia_kcal > 0, 1000 * ingesta / energia_kcal, NA_real_)
  )

# Probabilidad de que el requerimiento de hierro supere la ingesta observada.
prob_inadecuacion_hierro <- function(ingesta, biodisponibilidad) {
  req <- req_hierro$requerimiento_mg * BIODISPONIBILIDAD_TABLA / biodisponibilidad
  1 - approx(req, req_hierro$percentil / 100, xout = ingesta,
             yleft = 0, yright = 1)$y
}

resumir <- function(d, variable) {
  d |>
    summarise(
      n                = unweighted(n()),
      inadecuado       = survey_mean({{ variable }}, vartype = c("ci", "cv")),
      pct_sobre_ul     = 100 * survey_mean(sobre_ul, vartype = NULL, na.rm = TRUE),
      densidad_mediana = survey_median(densidad, vartype = NULL, na.rm = TRUE),
      .groups = "drop"
    )
}

estimar <- function(df, hogares, dominio) {
  d <- df |>
    mutate(nivel = .data[[DOMINIOS[[dominio]]]]) |>
    as_survey_design(ids = upm, strata = estrato,
                     weights = factor_expansion, nest = TRUE)

  corte <- d |>
    filter(metodo == "punto_de_corte") |>
    group_by(escenario, nivel, nutriente) |>
    resumir(bajo_ear) |>
    mutate(metodo = "Punto de corte")

  hierro <- lapply(BIODISPONIBILIDAD_HIERRO, function(b) {
    d |>
      filter(nutriente == "hierro_mg") |>
      mutate(prob = prob_inadecuacion_hierro(ingesta, b)) |>
      group_by(escenario, nivel, nutriente) |>
      resumir(prob) |>
      mutate(metodo = paste0("Probabilidad, biodisponibilidad ", 100 * b, "%"))
  }) |> bind_rows()

  bind_rows(corte, hierro) |>
    mutate(hogares = hogares, dominio = dominio, .before = 1)
}

combinaciones <- expand.grid(dominio = names(DOMINIOS),
                             hogares = c("Todos", "Energia plausible"),
                             stringsAsFactors = FALSE)

riesgo <- lapply(seq_len(nrow(combinaciones)), function(k) {
  df <- if (combinaciones$hogares[k] == "Todos") largo else largo |> filter(energia_plausible)
  if (combinaciones$dominio[k] != "Nacional") df <- df |> filter(escenario == ESCENARIO_BASE)
  estimar(df, combinaciones$hogares[k], combinaciones$dominio[k])
}) |>
  bind_rows() |>
  left_join(referencia |> select(nutriente, ear, ul, unidad, estado), by = "nutriente") |>
  transmute(
    escenario, dominio, nivel, hogares, nutriente, metodo, n, ear, ul, unidad,
    pct_inadecuado     = 100 * inadecuado,
    pct_inadecuado_low = 100 * inadecuado_low,
    pct_inadecuado_upp = 100 * inadecuado_upp,
    cv                 = inadecuado_cv,
    semiamplitud_ic    = (pct_inadecuado_upp - pct_inadecuado_low) / 2,
    precision_baja     = n < HOGARES_MIN | semiamplitud_ic > SEMIAMPLITUD_MAX,
    pct_sobre_ul       = if_else(is.na(ul), NA_real_, pct_sobre_ul),
    densidad_mediana, estado
  ) |>
  arrange(match(dominio, names(DOMINIOS)), nivel, nutriente, metodo, escenario, hogares)

nacional <- riesgo |> filter(dominio == "Nacional", hogares == "Todos")

message("Hogares bajo el requerimiento (%), total nacional, por escenario (ponderado; ",
        "valores de referencia: ", paste(unique(referencia$estado), collapse = ", "), "):")
print(as.data.frame(
  nacional |>
    mutate(nutriente = if_else(metodo == "Punto de corte", nutriente,
                               paste0("hierro_", sub(".* ", "", metodo)))) |>
    select(escenario, nutriente, pct_inadecuado) |>
    pivot_wider(names_from = nutriente, values_from = pct_inadecuado)
), digits = 3)

message("\nHogares sobre el limite superior (%), por escenario:")
print(as.data.frame(
  nacional |> filter(!is.na(ul), metodo != "Probabilidad, biodisponibilidad 18%") |>
    select(escenario, nutriente, pct_sobre_ul) |>
    pivot_wider(names_from = nutriente, values_from = pct_sobre_ul)
), digits = 3)

message("\nSensibilidad: mismo calculo solo con hogares de energia plausible, linea base:")
print(as.data.frame(
  riesgo |> filter(dominio == "Nacional", escenario == ESCENARIO_BASE) |>
    select(nutriente, metodo, hogares, pct_inadecuado) |>
    pivot_wider(names_from = hogares, values_from = pct_inadecuado)
), digits = 3)

message("\nPrecision por dominio (linea base, todos los hogares):")
print(as.data.frame(
  riesgo |> filter(hogares == "Todos", escenario == ESCENARIO_BASE) |>
    group_by(dominio) |>
    summarise(niveles = n_distinct(nivel), celdas = n(),
              precision_baja = sum(precision_baja),
              hogares_min = min(n),
              semiamplitud_max = round(max(semiamplitud_ic, na.rm = TRUE), 1))
))

# --- Diferencias entre escenarios, pareadas por hogar ------------------------
# Un cambio expresado en puntos porcentuales sin intervalo no es citable. Y el
# intervalo NO se obtiene restando los extremos de los dos intervalos
# marginales: los dos escenarios se estiman sobre LOS MISMOS hogares, de modo
# que la comparacion es pareada y su varianza es menor que la de la diferencia
# de dos estimaciones independientes.
#
# El procedimiento: se construye por hogar la diferencia entre el indicador de
# un escenario y el del otro, y se estima la media de esa diferencia con el
# diseno completo. Es la contrapartida, para un diseno complejo, de la prueba
# para proporciones pareadas.
#
# Se calculan todos los pares ordenados. Cada documento toma el que necesita y
# declara contra que compara.
ind <- bind_rows(
  largo |>
    filter(metodo == "punto_de_corte") |>
    transmute(id_hogar_unico, escenario, nutriente, valor = bajo_ear,
              metodo = "Punto de corte"),
  lapply(BIODISPONIBILIDAD_HIERRO, function(b) {
    largo |>
      filter(nutriente == "hierro_mg") |>
      transmute(id_hogar_unico, escenario, nutriente,
                valor = prob_inadecuacion_hierro(ingesta, b),
                metodo = paste0("Probabilidad, biodisponibilidad ", 100 * b, "%"))
  }) |> bind_rows()
)

escenarios_todos <- sort(unique(ind$escenario))
pares <- expand.grid(desde = escenarios_todos, hasta = escenarios_todos,
                     stringsAsFactors = FALSE) |>
  filter(desde != hasta)

diferencias <- lapply(split(ind, list(ind$nutriente, ind$metodo), drop = TRUE),
                      function(z) {
  ancho <- z |>
    select(id_hogar_unico, escenario, valor) |>
    pivot_wider(names_from = escenario, values_from = valor) |>
    inner_join(diseno_hogar, by = "id_hogar_unico")

  disponibles <- intersect(escenarios_todos, names(ancho))
  d_w <- ancho |>
    as_survey_design(ids = upm, strata = estrato, weights = factor_expansion,
                     nest = TRUE)

  pp <- pares |> filter(desde %in% disponibles, hasta %in% disponibles)

  lapply(seq_len(nrow(pp)), function(k) {
    a <- pp$desde[k]; b <- pp$hasta[k]
    d_w |>
      mutate(d_par = !!rlang::sym(b) - !!rlang::sym(a)) |>
      summarise(n = unweighted(n()),
                dif = 100 * survey_mean(d_par, vartype = "ci")) |>
      mutate(nutriente = z$nutriente[1], metodo = z$metodo[1],
             escenario_desde = a, escenario_hasta = b, .before = 1)
  }) |> bind_rows()
}) |> bind_rows() |>
  transmute(escenario_desde, escenario_hasta, nutriente, metodo, n,
            dif_pp = dif, dif_pp_low = dif_low, dif_pp_upp = dif_upp,
            significativa = (dif_low > 0) | (dif_upp < 0)) |>
  arrange(nutriente, metodo, escenario_desde, escenario_hasta)

message("\nDiferencias pareadas frente a la linea base (puntos porcentuales):")
print(as.data.frame(
  diferencias |>
    filter(escenario_desde == ESCENARIO_BASE,
           metodo != "Probabilidad, biodisponibilidad 18%") |>
    select(escenario_hasta, nutriente, dif_pp, dif_pp_low, dif_pp_upp)
), digits = 3)

write_delim(riesgo, here("data", "clean", "riesgo_inadecuacion.csv"), delim = ";")
write_delim(diferencias, here("data", "clean", "diferencias_escenarios.csv"), delim = ";")
