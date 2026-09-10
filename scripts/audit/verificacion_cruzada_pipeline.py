# =============================================================================
# verificacion_cruzada_pipeline.py
# Proyecto: ENGIH 2018 - Consumo y nutrición (WFP)
# Creado: 2026-09-10 (auditoría externa)
#
# PROPÓSITO
#   Réplica INDEPENDIENTE (Python) del pipeline R (01_import → 02_eda →
#   03_transform → 04_equivalente_adulto → 05_ingesta_micronutrientes) para:
#     1. Verificar contra los datos reales cada cifra publicada en
#        HOJA_DE_RUTA_PROYECTO.md / README.md (auditoría doc-vs-datos).
#     2. Detectar bugs del pipeline R que solo se ven corriendo de punta a
#        punta (fan-out por claves duplicadas, filas muertas, etc.).
#     3. Producir un AVANCE PRELIMINAR del paso 05 (4 nutrientes: energía,
#        hierro, folato, vitamina A) como verificación cruzada del script R
#        cuando se complete.
#
# NO REEMPLAZA al pipeline R: es una segunda implementación para triangular.
# Si R y Python discrepan, la regla del proyecto aplica: investigar antes de
# publicar (principio 5 de VISION_Y_ARQUITECTURA_PROYECTO.md).
#
# ENTRADAS (mismas que usa el pipeline R):
#   data/raw/data_raw_sec2.csv, data_raw_sec3a.csv   (exportes del crudo;
#     verificado 2026-09-10: mismos conteos de filas que las hojas
#     "Cuest. B Sec 2"/"Cuest. B Sec 3A" de Registros_Cuestionario_B.xlsx)
#   data/raw/data_raw_unidades.xlsx                  (FC universal + específico)
#   data/raw/crosswalk_tablas_composicion.xlsx       (enhance_id + validado)
#   data/raw/food_factors.xlsx                       (PC/edible)
#   data/raw/food_composition_INCAP.xlsx             (nutrientes, por 100 g)
#   data/raw/food_composition_FNDDS.xlsx             (nutrientes, por 100 g)
#   data/raw/Sociodemograficas_e_ingresos.xlsx "Base" (sexo/edad + ESTRATO/UPM/
#     FACTOR_EXPANSION -- extraída a data/audit/socio_extract.csv por velocidad)
#
# SALIDAS (data/audit/): resúmenes CSV pequeños + log en consola.
#
# USO:  python3 scripts/audit/verificacion_cruzada_pipeline.py
# =============================================================================

import os
import sys

import numpy as np
import pandas as pd

# --- Configuración de rutas -------------------------------------------------
RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW = os.path.join(RAIZ, "data", "raw")
AUDIT = os.path.join(RAIZ, "data", "audit")
os.makedirs(AUDIT, exist_ok=True)

pd.set_option("display.width", 220)


def separador(txt):
    print("\n" + "=" * 78)
    print(txt)
    print("=" * 78)


# =============================================================================
# PASO 0. Cargar tablas de referencia (espejo de 01_import.R)
# =============================================================================
separador("PASO 0. Tablas de referencia")

dic = pd.read_excel(os.path.join(RAW, "data_raw_unidades.xlsx"), sheet_name="diccionario_conversion")
dic = dic[dic["FC"].notna()][["id_unidad_medida_presentacion", "FC"]].rename(columns={"FC": "fc_universal"})
print(f"diccionario_conversion: {len(dic)} unidades universales con FC")

s2fc = pd.read_excel(os.path.join(RAW, "data_raw_unidades.xlsx"), sheet_name="Cuest. B Sec 2")
s2fc_con_fc = s2fc[s2fc["FC"].notna()]
print(f"FC específico Sec 2: {len(s2fc_con_fc)} filas con FC | "
      f"filas con clave (variedad) vacía = INERTES: {s2fc_con_fc['variedad'].isna().sum()}")
s2fc = s2fc_con_fc[["variedad", "id_unidad_medida_presentacion", "FC"]].rename(columns={"FC": "fc_especifico"})
dups2 = s2fc.duplicated(subset=["variedad", "id_unidad_medida_presentacion"], keep=False).sum()
print(f"  claves duplicadas en tabla específica Sec2: {dups2}")

