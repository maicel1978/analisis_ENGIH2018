# ==============================================================================
# 91_helper_diseno_muestral.R
# Uso unico (2026-09-13). Borrar del repo una vez commiteado el resultado.
#
# ETAPA 2 de 2. Anade a reports/_comun.R las funciones para estimar con el
# diseno muestral complejo de la ENGIH.
#
# CRITERIO ADOPTADO
#   - Medias ponderadas con varianza por linealizacion de Taylor (el metodo por
#     defecto de `survey`/`srvyr`, y el que espera cualquier revision de un
#     analisis de encuesta compleja). Con intervalo de confianza.
#   - Mediana ponderada al lado, como descriptivo, SIN intervalo. Que un
#     estimador lleve intervalo y el otro no es normal: cada uno cumple un papel.
#   - NO se aplican estimadores robustos a los 572 hogares con ingesta
#     implausible. No son ruido estadistico: son un problema identificado con
#     causa conocida (solapamiento entre secciones). Se declaran y se resuelven
#     con datos, no se tapan con metodo.
# ==============================================================================

library(here)

ruta <- here("reports", "_comun.R")
if (!file.exists(ruta)) stop("No encuentro reports/_comun.R", call. = FALSE)

txt <- paste(readLines(ruta, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

if (grepl("diseno_muestral <- function", txt, fixed = TRUE)) {
  stop("El helper ya esta en _comun.R. Nada que hacer.", call. = FALSE)
}

ancla <- "# --- Helpers ------------------------------------------------------------------"
if (regexpr(ancla, txt, fixed = TRUE) == -1) {
  stop("No encuentro la seccion de helpers en _comun.R", call. = FALSE)
}

bloque <- '# --- Diseno muestral complejo -------------------------------------------------
# La ENGIH es una muestra estratificada por conglomerados: 8 estratos, 933
# unidades primarias de muestreo (UPM) y factor de expansion por hogar.
#
# Ignorar la estructura NO sesga las estimaciones puntuales de forma
# sistematica, pero SI subestima los errores estandar: los intervalos salen
# demasiado estrechos y cualquier contraste se vuelve optimista.
#
# Requiere que 04_equivalente_adulto.R haya conservado estrato, upm y
# factor_expansion en data_ema_hogar.csv (desde 2026-09-13).

cargar_ema_hogar <- function() {
  f <- file.path(RUTA_CLEAN, "data_ema_hogar.csv")
  exigir_archivo(f, "04_equivalente_adulto.R")
  d <- leer_limpio(f)
  faltan <- setdiff(c("estrato", "upm", "factor_expansion"), names(d))
  if (length(faltan) > 0) {
    stop("`data_ema_hogar.csv` no tiene: ", paste(faltan, collapse = ", "),
         ". Volver a correr scripts/04_equivalente_adulto.R.", call. = FALSE)
  }
  d
}

# Construye el objeto de diseno a partir de un data frame a nivel de HOGAR.
# `datos` debe traer id_hogar_unico; las variables de diseno se unen desde
# data_ema_hogar.csv, que es donde viven.
diseno_muestral <- function(datos) {
  if (!requireNamespace("srvyr", quietly = TRUE)) {
    stop("Falta el paquete `srvyr`. Instalar con install.packages(\\"srvyr\\").",
         call. = FALSE)
  }

  dis <- cargar_ema_hogar() |>
    select(id_hogar_unico, estrato, upm, factor_expansion,
           quintil, zona, grupo_region)

  d <- datos |>
    inner_join(dis, by = "id_hogar_unico", suffix = c("", "_dis"))

  perdidos <- nrow(datos) - nrow(d)
  if (perdidos > 0) {
    warning(perdidos, " filas sin correspondencia en el marco muestral; ",
            "quedan fuera de la estimacion.", call. = FALSE)
  }

  srvyr::as_survey_design(d, ids = upm, strata = estrato,
                          weights = factor_expansion, nest = TRUE)
}

# Media ponderada con intervalo (Taylor) + mediana ponderada como descriptivo.
# `por` admite variables de agrupacion: quintil, zona, grupo_region.
estimar <- function(diseno, variable, por = NULL, nivel = 0.95) {
  v <- rlang::ensym(variable)
  d <- if (is.null(por)) diseno else dplyr::group_by(diseno, dplyr::across(all_of(por)))

  media <- d |>
    srvyr::summarise(
      n        = srvyr::unweighted(dplyr::n()),
      media    = srvyr::survey_mean(!!v, vartype = "ci", level = nivel,
                                    na.rm = TRUE)
    )

  mediana <- d |>
    srvyr::summarise(
      mediana = srvyr::survey_median(!!v, vartype = NULL, na.rm = TRUE)
    )

  if (is.null(por)) dplyr::bind_cols(media, mediana)
  else dplyr::left_join(media, mediana, by = por)
}

# Proporcion ponderada con intervalo, para indicadores de cobertura.
# `condicion` debe ser una columna logica ya calculada en `datos`.
estimar_proporcion <- function(diseno, condicion, por = NULL, nivel = 0.95) {
  v <- rlang::ensym(condicion)
  d <- if (is.null(por)) diseno else dplyr::group_by(diseno, dplyr::across(all_of(por)))

  d |>
    srvyr::summarise(
      n = srvyr::unweighted(dplyr::n()),
      p = srvyr::survey_mean(!!v, vartype = "ci", level = nivel, na.rm = TRUE)
    ) |>
    dplyr::mutate(dplyr::across(dplyr::starts_with("p"), ~ .x * 100))
}

'

nuevo <- sub(ancla, paste0(bloque, ancla), txt, fixed = TRUE)
writeLines(strsplit(nuevo, "\n")[[1]], ruta, useBytes = TRUE)

cat("\n--------------------------------------------------\n")
cat("Helper anadido a reports/_comun.R\n")
cat("  cargar_ema_hogar()     -- lee el nivel de hogar con las variables de diseno\n")
cat("  diseno_muestral(datos) -- construye el objeto srvyr\n")
cat("  estimar()              -- media con IC + mediana ponderada\n")
cat("  estimar_proporcion()   -- proporcion con IC\n")
cat("--------------------------------------------------\n")
cat("\nPrueba rapida (pegar en la consola):\n\n")
cat('  source(here::here("reports", "_comun.R"))\n')
cat('  ing <- leer_limpio(file.path(RUTA_CLEAN, "data_ingesta_micronutrientes_hogar.csv"))\n')
cat('  ing <- dplyr::filter(ing, variante == "Sec 2 + Sec 3A")\n')
cat('  dis <- diseno_muestral(ing)\n')
cat('  estimar(dis, energia_kcal)\n\n')
cat("Debe devolver n = 8774, una media con su intervalo, y una mediana\n")
cat("ponderada cercana a 2.153 kcal (el valor sin ponderar).\n")
