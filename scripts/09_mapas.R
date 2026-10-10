# 09_mapas.R
#
# Mapas provinciales: bivariado de cobertura y consumo de vehiculos, y
# coropletico de riesgo de ingesta inadecuada con marca de precision.
#
# Geometria: paquete sfDR (limites del geoportal IDERD y Division Territorial
# 2021 de la ONE, licencia MIT). Se descarga UNA vez y se guarda como GeoJSON
# en data/raw para que el entregable no dependa de un paquete experimental.
#
# Empate con la encuesta: por identificador numerico de provincia. Exacto para
# las 32. Dos nombres difieren y no son errores: "Baoruco" (ONE) frente a
# "BAHORUCO" (encuesta), y "Hermanas Mirabal" frente a "SALCEDO", que es el
# nombre anterior al renombramiento de la provincia.
#
# Requiere haber corrido 04, 05, 06 y 07.
#
# Uso: source(here::here("scripts", "09_mapas.R"))

library(dplyr); library(tidyr); library(readr); library(here)
library(srvyr); library(sf); library(ggplot2); library(biscale); library(cowplot)

leer <- function(...) read_delim(here(...), delim = ";", show_col_types = FALSE,
                                locale = locale(decimal_mark = "."), guess_max = 100000)
norm_txt <- function(x) trimws(iconv(tolower(as.character(x)), to = "ASCII//TRANSLIT"))

dir.create(here("media", "mapas"), showWarnings = FALSE, recursive = TRUE)

# --- 1. Geometria, descargada una sola vez -----------------------------------
geo_f <- here("data", "raw", "provincias_rd.geojson")
if (!file.exists(geo_f)) {
  if (!requireNamespace("sfDR", quietly = TRUE)) {
    stop("Falta sfDR. Instalar con:\n",
         'install.packages("sfDR", repos = c("https://adatar-do.r-universe.dev", ',
         '"https://cloud.r-project.org"))', call. = FALSE)
  }
  sfDR::dr_provinces() |>
    transmute(id_provincia = as.integer(PROV_ID), PROV_CODE, PROV_NAME) |>
    st_write(geo_f, delete_dsn = TRUE, quiet = TRUE)
  writeLines(c(
    "provincias_rd.geojson",
    "",
    "Limites provinciales de la Republica Dominicana, 32 provincias.",
    "Fuente: paquete sfDR (github.com/adatar-do/sfDR), que los toma del",
    "geoportal del IDERD (geoportal.iderd.gob.do) y de la Division Territorial",
    "2021 de la Oficina Nacional de Estadistica. Licencia MIT.",
    paste("Extraido el", Sys.Date(), "con sfDR", as.character(packageVersion("sfDR"))),
    "",
    "El campo id_provincia es PROV_ID convertido a entero, que empata de forma",
    "exacta con id_provincia de la ENGIH 2018."
  ), here("data", "raw", "provincias_rd_FUENTE.txt"))
  message("Geometria guardada en data/raw/provincias_rd.geojson")
}
provincias <- st_read(geo_f, quiet = TRUE)
stopifnot(nrow(provincias) == 32)

# --- 2. Consumo de vehiculos por provincia -----------------------------------
# Misma definicion de vehiculo que 06: se lee el mismo archivo de parametros.
vehiculos <- leer("data", "raw", "vehiculos_escenarios.csv")
DERIVADOS_TRIGO <- c("Pan", "Pastas", "Galletas saladas", "Galletas dulces",
                     "Reposteria", "Repostería")

asignar_vehiculo <- function(descripcion) {
  d <- norm_txt(descripcion); v <- rep(NA_character_, length(d))
  for (i in seq_len(nrow(vehiculos))) {
    hit <- grepl(vehiculos$patron[i], d) & is.na(v)
    if (!is.na(vehiculos$excluir[i])) hit <- hit & !grepl(vehiculos$excluir[i], d)
    v[hit] <- vehiculos$vehiculo[i]
  }
  v
}

hogar <- leer("data", "clean", "data_ema_hogar.csv") |>
  select(id_hogar_unico, estrato, upm, factor_expansion, id_provincia)