s3fc = pd.read_excel(os.path.join(RAW, "data_raw_unidades.xlsx"), sheet_name="Cuest. B Sec 3A")
s3fc_con_fc = s3fc[s3fc["FC"].notna()].copy()
# Normaliza descripcion para el join por texto (igual que hace R: exacto)
dup3 = s3fc_con_fc.groupby(["descripcion", "id_unidad_medida_presentacion"]).size()
print(f"FC específico Sec 3A: {len(s3fc_con_fc)} filas con FC | "
      f"CLAVES DUPLICADAS (fan-out en left_join): {(dup3 > 1).sum()}")
if (dup3 > 1).sum():
    for (d, u), n in dup3[dup3 > 1].items():
        print(f"    !! '{d}' + unidad {u}: {n} filas -> cada fila del crudo se DUPLICA")
s3fc = s3fc_con_fc[["descripcion", "id_unidad_medida_presentacion", "FC"]].rename(columns={"FC": "fc_especifico"})

# Crosswalk (puente a enhance_id)
cw2 = pd.read_excel(os.path.join(RAW, "crosswalk_tablas_composicion.xlsx"), sheet_name="Cuest. B Sec 2")
cw2 = cw2.rename(columns={"variedad": "id_variedad"})
cw3 = pd.read_excel(os.path.join(RAW, "crosswalk_tablas_composicion.xlsx"), sheet_name="Cuest. B Sec 3A")


def puente(cw):
    cw = cw.copy()
    cw["validado"] = cw["validado"].astype(str).str.upper().isin(["TRUE", "1"])
    cw["enhance_id"] = pd.to_numeric(cw["enhance_id"], errors="coerce")
    out = cw[cw["validado"] & cw["enhance_id"].notna()][
        ["id_variedad", "enhance_id", "fuente"]].copy()
    return out


p2 = puente(cw2)
p3 = puente(cw3)
p3["id_variedad"] = p3["id_variedad"].astype(float).astype(int).astype(str)  # como as.character(as.numeric()) en R
p2["id_variedad"] = pd.to_numeric(p2["id_variedad"], errors="coerce")
print(f"crosswalk Sec 2: {len(p2)} variedades con enhance_id validado (de {len(cw2)})")
print(f"crosswalk Sec 3A: {len(p3)} id_variedad con enhance_id validado (de {len(cw3)} validadas={cw3['validado'].astype(str).str.upper().isin(['TRUE','1']).sum()})")

# PC/edible
ff2 = pd.read_excel(os.path.join(RAW, "food_factors.xlsx"), sheet_name="Cuest. B Sec 2")
ff2["edible"] = ff2["edible"].astype(str).str.replace(",", ".", regex=False).astype(float)
ff2["enhance_id"] = pd.to_numeric(ff2["enhance_id"], errors="coerce")
pc2 = ff2[["enhance_id", "edible"]]

ff3 = pd.read_excel(os.path.join(RAW, "food_factors.xlsx"), sheet_name="Cuest. B Sec 3A")
ff3["id_variedad"] = ff3["id_variedad"].astype(float).astype(int).astype(str)
pc3 = ff3[["id_variedad", "edible"]]
print(f"food_factors (PC): Sec2 {len(pc2)} enhance_id | Sec3A {len(pc3)} id_variedad")

# Nutrientes (por 100 g -> se convierte a por gramo)
incap = pd.read_excel(os.path.join(RAW, "food_composition_INCAP.xlsx"), sheet_name="nutrient_values")
fndds = pd.read_excel(os.path.join(RAW, "food_composition_FNDDS.xlsx"), sheet_name="nutrient_values", skiprows=1)

nut_cols = {
    "energia_kcal": ("ENERC_KCAL", "Energy (kcal)"),
    "hierro_mg": ("FE", "Iron\n(mg)"),
    "folato_mcg_dfe": ("FOLDFE", "Folate, DFE (mcg_DFE)"),
    "vitamina_a_mcg_rae": ("VITA_RAE", "Vitamin A, RAE (mcg_RAE)"),
}
nut_incap = pd.DataFrame({"enhance_id": pd.to_numeric(incap["ENHANCE_ID"], errors="coerce")})
nut_fndds = pd.DataFrame({"enhance_id": pd.to_numeric(fndds["Food code"], errors="coerce")})
for nuevo, (ci, cf) in nut_cols.items():
    nut_incap[nuevo] = pd.to_numeric(incap[ci], errors="coerce") / 100.0
    nut_fndds[nuevo] = pd.to_numeric(fndds[cf], errors="coerce") / 100.0
colision = set(nut_incap["enhance_id"].dropna()) & set(nut_fndds["enhance_id"].dropna())
print(f"nutrientes: INCAP {len(nut_incap)} alimentos | FNDDS {len(nut_fndds)} | "
      f"colisión de IDs entre fuentes: {len(colision)}")
