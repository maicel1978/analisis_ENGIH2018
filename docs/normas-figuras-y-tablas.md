# Normas de figuras y tablas

Referencia única para el informe final (TdR 7 y 8), el manual técnico (TdR 18) y
la difusión posterior. El criterio es el de una revista con revisión por pares:
la figura y su leyenda deben bastar para interpretarla sin leer el cuerpo del
texto. Pendiente de aplicar; levantado el 2026-10-11.

## Por qué está escrito aparte

Las tablas del informe ya llevan título y notas; los mapas de `09_mapas.R`
todavía no. El mismo trabajo hace falta en los dos, y conviene que el criterio
viva en un archivo y no en la cabeza de quien lo aplica.

## Toda figura

1. **Numeración y leyenda al pie.** En publicación la figura no lleva título
   incrustado: lo lleva la leyenda. En presentación e informe interno sí
   conviene el título dentro de la imagen. Son dos salidas de la misma figura y
   hay que decidirla, no heredarla.
2. **La leyenda declara, en este orden:** qué se muestra, la cantidad con su
   unidad y su denominador, el escenario, la población o el subconjunto de
   hogares, la fuente de los datos, el método de clasificación con sus cortes,
   la regla de precisión y qué significa el gris, y el estado de los valores de
   referencia cuando son provisionales.
3. **Unidad y denominador en el eje o en la leyenda de color**, nunca solo en
   la leyenda al pie. Una escala que dice `%` sin decir por ciento de qué no
   está rotulada.
4. **Tamaño final.** Exportar al ancho de columna definitivo (una columna, en
   torno a 85 mm; dos columnas, en torno a 180 mm) y no reescalar después: al
   reescalar, la tipografía deja de ser legible. Vectorial (PDF o SVG) cuando
   se pueda; 300 dpi o más si es raster.
5. **Paleta verificada para visión del color.** Divergente rojo-azul es
   aceptable; cualquier combinación que dependa de distinguir rojo de verde no
   lo es. El color no debe ser el único portador de la información.
6. **Cortes idénticos entre figuras comparables.** Dos mapas con escalas
   distintas no se comparan, aunque estén lado a lado.

## La figura tiene que corresponder al hallazgo

La norma que más veces se incumple no es de formato. Una figura puede estar
bien construida y no decir nada, porque el recurso elegido no corresponde a lo
que se encontró.

- **Un esquema bivariado de dieciséis clases sirve cuando hay variación en los
  dos ejes.** Aplicado a una variable homogénea entre territorios, las
  dieciséis clases se reducen a dos y la leyenda deja de transportar
  información. Para mostrar **ausencia** de variación sirve mejor la
  dispersión: los 32 valores provinciales en un eje y el nacional marcado.
- **Un mapa sirve cuando la posición importa.** Si el hallazgo es que la
  posición no importa, el mapa lo oculta en vez de mostrarlo.
- La prueba: enunciar el hallazgo en una frase y preguntarse si la figura la
  sostiene. Si la frase es «no hay diferencia» y la figura está construida para
  mostrar diferencias, la figura es la equivocada.

## Toda afirmación numérica del texto se calcula del mismo archivo que la figura

Una afirmación escrita a mano junto a una figura generada del dato pueden
discrepar sin que nadie lo advierta hasta que alguien lo nota en pantalla. Las
superlativas —el mayor, el de más alcance, el principal— se obtienen con código
del mismo archivo que alimenta la figura. Así las dos leen lo mismo y no pueden
contradecirse.

## Específico de mapas

7. **Barra de escala y norte.** `ggspatial::annotation_scale()` y
   `annotation_north_arrow()`.
8. **Proyección declarada.** Hoy la geometría se dibuja en coordenadas
   geográficas. Para publicación hay que proyectar a un sistema apropiado para
   el país y declararlo en la leyenda. Un mapa en grados deforma las áreas y un
   revisor lo señala.
9. **El gris se explica siempre** en la leyenda al pie, con la regla exacta que
   lo produce. Un gris sin explicar se lee como cero.
10. **Advertencia de dominio.** La provincia no es dominio de estimación de la
    ENGIH 2018. Va en la leyenda de todo mapa provincial, no solo del primero.
11. **Fuente de la geometría con fecha y licencia.** Está en
    `data/raw/provincias_rd_FUENTE.txt`; hay que trasladarla a la leyenda.

## Específico de tablas

12. **Título arriba, notas abajo.** Unidades en el encabezado de cada columna.
13. **n por celda** y la medida de incertidumbre que corresponda, o la marca de
    precisión insuficiente.
14. **Una nota de diseño** que indique que las estimaciones son ponderadas y
    que la varianza es de diseño complejo con linealización de Taylor.

## Estado de los mapas actuales

`media/mapas/`, producidos por `scripts/09_mapas.R`:

| Mapa | Falta |
|---|---|
| `mapa_bivariado_vehiculos.png` | Leyenda al pie completa; fuente de los datos y de la geometría; proyección; barra de escala y norte; explicación del gris |
| `mapa_riesgo_folato.png` | Título o numeración; fuente de los datos y de la geometría; proyección; barra de escala y norte |
| `mapa_densidad_folato.png` | Lo mismo, y la condición de uso del criterio de densidad por nutriente |

## Orden de aplicación

Después de E3. Son mejoras de presentación sobre figuras cuyo contenido ya está
decidido, de modo que no bloquean el informe: se aplican una vez y sirven a los
tres entregables. Hacerlas antes competiría con el contenido, que es lo que se
evalúa.
