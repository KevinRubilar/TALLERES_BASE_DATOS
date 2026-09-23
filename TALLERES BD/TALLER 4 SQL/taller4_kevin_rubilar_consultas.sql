--consulta 1
SELECT 
    idprueba,
    COUNT(mrut) AS cantidad_estudiantes
FROM puntajesrendicionespruebasalumnos
WHERE idrendicionprueba = (
    SELECT MAX(idrendicionprueba) 
    FROM puntajesrendicionespruebasalumnos
)
AND puntaje > (
    SELECT AVG(puntaje)
    FROM puntajesrendicionespruebasalumnos p2
    WHERE p2.idprueba = puntajesrendicionespruebasalumnos.idprueba
      AND p2.idrendicionprueba = puntajesrendicionespruebasalumnos.idrendicionprueba
)
GROUP BY idprueba;



-- consulta 2


SELECT idprueba, mrut, puntaje FROM puntajesrendicionespruebasalumnos 
WHERE idprueba = 1 
AND puntaje = (
    SELECT MAX(puntaje) FROM puntajesrendicionespruebasalumnos 
    WHERE idprueba = 1 AND mrut IN (
        SELECT mrut FROM puntajesrendicionespruebasalumnos WHERE idprueba = 1 GROUP BY mrut HAVING COUNT(idrendicionprueba) >= ALL (SELECT COUNT(idrendicionprueba) FROM puntajesrendicionespruebasalumnos WHERE idprueba = 1 GROUP BY mrut)
    )
)
AND mrut IN (
    SELECT mrut FROM puntajesrendicionespruebasalumnos WHERE idprueba = 1 GROUP BY mrut HAVING COUNT(idrendicionprueba) >= ALL (SELECT COUNT(idrendicionprueba) FROM puntajesrendicionespruebasalumnos WHERE idprueba = 1 GROUP BY mrut)
)

UNION ALL


SELECT idprueba, mrut, puntaje FROM puntajesrendicionespruebasalumnos 
WHERE idprueba = 2 
AND puntaje = (
    SELECT MAX(puntaje) FROM puntajesrendicionespruebasalumnos 
    WHERE idprueba = 2 AND mrut IN (
        SELECT mrut FROM puntajesrendicionespruebasalumnos WHERE idprueba = 2 GROUP BY mrut HAVING COUNT(idrendicionprueba) >= ALL (SELECT COUNT(idrendicionprueba) FROM puntajesrendicionespruebasalumnos WHERE idprueba = 2 GROUP BY mrut)
    )
)
AND mrut IN (
    SELECT mrut FROM puntajesrendicionespruebasalumnos WHERE idprueba = 2 GROUP BY mrut HAVING COUNT(idrendicionprueba) >= ALL (SELECT COUNT(idrendicionprueba) FROM puntajesrendicionespruebasalumnos WHERE idprueba = 2 GROUP BY mrut)
)

UNION ALL


SELECT idprueba, mrut, puntaje FROM puntajesrendicionespruebasalumnos 
WHERE idprueba = 3 
AND puntaje = (
    SELECT MAX(puntaje) FROM puntajesrendicionespruebasalumnos 
    WHERE idprueba = 3 AND mrut IN (
        SELECT mrut FROM puntajesrendicionespruebasalumnos WHERE idprueba = 3 GROUP BY mrut HAVING COUNT(idrendicionprueba) >= ALL (SELECT COUNT(idrendicionprueba) FROM puntajesrendicionespruebasalumnos WHERE idprueba = 3 GROUP BY mrut)
    )
)
AND mrut IN (
    SELECT mrut FROM puntajesrendicionespruebasalumnos WHERE idprueba = 3 GROUP BY mrut HAVING COUNT(idrendicionprueba) >= ALL (SELECT COUNT(idrendicionprueba) FROM puntajesrendicionespruebasalumnos WHERE idprueba = 3 GROUP BY mrut)
)

UNION ALL


SELECT idprueba, mrut, puntaje FROM puntajesrendicionespruebasalumnos 
WHERE idprueba = 4 
AND puntaje = (
    SELECT MAX(puntaje) FROM puntajesrendicionespruebasalumnos 
    WHERE idprueba = 4 AND mrut IN (
        SELECT mrut FROM puntajesrendicionespruebasalumnos WHERE idprueba = 4 GROUP BY mrut HAVING COUNT(idrendicionprueba) >= ALL (SELECT COUNT(idrendicionprueba) FROM puntajesrendicionespruebasalumnos WHERE idprueba = 4 GROUP BY mrut)
    )
)
AND mrut IN (
    SELECT mrut FROM puntajesrendicionespruebasalumnos WHERE idprueba = 4 GROUP BY mrut HAVING COUNT(idrendicionprueba) >= ALL (SELECT COUNT(idrendicionprueba) FROM puntajesrendicionespruebasalumnos WHERE idprueba = 4 GROUP BY mrut)
)

UNION ALL


SELECT idprueba, mrut, puntaje FROM puntajesrendicionespruebasalumnos 
WHERE idprueba = 5 
AND puntaje = (
    SELECT MAX(puntaje) FROM puntajesrendicionespruebasalumnos 
    WHERE idprueba = 5 AND mrut IN (
        SELECT mrut FROM puntajesrendicionespruebasalumnos WHERE idprueba = 5 GROUP BY mrut HAVING COUNT(idrendicionprueba) >= ALL (SELECT COUNT(idrendicionprueba) FROM puntajesrendicionespruebasalumnos WHERE idprueba = 5 GROUP BY mrut)
    )
)
AND mrut IN (
    SELECT mrut FROM puntajesrendicionespruebasalumnos WHERE idprueba = 5 GROUP BY mrut HAVING COUNT(idrendicionprueba) >= ALL (SELECT COUNT(idrendicionprueba) FROM puntajesrendicionespruebasalumnos WHERE idprueba = 5 GROUP BY mrut)
);

--consulta 3

SELECT mrut, AVG(puntaje) AS promedio
INTO tabla_promedios
FROM puntajesrendicionespruebasalumnos
WHERE idprueba IN (1, 2)
  AND idrendicionprueba = (
      SELECT MAX(idrendicionprueba) 
      FROM puntajesrendicionespruebasalumnos
  )
GROUP BY mrut
HAVING COUNT(idprueba) = 2;

SELECT promedio AS moda_estadistica
FROM tabla_promedios
GROUP BY promedio
HAVING COUNT(mrut) >= ALL (
    SELECT COUNT(mrut)
    FROM tabla_promedios
    GROUP BY promedio
);