nutrientes = pd.concat([nut_incap, nut_fndds], ignore_index=True)

# =============================================================================
# PASO 1. Crudo + resolución de FC (espejo de 01_import.R)
# =============================================================================
separador("PASO 1. Crudo y resolución de FC (espejo 01_import.R)")

crudo2 = pd.read_csv(os.path.join(RAW, "data_raw_sec2.csv"), sep=";")
crudo3 = pd.read_csv(os.path.join(RAW, "data_raw_sec3a.csv"), sep=";",
                     dtype={"id_variedad": str, "vivienda": str, "hogar": str}, low_memory=False)
crudo2["id_hogar_unico"] = crudo2["vivienda"].astype(str) + "_" + crudo2["hogar"].astype(str)
crudo3["id_hogar_unico"] = crudo3["vivienda"].astype(str) + "_" + crudo3["hogar"].astype(str)
print(f"Crudo Sec 2: {len(crudo2)} filas | Sec 3A: {len(crudo3)} filas")

for df in (crudo2, crudo3):
    df["unidad_a_convertir"] = df["id_unidad_medida_presentacion"].combine_first(
        pd.to_numeric(df["id_unidad_medida"], errors="coerce"))


def resolver_fc(df, fc_esp, clave, dedupe=False):
    """Espejo de la lógica de 3 niveles de 01_import.R.
    dedupe=True elimina claves duplicadas de la tabla específica ANTES del join
    (corrección del bug de fan-out), quedándose con la fila de mayor id (la
    última añadida: peso-por-unidad manual)."""
    t = fc_esp.copy()
    if dedupe:
        t = (t.sort_values("_orden")
               .drop_duplicates(subset=[t.columns[0], "id_unidad_medida_presentacion"], keep="last"))
    m = df.merge(t, how="left",
                 left_on=[clave, "unidad_a_convertir"],
                 right_on=[t.columns[0], "id_unidad_medida_presentacion"])
    m = m.merge(dic, how="left", left_on="unidad_a_convertir",
                right_on="id_unidad_medida_presentacion", suffixes=("", "_dic"))
    m["fc"] = m["fc_universal"].combine_first(m["fc_especifico"])
    return m


s3fc["_orden"] = np.arange(len(s3fc))  # para dedupe: gana la última (manual)

# --- Estado ACTUAL del repo (sin correcciones: fan-out incluido) ---
a2 = resolver_fc(crudo2, s2fc, "variedad")
a3 = resolver_fc(crudo3, s3fc, "descripcion")
print("\n-- Estado ACTUAL del repo (lo que produce hoy 01_import.R) --")
print(f"Sec 2 : {len(a2)} filas | universal {a2['fc_universal'].notna().sum()} | "
      f"específica {(a2['fc_universal'].isna() & a2['fc_especifico'].notna()).sum()} | "
      f"SIN FC {a2['fc'].isna().sum()}")
print(f"Sec 3A: {len(a3)} filas (crudo {len(crudo3)}) | universal {a3['fc_universal'].notna().sum()} | "
      f"específica {(a3['fc_universal'].isna() & a3['fc_especifico'].notna()).sum()} | "
      f"SIN FC {a3['fc'].isna().sum()}")
print(f"   >>> fan-out Sec3A: {len(a3) - len(crudo3)} filas duplicadas espurias")

# --- Estado CORREGIDO (dedupe + filas muertas Sec2 con variedad llena) ---
s2fc_full = s2fc_con_fc.copy()
varmap = {"HUEVOS": 15, "PANES": 1, "GALLETAS SALADAS": 3}
for desc, var in varmap.items():
    m = s2fc_full["descripcion"] == desc
    s2fc_full.loc[m, "variedad"] = s2fc_full.loc[m, "variedad"].fillna(var)
s2fc_fix = s2fc_full[["variedad", "id_unidad_medida_presentacion", "FC"]].rename(columns={"FC": "fc_especifico"})
b2 = resolver_fc(crudo2, s2fc_fix, "variedad")
b3 = resolver_fc(crudo3, s3fc, "descripcion", dedupe=True)
print("\n-- Estado CORREGIDO (dedupe Sec3A + variedad en filas de peso-por-unidad Sec2) --")
print(f"Sec 2 : {len(b2)} filas | universal {b2['fc_universal'].notna().sum()} | "
      f"específica {(b2['fc_universal'].isna() & b2['fc_especifico'].notna()).sum()} | "
      f"SIN FC {b2['fc'].isna().sum()}")
