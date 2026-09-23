
SELECT COUNT(*) AS total_traspaso FROM traspaso;

TRUNCATE TABLE tiposensenanza_establecimientos CASCADE;

INSERT INTO tiposensenanza_establecimientos (codigo_ens_tiposensenanza, rbd_establecimientos, codigoramaeducacional)
SELECT DISTINCT 
    CAST(TRIM(t.codigo_ens) AS INTEGER),
    CAST(TRIM(t.rbd) AS INTEGER),
    TRIM(t.rama_educacional)
FROM traspaso t
WHERE t.rbd IS NOT NULL 
  AND TRIM(t.rbd) ~ '^[0-9]+$'
  AND t.codigo_ens IS NOT NULL 
  AND TRIM(t.codigo_ens) ~ '^[0-9]+$'
  AND t.rama_educacional IS NOT NULL 
  AND TRIM(t.rama_educacional) <> ''
  AND CAST(TRIM(t.rbd) AS INTEGER) IN (SELECT rbd FROM establecimientos)
  AND CAST(TRIM(t.codigo_ens) AS INTEGER) IN (SELECT codigo_ens FROM tiposensenanza)
  AND TRIM(t.rama_educacional) IN (SELECT codigoramaeducacional FROM ramaseducacionales)
ON CONFLICT (codigo_ens_tiposensenanza, rbd_establecimientos, codigoramaeducacional) 
DO NOTHING;

SELECT 'dependencias' AS tabla, COUNT(*) AS total FROM dependencias
UNION ALL
SELECT 'establecimientos' AS tabla, COUNT(*) AS total FROM establecimientos
UNION ALL
SELECT 'postulantes' AS tabla, COUNT(*) AS total FROM postulantes
UNION ALL
SELECT 'provincias' AS tabla, COUNT(*) AS total FROM provincias
UNION ALL
SELECT 'pruebas' AS tabla, COUNT(*) AS total FROM pruebas
UNION ALL
SELECT 'puntajes_maximos' AS tabla, COUNT(*) AS total FROM puntajes_maximos
UNION ALL
SELECT 'puntajesrendicionespruebasalumnos' AS tabla, COUNT(*) AS total FROM puntajesrendicionespruebasalumnos
UNION ALL
SELECT 'ramaseducacionales' AS tabla, COUNT(*) AS total FROM ramaseducacionales
UNION ALL
SELECT 'regiones' AS tabla, COUNT(*) AS total FROM regiones
UNION ALL
SELECT 'rendicionespruebas' AS tabla, COUNT(*) AS total FROM rendicionespruebas
UNION ALL
SELECT 'sexos' AS tabla, COUNT(*) AS total FROM sexos
UNION ALL
SELECT 'tiposensenanza' AS tabla, COUNT(*) AS total FROM tiposensenanza
UNION ALL
SELECT 'tiposensenanza_establecimientos' AS tabla, COUNT(*) AS total FROM tiposensenanza_establecimientos
UNION ALL
SELECT 'traspaso' AS tabla, COUNT(*) AS total FROM traspaso
ORDER BY tabla;