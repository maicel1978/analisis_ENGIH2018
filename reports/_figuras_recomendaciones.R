# Cifras y figuras de presentacion_recomendaciones.qmd.
# Lee los mismos archivos que el informe final, de modo que las cifras no
# pueden divergir. La presentacion solo contiene texto y llamadas a estos
# objetos.

ruta_comun <- c(here::here("reports", "_comun.R"),
                here::here("scripts", "_comun.R"))
source(ruta_comun[file.exists(ruta_comun)][1])
library(ggplot2); library(tidyr)

AZUL <- "#2c5364"; AZUL_C <- "#7ba3bd"; GRIS <- "#c9d3da"; ACENTO <- "#c0623c"

tema <- function(base = 16) {
  theme_minimal(base_size = base) +
    theme(panel.grid.minor   = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(colour = "#eef2f4"),
          axis.title  = element_text(colour = "#5a6b76", size = rel(0.85)),
          plot.title  = element_text(face = "bold", colour = "#1a3a4a",
                                     size = rel(0.95)),
          legend.position = "none")
}

leer_clean <- function(archivo, script) {
  f <- file.path(RUTA_CLEAN, archivo)
  exigir_archivo(f, script)
  leer_limpio(f)
}

rie  <- leer_clean("riesgo_inadecuacion.csv",        "07_riesgo_inadecuacion.R")
esc  <- leer_clean("escenarios_resumen.csv",         "06_escenarios_fortificacion.R")
veh  <- leer_clean("escenarios_consumo_vehiculos.csv","06_escenarios_fortificacion.R")
gnut <- leer_clean("grupos_micronutrientes.csv",     "08_grupos_alimentos.R")
refs <- leer_limpio(file.path(RUTA_RAW, "valores_referencia.csv"))
entregables <- leer_limpio(file.path(RUTA_RAW, "entregables_estado.csv")) |>
  arrange(orden)

E_SIN   <- "0. Sin fortificación"
E_BASE  <- "1a. Norma nacional: harina y pan"
E_TODOS <- "1b. Norma nacional: harina y todos los derivados"
E_AZUC  <- "1c. Norma nacional y azúcar"
E_OMS   <- "2b. OMS: harina y derivados, consumo de 75 a 149 g"
E_ARROZ <- "3. Norma nacional y arroz (propuesta nacional)"
faltan <- setdiff(c(E_SIN, E_BASE, E_TODOS, E_AZUC, E_OMS, E_ARROZ),
                  unique(esc$escenario))
if (length(faltan) > 0) {
  stop("Escenarios ausentes en escenarios_resumen.csv: ",
       paste(faltan, collapse = "; "), call. = FALSE)
}

ROTULOS <- tibble::tribble(
  ~escenario, ~corto,
  E_SIN,   "Sin\nfortificar",
  E_BASE,  "Hoy:\nharina y pan",
  E_TODOS, "Todos los\nderivados",
  E_AZUC,  "Con\nazúcar",
  "2a. OMS: harina y derivados, consumo menor de 75 g", "OMS\n(<75 g)",
  E_OMS,   "Nivel\nOMS",
  E_ARROZ, "Con\narroz"
)
corto <- function(x) ROTULOS$corto[match(x, ROTULOS$escenario)]

metodo_de <- function(nutriente_) {
  m <- rie |>
    filter(nutriente == nutriente_, metodo != "Probabilidad, biodisponibilidad 18%") |>
    distinct(metodo) |> pull()
  if (length(m) != 1) stop("Metodo no identificado para ", nutriente_, ".", call. = FALSE)
  m
}

riesgo_nac <- function(escenario_, nutriente_) {
  v <- rie |>
    filter(dominio == "Nacional", hogares == "Todos", escenario == escenario_,
           nutriente == nutriente_, metodo == metodo_de(nutriente_)) |>
    pull(pct_inadecuado)
  if (length(v) != 1) stop("Riesgo no identificado: ", escenario_, " / ",
                           nutriente_, ".", call. = FALSE)
  v
}