consumo <- leer("data", "clean", "data_gramos_por_ema.csv") |>
  filter(!almacenado) |>
  mutate(vehiculo = asignar_vehiculo(descripcion)) |>
  left_join(vehiculos |> select(vehiculo, fraccion_harina), by = "vehiculo") |>
  filter(!is.na(vehiculo)) |>
  mutate(grupo = if_else(vehiculo %in% c("Harina de trigo", DERIVADOS_TRIGO),
                         "Trigo, en equivalentes de harina", vehiculo),
         gramos = Gramos_por_EMA_dia * coalesce(fraccion_harina, 1)) |>
  group_by(id_hogar_unico, grupo) |>
  summarise(g = sum(gramos), .groups = "drop") |>
  complete(id_hogar_unico = hogar$id_hogar_unico, grupo, fill = list(g = 0)) |>
  inner_join(hogar, by = "id_hogar_unico")

dis <- consumo |>
  as_survey_design(ids = upm, strata = estrato, weights = factor_expansion, nest = TRUE)

# Guarda: el agregado nacional debe reproducir la salida de 06.
nac <- dis |> group_by(grupo) |>
  summarise(pct_hogares = 100 * survey_mean(g > 0, vartype = NULL),
            mediana_consumidores = survey_median(if_else(g > 0, g, NA_real_),
                                                 vartype = NULL, na.rm = TRUE))
ref <- leer("data", "clean", "escenarios_consumo_vehiculos.csv") |>
  select(grupo, pct_ref = pct_hogares, med_ref = mediana_consumidores)
chk <- inner_join(nac, ref, by = "grupo")
if (nrow(chk) != nrow(ref) ||
    any(abs(chk$pct_hogares - chk$pct_ref) > 0.1) ||
    any(abs(chk$mediana_consumidores - chk$med_ref) > 0.5)) {
  print(as.data.frame(chk))
  stop("La asignacion de vehiculos no reproduce el agregado de 06. Revisar antes de mapear.",
       call. = FALSE)
}
message("Guarda superada: el agregado nacional coincide con 06.")

por_prov <- dis |> group_by(id_provincia, grupo) |>
  summarise(n = unweighted(n()),
            pct_hogares = 100 * survey_mean(g > 0, vartype = NULL),
            mediana = survey_median(if_else(g > 0, g, NA_real_),
                                    vartype = NULL, na.rm = TRUE),
            .groups = "drop")
write_delim(por_prov, here("data", "clean", "vehiculos_por_provincia.csv"), delim = ";")

# --- 3. Mapa bivariado: cobertura x consumo ----------------------------------
# Cortes fijos, los mismos de los analisis de referencia del proyecto, para que
# los mapas sean comparables entre paises.
CORTES_COB <- c(0, 25, 50, 75, 100)            # % de hogares que lo adquiere
CORTES_CON <- c(0, 75, 150, 300, Inf)          # g por EMA y dia
DIM <- 4
PALETA <- "BlueGold"
ok <- tryCatch({ bi_pal(PALETA, dim = DIM, preview = FALSE); TRUE }, error = function(e) FALSE)
if (!ok) { DIM <- 3; CORTES_COB <- c(0, 40, 70, 100); CORTES_CON <- c(0, 100, 250, Inf)
  message("biscale sin dim = 4; se usan 3 clases.") }

bi <- por_prov |>
  filter(grupo %in% c("Arroz", "Trigo, en equivalentes de harina")) |>
  mutate(ix = as.integer(cut(pct_hogares, CORTES_COB, labels = seq_len(DIM),
                             include.lowest = TRUE)),
         iy = as.integer(cut(mediana, CORTES_CON, labels = seq_len(DIM),
                             include.lowest = TRUE)),
         bi_class = if_else(is.na(ix) | is.na(iy), NA_character_,
                            paste0(ix, "-", iy)),
         grupo = recode(grupo, "Trigo, en equivalentes de harina" = "Trigo")) |>
  inner_join(provincias, by = "id_provincia") |> st_as_sf()

if (any(is.na(bi$bi_class))) {
  message("AVISO: ", sum(is.na(bi$bi_class)), " combinaciones provincia-vehiculo ",
          "sin clase (sin consumidores); se pintan en gris.")
}

