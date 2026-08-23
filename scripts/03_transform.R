# Creación de nuevas variables

# Guardo los datos en un dataset crudo  para limpiar y transformar luego
data_sec2 <- data_raw_sec2 |> 
  left_join(y = data_raw_unidades,
            by = join_by(id_unidad_medida  == id_unidad_medida) ) |>
  transmute(id = hogar, # Identificador único de hogar 
            alimento = factor(x = variedad,
                              levels =variedad,
                              labels =descripcion  ),
            cantidad = cantidad_inicial-cantidad_final, # revisar
            unidad_medida = des_unidad_medida , # revisar
            consumo=consumo_exclusivo_hogar
  ) |> 