riesgo_ic <- function(escenario_, nutriente_) {
  r <- rie |>
    filter(dominio == "Nacional", hogares == "Todos", escenario == escenario_,
           nutriente == nutriente_, metodo == metodo_de(nutriente_))
  if (nrow(r) != 1) stop("Riesgo sin IC: ", escenario_, " / ", nutriente_, ".",
                         call. = FALSE)
  paste0(fmt(r$pct_inadecuado), "% (IC 95%: ", fmt(r$pct_inadecuado_low),
         "–", fmt(r$pct_inadecuado_upp), ")")
}

n_analitico <- function() {
  v <- rie |> filter(dominio == "Nacional", hogares == "Todos") |>
    distinct(n) |> pull()
  if (length(v) != 1) stop("Tamano analitico no identificado.", call. = FALSE)
  v
}

ETIQ_NUT <- c(folato_mcg_dfe = "Folato", hierro_mg = "Hierro",
              vitamina_a_mcg_rae = "Vitamina A", zinc_mg = "Zinc",
              vitamina_b12_mcg = "Vitamina B12")

# Los escenarios estan ANIDADOS: 1c y 3 incluyen 1b, que incluye 1a. Comparar
# cualquiera de ellos contra 1a atribuye a la accion que lo distingue una
# mejora que pertenece al escalon anterior. Cada accion se compara por tanto
# contra su predecesor inmediato, declarado en la figura.

# Diferencias pareadas entre escenarios, con su intervalo. Los dos escenarios se
# estiman sobre los mismos hogares: el intervalo de la diferencia no se obtiene
# restando los extremos de los dos intervalos marginales.
dif <- leer_clean("diferencias_escenarios.csv", "07_riesgo_inadecuacion.R")

dif_ic <- function(desde, hasta, nutriente_) {
  m <- metodo_de(nutriente_)
  r <- dif |> filter(escenario_desde == .env$desde,
                     escenario_hasta == .env$hasta,
                     nutriente == .env$nutriente_, metodo == .env$m)
  if (nrow(r) != 1) stop("Diferencia no identificada: ", desde, " -> ", hasta,
                         " / ", nutriente_, ".", call. = FALSE)
  paste0(if_else(r$dif_pp < 0, "−", "+"), fmt(abs(r$dif_pp)),
         " pp (IC 95%: ", fmt(r$dif_pp_low), " a ", fmt(r$dif_pp_upp), ")")
}

# Superlativas calculadas del mismo archivo que alimenta cada figura, para que
# el texto y la figura no puedan contradecirse.
# Grupo principal de cada micronutriente, del mismo archivo que alimenta la
# figura de grupos.
top_grupo <- gnut |>
  pivot_longer(any_of(names(ETIQ_NUT)), names_to = "n", values_to = "pct") |>
  filter(!is.na(pct)) |>
  group_by(n) |> slice_max(pct, n = 1) |> ungroup() |>
  mutate(Grupo = sub("^[0-9]{2} ", "", grupo_mddw))
fol_top <- top_grupo |> filter(n == "folato_mcg_dfe")
b12_top <- top_grupo |> filter(n == "vitamina_b12_mcg")
if (nrow(fol_top) != 1 || nrow(b12_top) != 1) {
  stop("Grupo principal no identificado para folato o vitamina B12.", call. = FALSE)
}

v_cob <- veh |> slice_max(pct_hogares, n = 1)
v_con <- veh |> slice_max(mediana_consumidores, n = 1)
n_mayoria <- sum(veh$pct_hogares >= 50)

# --- Cifras citadas en el texto ------------------------------------------------
n_hogares      <- fmt(n_analitico(), 0)
n_vehiculos    <- nrow(veh)
folato_hoy     <- riesgo_ic(E_BASE, "folato_mcg_dfe")
hierro_hoy     <- riesgo_ic(E_BASE, "hierro_mg")
cambio_azucar  <- dif_ic(E_TODOS, E_AZUC, "vitamina_a_mcg_rae")
hierro_18      <- rie |>
  filter(dominio == "Nacional", hogares == "Todos", escenario == E_BASE,
         nutriente == "hierro_mg", metodo == "Probabilidad, biodisponibilidad 18%") |>
  pull(pct_inadecuado) |> fmt()

