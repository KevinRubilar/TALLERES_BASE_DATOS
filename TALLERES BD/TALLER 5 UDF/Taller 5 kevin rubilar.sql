--1. 

CREATE OR REPLACE FUNCTION fn_estadisticas_mrut(p_mrut INTEGER)
RETURNS VARCHAR AS $$
DECLARE
    v_veces INTEGER;
    v_puntaje_mayor INTEGER;
    v_promedio_menor NUMERIC;
BEGIN
    -- 1. Contar cuántas veces rindió la prueba y validar si existe
    SELECT COUNT(DISTINCT idrendicionprueba) INTO v_veces
    FROM puntajesrendicionespruebasalumnos
    WHERE mrut = p_mrut;

    -- Validar retorno
    IF v_veces = 0 THEN
        RETURN 'Error: El rut ingresado no tiene rendiciones registradas.';
    END IF;

    -- 2. Obtener el puntaje mayor histórico del estudiante
    SELECT MAX(puntaje) INTO v_puntaje_mayor
    FROM puntajesrendicionespruebasalumnos
    WHERE mrut = p_mrut;

    -- 3. Calcular el promedio entre pruebas 1 y 2
    SELECT MIN(promedio_rend) INTO v_promedio_menor
    FROM (
        SELECT idrendicionprueba, AVG(puntaje) AS promedio_rend
        FROM puntajesrendicionespruebasalumnos
        WHERE mrut = p_mrut AND idprueba IN (1, 2)
        GROUP BY idrendicionprueba
        HAVING COUNT(idprueba) = 2
    ) sub;

    -- 4. Retornar el texto concatenado
    RETURN 'Rendiciones: ' || v_veces || 
           ', Promedio PAES menor: ' || COALESCE(v_promedio_menor::VARCHAR, 'No aplica') || 
           ', Puntaje PAES mayor: ' || v_puntaje_mayor;
END;
$$ LANGUAGE plpgsql;

--2.

CREATE OR REPLACE FUNCTION fn_mejor_colegio_ubicacion(p_nombre VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    v_tipo VARCHAR;
    v_colegio VARCHAR;
    v_promedio NUMERIC;
    v_alumnos INTEGER;
BEGIN
    -- 1. Validar si el texto ingresado es Comuna, Provincia o Región
    IF EXISTS (SELECT 1 FROM comunas WHERE comuna = p_nombre) THEN
        v_tipo := 'Comuna';
    ELSIF EXISTS (SELECT 1 FROM provincias WHERE provincias = p_nombre) THEN
        v_tipo := 'Provincia';
    ELSIF EXISTS (SELECT 1 FROM regiones WHERE region = p_nombre) THEN
        v_tipo := 'Región';
    ELSE
        -- Retorna error si no existe la ubicación
        RETURN 'Error: La ubicación ingresada no existe en la base de datos.';
    END IF;

    -- 2. Buscar el colegio con el mejor promedio en esa ubicación
    SELECT 
        e.nombre_unidad_educativa,
        ROUND(AVG(pr.puntaje), 0),
        COUNT(DISTINCT p.mrut)
    INTO 
        v_colegio, v_promedio, v_alumnos
    FROM establecimientos e
    JOIN postulantes p ON e.rbd = p.rdb
    JOIN puntajesrendicionespruebasalumnos pr ON p.mrut = pr.mrut
    JOIN comunas c ON e.codigocomuna = c.codigocomuna
    JOIN provincias pv ON c.codigoprovincia = pv.codigoprovincia
    JOIN regiones r ON pv.codigoregion = r.codigoregion
    WHERE pr.idprueba IN (1, 2)
      AND (
          (v_tipo = 'Comuna' AND c.comuna = p_nombre) OR
          (v_tipo = 'Provincia' AND pv.provincias = p_nombre) OR
          (v_tipo = 'Región' AND r.region = p_nombre)
      )
    GROUP BY e.rbd, e.nombre_unidad_educativa
    ORDER BY AVG(pr.puntaje) DESC
    LIMIT 1;

    -- 3. Validar si encontró algún colegio con alumnos que rindieron la PAES
    IF v_colegio IS NULL THEN
        RETURN 'Error: No se encontraron colegios con rendiciones en esa ubicación.';
    END IF;

    RETURN v_tipo || ': ' || p_nombre || ', Colegio: ' || v_colegio || ', Promedio PAES: ' || v_promedio || ' , Alumnos: ' || v_alumnos;
END;
$$ LANGUAGE plpgsql;