print(f"Sec 3A: {len(b3)} filas | universal {b3['fc_universal'].notna().sum()} | "
      f"específica {(b3['fc_universal'].isna() & b3['fc_especifico'].notna()).sum()} | "
      f"SIN FC {b3['fc'].isna().sum()}")

# =============================================================================
# PASO 2. Consumo diario + outliers (espejo de 03_transform.R)  [estado corregido]
# =============================================================================
separador("PASO 2. Consumo diario y outliers (espejo 03_transform.R) [corregido]")


def armar(df, puente_tabla, pc_tabla, clave_puente, clave_pc, Q_col, PM):
    d = df.copy()
    d["Q"] = pd.to_numeric(d[Q_col], errors="coerce")
    d = d.merge(puente_tabla, how="left", left_on=clave_puente, right_on="id_variedad")
    if clave_pc == "enhance_id":
        d = d.merge(pc_tabla, how="left", on="enhance_id")
    else:
        d = d.merge(pc_tabla, how="left", on="id_variedad")
    d["Consumo_diario_g"] = d["Q"] * d["fc"] * d["edible"] / PM
    return d


# Sec 2: PM = 7 fijo
sec2 = armar(b2, p2, pc2, "variedad", "enhance_id", "consumo_exclusivo_hogar", 7)

# Sec 3A: PM = dias_observados_hogar
dias = crudo3.groupby("id_hogar_unico")["dia"].nunique().rename("dias_observados_hogar")
sec3 = armar(b3, p3, pc3, "id_variedad", "id_variedad", "cantidad_adquirida", 1)
sec3 = sec3.merge(dias, how="left", left_on="id_hogar_unico", right_index=True)
sec3["PM_real"] = sec3["dias_observados_hogar"].where(sec3["dias_observados_hogar"] > 0, 7.0)
sec3["Consumo_diario_g"] = sec3["Q"] * sec3["fc"] * sec3["edible"] / sec3["PM_real"]


def marcar_outliers(d):
    # OJO: R group_by(enhance_id) AGRUPA los NA juntos (comportamiento reproducido
    # con dropna=False) -- documentado en HOJA_DE_RUTA como limitación.
    d = d.copy()
    g = d.groupby("enhance_id", dropna=False)["Consumo_diario_g"]
    d["n_grupo"] = g.transform("size")
    d["p995"] = g.transform(lambda x: x.quantile(0.995) if len(x) >= 20 else np.nan)
    d["p005"] = g.transform(lambda x: x.quantile(0.005) if len(x) >= 20 else np.nan)
    d["es_outlier"] = (d["Consumo_diario_g"].notna() & d["p995"].notna() &
                       ((d["Consumo_diario_g"] > d["p995"] * 5) |
                        ((d["Consumo_diario_g"] < d["p005"] / 5) & (d["Consumo_diario_g"] > 0))))
    return d.drop(columns=["n_grupo", "p995", "p005"])


sec2, sec3 = marcar_outliers(sec2), marcar_outliers(sec3)
print(f"Sec 2 : consumo calculado {sec2['Consumo_diario_g'].notna().sum()}/{len(sec2)} | "
      f"outliers {int(sec2['es_outlier'].sum())}")
print(f"Sec 3A: consumo calculado {sec3['Consumo_diario_g'].notna().sum()}/{len(sec3)} | "
      f"outliers {int(sec3['es_outlier'].sum())}")

# =============================================================================
# PASO 3. EMA (espejo de 04_equivalente_adulto.R)
# =============================================================================
separador("PASO 3. Equivalente de Mujer Adulta (espejo 04)")

socio_path = os.path.join(AUDIT, "socio_extract.csv")
if not os.path.exists(socio_path):
    cols = ["VIVIENDA", "HOGAR", "MIEMBRO", "A402", "A403", "FACTOR_EXPANSION",
            "ESTRATO", "UPM", "DES_ESTRATO", "GRUPO_REGION"]
    socio = pd.read_excel(os.path.join(RAW, "Sociodemograficas_e_ingresos.xlsx"),
                          sheet_name="Base", usecols=cols)
    socio.to_csv(socio_path, index=False)
else:
    socio = pd.read_csv(socio_path)

socio = socio.rename(columns={"A402": "sexo", "A403": "edad",
                              "FACTOR_EXPANSION": "factor_expansion",
                              "VIVIENDA": "vivienda", "HOGAR": "hogar"})
socio["id_hogar_unico"] = socio["vivienda"].astype(str) + "_" + socio["hogar"].astype(str)