# --- fig_concepto ----------------------------------------------------------
fig_concepto <- local({
  paso <- tibble::tibble(
    i = 1:4,
    titulo = c("Vitaminas y minerales",
               "No se fabrican",
               "La carencia no se ve",
               "Fortificación"),
    texto = c("El cuerpo los necesita\ntodos los días, en\ncantidades muy pequeñas",
              "El cuerpo no los produce.\nEntran únicamente con\nlos alimentos",
              "Si la alimentación diaria\nno los aporta, la carencia\nse instala sin síntomas",
              "Se añaden en la planta\nde producción a un alimento\nde consumo masivo")
  )

  ANCHO <- 0.86; ALTO <- 1.5
  ggplot(paso) +
    geom_rect(aes(xmin = i - ANCHO/2, xmax = i + ANCHO/2,
                  ymin = -ALTO/2, ymax = ALTO/2,
                  fill = i == 4), colour = NA) +
    geom_segment(data = tibble::tibble(x = (1:3) + ANCHO/2 + 0.02),
                 aes(x = x, xend = x + 0.1, y = 0, yend = 0),
                 inherit.aes = FALSE, colour = AZUL_C, linewidth = 1.1,
                 arrow = arrow(length = unit(0.16, "cm"), type = "closed")) +
    geom_text(aes(i, 0.52, label = titulo, colour = i == 4),
              fontface = "bold", size = 5, show.legend = FALSE) +
    geom_text(aes(i, -0.12, label = texto, colour = i == 4),
              size = 4.1, lineheight = 1.15, show.legend = FALSE) +
    scale_fill_manual(values = c(`FALSE` = "#eef2f4", `TRUE` = AZUL)) +
    scale_colour_manual(values = c(`FALSE` = "#1a3a4a", `TRUE` = "white")) +
    coord_cartesian(xlim = c(0.45, 4.55), ylim = c(-1.35, 0.95)) +
    annotate("rect", xmin = 0.45, xmax = 4.55, ymin = -1.3, ymax = -0.92,
             fill = "#eef2f4", colour = NA) +
    annotate("text", x = 2.5, y = -1.11,
             label = paste("A gran escala: lo ejecuta la industria por mandato de una norma,",
                           "en todo el país,\nsin que las personas modifiquen lo que comen."),
             size = 4.3, lineheight = 1.2, colour = "#1a3a4a", fontface = "bold") +
    theme_void() + theme(legend.position = "none")
})

# --- fig_cadena ------------------------------------------------------------
fig_cadena <- local({
  eslabon <- tibble::tibble(
    i = 1:3,
    texto = c("Alimentos que el hogar\ndeclaró adquirir",
              "Tabla de composición\nde alimentos",
              "Aporte estimado de\nmicronutrientes")
  )
  AN <- 2.3
  ggplot(eslabon) +
    geom_rect(aes(xmin = i*3 - AN/2, xmax = i*3 + AN/2, ymin = -0.5, ymax = 0.5,
                  fill = i == 3), colour = NA) +
    geom_segment(data = tibble::tibble(x = c(3, 6) + AN/2 + 0.08),
                 aes(x = x, xend = x + 0.45, y = 0, yend = 0), inherit.aes = FALSE,
                 colour = AZUL_C, linewidth = 1.1,
                 arrow = arrow(length = unit(0.16, "cm"), type = "closed")) +
    geom_text(aes(i*3, 0, label = texto, colour = i == 3),
              size = 4.3, lineheight = 1.15, show.legend = FALSE) +
    scale_fill_manual(values = c(`FALSE` = "#eef2f4", `TRUE` = AZUL)) +
    scale_colour_manual(values = c(`FALSE` = "#1a3a4a", `TRUE` = "white")) +
    coord_cartesian(xlim = c(1.6, 10.4), ylim = c(-0.62, 0.62)) +
    theme_void() + theme(legend.position = "none")
})