# Un mapa por vehiculo. No se usa facet_wrap: bi_theme() y el facetado rompen
# la construccion del gtable de ggplot2.
mapa_de <- function(g) {
  d <- bi |> filter(grupo == g)
  ggplot() +
    geom_sf(data = filter(d, is.na(bi_class)), fill = "grey85",
            colour = "white", linewidth = 0.18) +
    geom_sf(data = filter(d, !is.na(bi_class)), aes(fill = bi_class),
            colour = "white", linewidth = 0.18, show.legend = FALSE) +
    bi_scale_fill(pal = PALETA, dim = DIM) +
    labs(title = g) +
    theme_void(base_size = 11) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 13,
                                    colour = "#1a3a4a"))
}

leyenda <- bi_legend(pal = PALETA, dim = DIM, size = 8,
                     xlab = "Cobertura (% que lo adquiere)",
                     ylab = "Consumo (g/EMA/día)")

ggsave(here("media", "mapas", "mapa_bivariado_vehiculos.png"),
       plot_grid(mapa_de("Arroz"), mapa_de("Trigo"), leyenda,
                 nrow = 1, rel_widths = c(1, 1, 0.62)),
       width = 12, height = 5, dpi = 200, bg = "white")

# --- 4. Coropletico de riesgo, con precision declarada -----------------------
# Las celdas de precision insuficiente no se pintan con su valor: se declaran.
# Province no es dominio de estimacion de la encuesta.
# El archivo de riesgo identifica la provincia por el nombre de la encuesta.
# Se traduce a identificador con la propia tabla de hogares, y el empate con la
# geometria va por identificador: exacto para las 32. Unir por nombre fallaria
# en Baoruco/BAHORUCO y en Hermanas Mirabal/SALCEDO.
lookup <- leer("data", "clean", "data_ema_hogar.csv") |>
  distinct(id_provincia, des_provincia) |>
  mutate(nivel_n = norm_txt(des_provincia))

riesgo <- leer("data", "clean", "riesgo_inadecuacion.csv") |>
  filter(dominio == "Provincia", hogares == "Todos",
         nutriente == "folato_mcg_dfe", metodo == "Punto de corte") |>
  mutate(nivel_n = norm_txt(nivel)) |>
  left_join(lookup, by = "nivel_n")

sin_id <- sum(is.na(riesgo$id_provincia))
if (sin_id > 0) {
  stop(sin_id, " provincias del archivo de riesgo no se pudieron identificar: ",
       paste(riesgo$nivel[is.na(riesgo$id_provincia)], collapse = ", "),
       call. = FALSE)
}

mapa_riesgo <- provincias |>
  left_join(riesgo |> select(id_provincia, pct_inadecuado, precision_baja),
            by = "id_provincia") |>
  mutate(valor = if_else(coalesce(precision_baja, TRUE), NA_real_, pct_inadecuado))

g_riesgo <- ggplot(mapa_riesgo) +
  geom_sf(aes(fill = valor), colour = "white", linewidth = 0.18) +
  scale_fill_gradientn(
    colours = wesanderson::wes_palette("Zissou1", 100, type = "continuous"),
    limits = c(0, 100), labels = function(x) paste0(x, "%"),
    na.value = "grey85",
    name = "Hogares bajo el\nrequerimiento de folato") +
  labs(caption = paste(
    "Escenario de linea base. Gris: precision insuficiente (menos de 50 hogares o",
    "semiamplitud del intervalo mayor de 10 puntos).\nLa provincia no es dominio de",
    "estimacion de la encuesta. Valores de referencia provisionales.")) +
  theme_void(base_size = 11) +
  theme(plot.caption = element_text(hjust = 0, colour = "#5a6b76", size = 8))

ggsave(here("media", "mapas", "mapa_riesgo_folato.png"), g_riesgo,
       width = 8.5, height = 6, dpi = 200, bg = "white")

message("\nMapas en media/mapas/. Provincias con precision suficiente: ",
        sum(!is.na(mapa_riesgo$valor)), " de 32.")