tabla_ninos = (
    [(1, 2, "M", 948), (2, 3, "M", 1129), (3, 4, "M", 1252), (4, 5, "M", 1360),
     (5, 6, "M", 1467), (6, 7, "M", 1573), (7, 8, "M", 1692), (8, 9, "M", 1830),
     (9, 10, "M", 1978), (10, 11, "M", 2150), (11, 12, "M", 2341), (12, 13, "M", 2548),
     (13, 14, "M", 2770), (14, 15, "M", 2990), (15, 16, "M", 3178), (16, 17, "M", 3322),
     (17, 18, "M", 3410),
     (1, 2, "F", 865), (2, 3, "F", 1047), (3, 4, "F", 1156), (4, 5, "F", 1241),
     (5, 6, "F", 1330), (6, 7, "F", 1428), (7, 8, "F", 1554), (8, 9, "F", 1698),
     (9, 10, "F", 1854), (10, 11, "F", 2006), (11, 12, "F", 2149), (12, 13, "F", 2276),
     (13, 14, "F", 2379), (14, 15, "F", 2449), (15, 16, "F", 2491), (16, 17, "F", 2503),
     (17, 18, "F", 2503)]
)
PAL, pH, pM = 1.76, 65.0, 55.0
tabla_adultos = [
    (18, 30, "M", (15.057 * pH + 692.2) * PAL),
    (30, 60, "M", (11.472 * pH + 873.1) * PAL),
    (60, 150, "M", (11.711 * pH + 587.7) * PAL),
    (18, 30, "F", (14.818 * pM + 486.6) * PAL),   # = 2290.8 kcal, referencia EMA
    (30, 60, "F", (8.126 * pM + 845.6) * PAL),
    (60, 150, "F", (9.082 * pM + 658.5) * PAL),
]
REQ = pd.DataFrame(tabla_ninos + tabla_adultos, columns=["d", "h", "s", "kcal"])
REF_EMA = (14.818 * pM + 486.6) * PAL
KCAL_0 = 600.0  # provisional <1 año (limitación documentada en 04)


def kcal_req(edad, sexo):
    if pd.isna(edad) or pd.isna(sexo):
        return np.nan
    s = {1: "M", 2: "F"}.get(int(sexo))  # A402: 1=Masculino, 2=Femenino
    if s is None:
        return np.nan
    if edad < 1:
        return KCAL_0
    f = REQ[(REQ.s == s) & (REQ.d <= edad) & (edad < REQ.h)]
    return f["kcal"].iloc[0] if len(f) else np.nan


socio["kcal_req"] = [kcal_req(e, s) for e, s in zip(socio["edad"], socio["sexo"])]
socio["EMA_i"] = socio["kcal_req"] / REF_EMA
ema_hogar = socio.groupby("id_hogar_unico").agg(
    n_miembros=("EMA_i", "size"), EMA_hogar=("EMA_i", "sum"),
    factor_expansion=("factor_expansion", "first")).reset_index()
print(f"Hogares: {len(ema_hogar)} | EMA mediana: {ema_hogar['EMA_hogar'].median():.2f} | "
      f"personas sin EMA: {socio['EMA_i'].isna().sum()}")
print(f"Suma factor_expansion (hogares): {ema_hogar['factor_expansion'].sum():,.0f}")

# =============================================================================
# PASO 4. Gramos por EMA (espejo del paso 6 de 04) + verificación del hito
# =============================================================================
separador("PASO 4. Gramos por EMA (espejo 04 paso 6)")

consumo = pd.concat([
    sec2[["id_hogar_unico", "descripcion", "enhance_id", "Consumo_diario_g", "es_outlier"]],
    sec3[["id_hogar_unico", "descripcion", "enhance_id", "Consumo_diario_g", "es_outlier"]],
], ignore_index=True)
validos = consumo[consumo["Consumo_diario_g"].notna() &
                  ~(consumo["es_outlier"].fillna(False))]
gpe = validos.merge(ema_hogar[["id_hogar_unico", "EMA_hogar"]], on="id_hogar_unico", how="inner")
gpe = gpe[gpe["EMA_hogar"] > 0]
gpe["Gramos_por_EMA_dia"] = gpe["Consumo_diario_g"] / gpe["EMA_hogar"]
print(f"Registros de consumo válidos (sin outliers): {len(validos)}")
print(f"Gramos por EMA calculado: {len(gpe)} filas  [hito documentado 2026-09-08: 254,905]")
gpe.to_csv(os.path.join(AUDIT, "gramos_por_ema_python.csv"), index=False)