# --- fig_vehiculos ---------------------------------------------------------
fig_vehiculos <- local({
  veh |>
    mutate(grupo = reorder(grupo, pct_hogares)) |>
    ggplot(aes(pct_hogares, grupo)) +
    geom_segment(aes(x = 0, xend = pct_hogares, yend = grupo),
                 colour = GRIS, linewidth = 1.6) +
    geom_point(colour = AZUL, size = 4.4) +
    geom_text(aes(label = paste0(fmt(pct_hogares), "%  ·  ",
                                 fmt(mediana_consumidores, 0), " g")),
              hjust = -0.2, size = 4, colour = "#44555f") +
    scale_x_continuous(limits = c(0, 130), breaks = seq(0, 100, 25),
                       labels = function(x) paste0(x, "%")) +
    labs(x = "Hogares que lo adquieren (%)", y = NULL) +
    tema()
})

# --- fig_riesgo ------------------------------------------------------------
fig_riesgo <- local({
  base_nut <- rie |>
    filter(dominio == "Nacional", hogares == "Todos", escenario == E_BASE,
           nutriente %in% names(ETIQ_NUT),
           metodo %in% c("Punto de corte", "Probabilidad, biodisponibilidad 10%")) |>
    mutate(nut = reorder(ETIQ_NUT[nutriente], pct_inadecuado))

  ggplot(base_nut, aes(pct_inadecuado, nut)) +
    geom_segment(aes(x = pct_inadecuado_low, xend = pct_inadecuado_upp,
                     y = nut, yend = nut), colour = GRIS, linewidth = 1.4) +
    geom_point(colour = AZUL, size = 4.2) +
    geom_text(aes(label = paste0(fmt(pct_inadecuado), "%")),
              hjust = -0.35, size = 4.1, colour = "#44555f") +
    scale_x_continuous(limits = c(0, 108), breaks = seq(0, 100, 25),
                       labels = function(x) paste0(x, "%")) +
    labs(x = "Hogares bajo el requerimiento (%)", y = NULL) +
    tema()
})

# --- fig_norma -------------------------------------------------------------
fig_norma <- local({
  par_nut <- rie |>
    filter(dominio == "Nacional", hogares == "Todos",
           escenario %in% c(E_SIN, E_BASE), nutriente %in% names(ETIQ_NUT),
           metodo %in% c("Punto de corte", "Probabilidad, biodisponibilidad 10%")) |>
    select(escenario, nutriente, pct_inadecuado) |>
    pivot_wider(names_from = escenario, values_from = pct_inadecuado) |>
    mutate(nut = ETIQ_NUT[nutriente],
           evita = .data[[E_SIN]] - .data[[E_BASE]]) |>
    arrange(desc(evita)) |>
    mutate(nut = factor(nut, levels = rev(nut)))

  ggplot(par_nut, aes(y = nut)) +
    geom_segment(aes(x = .data[[E_BASE]], xend = .data[[E_SIN]], yend = nut),
                 colour = GRIS, linewidth = 1.6) +
    geom_point(aes(x = .data[[E_SIN]]), colour = ACENTO, size = 4) +
    geom_point(aes(x = .data[[E_BASE]]), colour = AZUL, size = 4) +
    geom_text(aes(x = .data[[E_BASE]],
                  label = if_else(evita >= 0.5,
                                  paste0("−", fmt(evita), " pp"), "")),
              hjust = 1.25, size = 3.9, colour = "#44555f") +
    scale_x_continuous(limits = c(0, 100), labels = function(x) paste0(x, "%")) +
    labs(x = "Hogares bajo el requerimiento (%)", y = NULL) +
    tema()
})