# =============================================================================
# PASO 5. AVANCE PRELIMINAR de 05: ingesta aparente de 4 nutrientes por EMA
# =============================================================================
separador("PASO 5. Ingesta aparente (avance preliminar de 05_ingesta_micronutrientes.R)")

# --- Cobertura honesta: qué parte del crudo ENTRA al cálculo -----------------
# Una fila entra solo si tiene fc (FC) + edible (PC). Como los 144 alimentos
# de food_factors (Sec3A) están todos en el crosswalk validado (verificado
# arriba), el PC es el cuello de botella efectivo: quien tiene PC también
# tiene enhance_id. Por eso el match de nutrientes sobre filas YA calculadas
# es ~100% -- la subestimación ocurre ANTES, en las filas excluidas.
for nombre, sec in [("Sec 2", sec2), ("Sec 3A", sec3)]:
    n = len(sec)
    sin_fc = (sec["fc"].isna()).sum()
    con_fc_sin_pc = (sec["fc"].notna() & sec["edible"].isna()).sum()
    con_pc_sin_fc = (sec["edible"].notna() & sec["fc"].isna()).sum()
    dentro = sec["Consumo_diario_g"].notna().sum()
    print(f"{nombre}: {dentro:,} de {n:,} filas entran al cálculo ({100*dentro/n:.1f}%) | "
          f"excluidas: sin FC {sin_fc:,} | FC pero sin PC {con_fc_sin_pc:,} | PC pero sin FC {con_pc_sin_fc:,}")

excl = pd.concat([
    sec2.loc[sec2["Consumo_diario_g"].isna(), ["descripcion", "fc", "edible"]],
    sec3.loc[sec3["Consumo_diario_g"].isna(), ["descripcion", "fc", "edible"]],
])
top_excl = excl.groupby("descripcion").size().sort_values(ascending=False).head(20)
print("\nTop 20 alimentos EXCLUIDOS del cálculo (prioridad de relleno):")
print(top_excl.to_string())
top_excl.rename("filas_excluidas").to_csv(os.path.join(AUDIT, "prioridad_relleno_excluidos.csv"))

gpe_base = gpe.copy()  # copia pre-merge de nutrientes (la usa el PASO 7)
gpe = gpe_base.merge(nutrientes, on="enhance_id", how="left")
for n in nut_cols:
    gpe[f"intake_{n}"] = gpe["Gramos_por_EMA_dia"] * gpe[n]

matched = gpe[gpe["energia_kcal"].notna()]
cov_fils = 100 * len(matched) / len(gpe)
cov_gramos = 100 * matched["Gramos_por_EMA_dia"].sum() / gpe["Gramos_por_EMA_dia"].sum()
print(f"\nMatch de nutrientes sobre filas ya calculadas: {cov_fils:.1f}% de filas | "
      f"{cov_gramos:.1f}% de gramos (esperado ~100%: PC ⊆ crosswalk, ver arriba)")

hog = gpe.groupby("id_hogar_unico").agg(
    gramos_tot=("Gramos_por_EMA_dia", "sum"),
    **{f"intake_{n}": (f"intake_{n}", "sum") for n in nut_cols}
).reset_index()
hog = hog.merge(ema_hogar[["id_hogar_unico", "factor_expansion", "EMA_hogar"]], on="id_hogar_unico")

w = hog["factor_expansion"].fillna(0)


def wstats(x):
    ww = w[x.notna()]
    xx = x[x.notna()]
    m = np.average(xx, weights=ww)
    return m


print("\nIngesta aparente por EMA (hogares, ponderado por factor_expansion):")
refs = {"energia_kcal": 2291, "hierro_mg": 8.1, "folato_mcg_dfe": 320, "vitamina_a_mcg_rae": 500}
for n in nut_cols:
    col = f"intake_{n}"
    media = wstats(hog[col])
    mediana = hog[col].median()
    # % hogares por debajo del EAR (ILUSTRATIVO: nivel hogar, no individual)
    bajo = 100 * (hog.loc[hog[col] < refs[n], "factor_expansion"].sum()) / w.sum()
    print(f"  {n:22s}: media pond. {media:9.1f} | mediana {mediana:9.1f} | "
          f"ref. EAR/EER {refs[n]:6.0f} | hogares bajo ref: {bajo:5.1f}%")

# Top alimentos contribuyentes (hierro y folato) entre lo cubierto
print("\nTop 10 alimentos por aporte a la ingesta de HIERRO (solo filas con match):")
top_fe = (matched.groupby("descripcion")["intake_hierro_mg"].sum()
          .sort_values(ascending=False).head(10))
print(top_fe.to_string())
print("\nTop 10 alimentos por aporte a FOLATO:")
top_fol = (matched.groupby("descripcion")["intake_folato_mcg_dfe"].sum()
           .sort_values(ascending=False).head(10))
print(top_fol.to_string())

hog.to_csv(os.path.join(AUDIT, "ingesta_hogar_python.csv"), index=False)

# =============================================================================
# PASO 6. Verificación del ejemplo ponderado de 03 (cobertura arroz 70213002)
#          + versión con diseño muestral COMPLETO (ESTRATO/UPM, disponible!)
# =============================================================================
separador("PASO 6. Cobertura ponderada del arroz blanco enriquecido (70213002)")

ejemplo_id = 70213002
cons3 = sec3.copy()
cons3["consume"] = ((cons3["enhance_id"] == ejemplo_id) &
                    cons3["Consumo_diario_g"].notna()).astype(int)
cov = cons3.groupby("id_hogar_unico").agg(
    consume=("consume", "max"), fe=("factor_expansion", "first")).reset_index()
cov = cov[cov["fe"].notna()]
p = np.average(cov["consume"], weights=cov["fe"])
# SE con ids=1 (lo que hace hoy 03_transform.R)
n = len(cov)
se_sr = np.sqrt(p * (1 - p) / n)
# SE con diseño estratificado por UPM (las variables YA EXISTEN en el repo)
cov = cov.merge(ema_hogar[["id_hogar_unico", "factor_expansion"]].rename(
    columns={"factor_expansion": "fe2"}), on="id_hogar_unico", how="left")
cov = cov.merge(socio.groupby("id_hogar_unico")[["ESTRATO", "UPM"]].first().reset_index(),
                on="id_hogar_unico", how="left")
u = cov["fe"] * (cov["consume"] - p)  # linealizado del estimador de razón
tmp = pd.DataFrame({"h": cov["ESTRATO"], "u": u})
var = 0.0
for h, g in tmp.groupby("h"):
    nh = len(g)
    if nh > 1:
        var += nh / (nh - 1) * ((g["u"] - g["u"].mean()) ** 2).sum()
var /= cov["fe"].sum() ** 2
se_dsg = np.sqrt(var)
print(f"Cobertura ponderada: {100 * p:.1f}%  [documentado en 03: 30.0% (IC 28.9-31.1)]")
print(f"  IC ids=1 (actual, subestimado):    {100*p-1.96*100*se_sr:.1f} - {100*p+1.96*100*se_sr:.1f}%")
print(f"  IC diseño completo ESTRATO+UPM:    {100*p-1.96*100*se_dsg:.1f} - {100*p+1.96*100*se_dsg:.1f}%")

# =============================================================================
# PASO 7. Ilustración de escenarios de fortificación (capa de intercambio de
#          entradas de composición, como requiere la especificación de Santiago)
# =============================================================================
# Hallazgo clave de la auditoría (2026-09-10): el crosswalk actual apunta el
# arroz a entradas ENRIQUECIDAS (70213002) cuando en RD el arroz NO estaba
# fortificado en 2018, la harina de trigo a la entrada SIN ENRIQUECER (70213038)
# cuando en RD SÍ es obligatoria (NORDOM, 45 mg/kg Fe, 1.8 mg/kg folato), y el
# azúcar a entradas SIN FORTIFICAR cuando NORDOM 606 exige vitamina A (5-25
# mg/kg). Fuente: Informe ENM 2009 RD (repositorio MSP), que describe el
# programa vigente. La tabla INCAP tiene las entradas pareadas, así que cada
# escenario es solo un intercambio de enhance_id por vehículo.
separador("PASO 7. Escenarios de fortificación (ilustración, capa de intercambio)")

# Vehículos y entradas INCAP (verificadas arriba contra la tabla real):
#   Arroz blanco crudo:      enriquecido 70213002 (FE 4.36, FOL 386) | s/enrio 70213004 (FE 0.80, FOL 9)
#   Harina de trigo:         enriquecida 70213039 (FE 4.64, FOL 291) | s/enrio 70213038 (FE 1.17, FOL 26)
#   Azúcar blanca granulada: fortif. A   70215002 (VIT A 1000 mcg/100g = 10 mg/kg) | s/fort 70215001
escenarios = {
    "(a) sin fortificación (arroz 70213004, harina 70213038, azúcar 70215001)":
        {70213002: 70213004, 70213038: 70213038, 70215001: 70215001, 70215036: 70215001},
    "(b) norma RD vigente 2018 (arroz s/fort, harina 70213039, azúcar 70215002)":
        {70213002: 70213004, 70213038: 70213039, 70215001: 70215002, 70215036: 70215002},
    "(c) crosswalk actual (mixto: arroz enriquecido, harina s/enrio, azúcar s/fort)":
        {},
}