# --- fig_grupos ------------------------------------------------------------
fig_grupos <- local({
  largo <- gnut |>
    pivot_longer(any_of(names(ETIQ_NUT)), names_to = "n", values_to = "pct") |>
    filter(!is.na(pct)) |>
    mutate(Grupo = sub("^[0-9]{2} ", "", grupo_mddw),
           Nutriente = factor(ETIQ_NUT[n], levels = ETIQ_NUT))
  orden <- largo |> filter(n == "folato_mcg_dfe") |> arrange(pct) |> pull(Grupo)

  largo |> mutate(Grupo = factor(Grupo, levels = orden)) |>
    ggplot(aes(Nutriente, Grupo, fill = pct)) +
    geom_tile(colour = "white", linewidth = 0.6) +
    geom_text(aes(label = if_else(pct >= 5, fmt(pct, 0), ""),
                  colour = pct >= 25), size = 3.4, show.legend = FALSE) +
    scale_fill_gradient(low = "#eef2f4", high = AZUL) +
    scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "#44555f")) +
    labs(x = NULL, y = NULL) +
    tema(13) + theme(panel.grid.major.y = element_blank())
})

# --- fig_azucar ------------------------------------------------------------
fig_azucar <- local({
  a_antes <- riesgo_nac(E_TODOS, "vitamina_a_mcg_rae")
  a_desp  <- riesgo_nac(E_AZUC,  "vitamina_a_mcg_rae")

  tibble::tibble(x = c(1, 2),
                 v = c(a_antes, a_desp),
                 et = c("Hoy\nNorma no aplicada", "Norma cumplida")) |>
    ggplot(aes(x, v)) +
    geom_segment(aes(x = 1, xend = 2, y = a_antes, yend = a_desp),
                 colour = GRIS, linewidth = 1.6) +
    geom_point(size = 11, colour = c(ACENTO, AZUL)) +
    geom_text(aes(label = paste0(fmt(v, 1), "%")), vjust = -1.9,
              size = 7.5, fontface = "bold", colour = "#1a3a4a") +
    geom_text(aes(y = 0, label = et), vjust = 1.1, size = 4.6,
              lineheight = 1.1, colour = "#5a6b76") +
    scale_x_continuous(limits = c(0.65, 2.35)) +
    scale_y_continuous(limits = c(0, 92)) +
    labs(x = NULL, y = NULL) +
    theme_void() +
    theme(plot.margin = margin(14, 10, 24, 10))
})

# --- fig_acciones ----------------------------------------------------------
fig_acciones <- local({
  acciones <- tibble::tribble(
    ~orden, ~accion,                                  ~desde,  ~hasta,
    1, "Cumplir la norma del azúcar",                 E_TODOS, E_AZUC,
    2, "Ampliar a todos los derivados del trigo",     E_BASE,  E_TODOS,
    3, "Elevar al nivel de la OMS",                   E_TODOS, E_OMS,
    4, "Incorporar el arroz",                         E_TODOS, E_ARROZ
  )

  metodos_principales <- c("Punto de corte", "Probabilidad, biodisponibilidad 10%")

  datos <- acciones |>
    inner_join(dif |> filter(metodo %in% metodos_principales,
                             nutriente %in% names(ETIQ_NUT)),
               by = c("desde" = "escenario_desde", "hasta" = "escenario_hasta"),
               relationship = "one-to-many") |>
    filter(abs(dif_pp) >= 0.5) |>
    mutate(accion = factor(accion, levels = rev(acciones$accion)),
           nut = ETIQ_NUT[nutriente])

  ggplot(datos, aes(dif_pp, accion)) +
    geom_vline(xintercept = 0, colour = "#c9d3da", linewidth = 0.7) +
    geom_segment(aes(x = dif_pp_low, xend = dif_pp_upp, y = accion, yend = accion),
                 colour = GRIS, linewidth = 1.2) +
    geom_point(colour = AZUL, size = 3.4) +
    geom_text(aes(label = nut), vjust = -1.1, size = 3.5, colour = "#5a6b76") +
    scale_x_continuous(limits = c(-52, 6),
                       labels = function(x) paste0(x, " pp")) +
    labs(x = "Cambio en la proporción de hogares bajo el requerimiento", y = NULL) +
    tema(14)
})

# --- tabla_entregables -----------------------------------------------------
tabla_entregables <- local({
  entregables |>
    transmute(`Producto` = entregable, `TdR` = tdr, `Situación` = situacion) |>
    tabla(fuente = "Fuente: registro de avance del repositorio del proyecto.",
          notas = "El detalle metodológico está en el informe analítico y en el manual técnico.")
})