print(f"{'escenario':70s} | {'nutriente':16s} | {'mediana':>9s} | {'%hog<EAR':>8s}")
resumen_esc = []
for nombre_esc, swaps in escenarios.items():
    gg = gpe_base.copy()
    if swaps:
        gg["enhance_id"] = gg["enhance_id"].replace(swaps)
    gg = gg.merge(nutrientes, on="enhance_id", how="left")
    for n in nut_cols:
        gg[f"intake_{n}"] = gg["Gramos_por_EMA_dia"] * gg[n]
    h = gg.groupby("id_hogar_unico").agg(**{f"i_{n}": (f"intake_{n}", "sum") for n in nut_cols}).reset_index()
    h = h.merge(ema_hogar[["id_hogar_unico", "factor_expansion"]], on="id_hogar_unico")
    for n in nut_cols:
        col = f"i_{n}"
        bajo = 100 * h.loc[h[col] < refs[n], "factor_expansion"].sum() / h["factor_expansion"].sum()
        print(f"{nombre_esc:70s} | {n:16s} | {h[col].median():9.1f} | {bajo:7.1f}%")
        resumen_esc.append({"escenario": nombre_esc, "nutriente": n,
                            "mediana_hogar_por_EMA": h[col].median(), "pct_hogares_bajo_EAR": bajo})

pd.DataFrame(resumen_esc).to_csv(os.path.join(AUDIT, "escenarios_fortificacion_python.csv"), index=False)
print("\nNota: pan/pastas/galletas mantienen su entrada actual en los 3 escenarios")
print("(decisión pendiente: si asumen harina fortificada en sus valores INCAP).")

# =============================================================================
# RESUMEN DE VERIFICACIÓN doc-vs-datos
# =============================================================================
separador("RESUMEN: cifras documentadas vs. verificadas")
comparaciones = [
    ("Crudo Sec 2 filas", "47,837", f"{len(crudo2):,}"),
    ("Crudo Sec 3A filas", "342,046", f"{len(crudo3):,}"),
    ("Sec2 FC universal", "22,316 (doc 05-09)", f"{a2['fc_universal'].notna().sum():,}"),
    ("Sec2 FC específica", "16,866 (doc 05-09, sin pesos-por-unidad)",
     f"{(a2['fc_universal'].isna() & a2['fc_especifico'].notna()).sum():,} (hoy: con pesos-por-unidad + fix filas inertes)"),
    ("Sec2 SIN FC", "8,655 (doc 05-09)", f"{a2['fc'].isna().sum():,} (hoy: 4,242 filas recuperadas con el fix)"),
    ("Sec3A FC universal", "107,095 (doc 05-09)", f"{a3['fc_universal'].notna().sum():,}"),
    ("Sec3A filas tras joins (fan-out)", "342,046 (doc: sin fan-out)",
     f"{len(a3):,} ({'OK, sin fan-out' if len(a3) == len(crudo3) else '!! FAN-OUT: ' + format(len(a3)-len(crudo3), ',') + ' filas duplicadas'})"),
    ("Crosswalk Sec3A validado", "420/769", f"{cw3['validado'].astype(str).str.upper().isin(['TRUE','1']).sum()}/769"),
    ("food_factors Sec3A", "144 alimentos", f"{len(pc3)} alimentos"),
    ("Hogares con EMA", "8,892 (mediana 3.04)", f"{len(ema_hogar):,} (mediana {ema_hogar['EMA_hogar'].median():.2f})"),
    ("Gramos por EMA", "254,905 (hito 08-09, sin pesos-por-unidad)",
     f"{len(gpe):,} (hoy: incluye filas resueltas por pesos-por-unidad)"),
    ("Cobertura arroz 70213002", "30.0% (IC 28.9-31.1)", f"{100*p:.1f}% (IC diseño {100*p-1.96*100*se_dsg:.1f}-{100*p+1.96*100*se_dsg:.1f})"),
]
for nombre, doc, real in comparaciones:
    print(f"  {nombre:32s} | doc: {doc:28s} | verificado: {real}")

print("\nFIN de la verificación cruzada.")
