-- FUNCION 1

CREATE OR REPLACE FUNCTION ListaPuntajes(
    arg_mrut INTEGER,
    arg_fecha_nac DATE,
    arg_ano_egreso DATE,
    arg_colegio VARCHAR,
    arg_comuna VARCHAR
)
-- definimos la tabla virtual que va a retornar la función con sus respectivas columnas
RETURNS TABLE (
    nombre_unidad_educativa VARCHAR,
    comuna VARCHAR,
    mrut INTEGER,
    fecha_nacimiento DATE,
    ano_egreso DATE,
    puntaje_lectora INTEGER,
    puntaje_mate1 INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.nombre_unidad_educativa,
        c.comuna,
        p.mrut,
        p.fecha_nacimiento,
        p.anoegreso,
        -- evaluamos si la prueba es la 1 (lectora) y guardamos su puntaje en esta columna
        MAX(CASE WHEN pr.idprueba = 1 THEN pr.puntaje END)::INTEGER AS puntaje_lectora,
        -- evaluamos si la prueba es la 2 (mate 1) y guardamos su puntaje en esta columna
        MAX(CASE WHEN pr.idprueba = 2 THEN pr.puntaje END)::INTEGER AS puntaje_mate1
    FROM postulantes p
    JOIN establecimientos e ON p.rdb = e.rbd
    JOIN comunas c ON e.codigocomuna = c.codigocomuna
    -- usamos LEFT JOIN para no perder al alumno si es que no rindio la prueba
    -- ademas, con la subconsulta nos aseguramos de cruzar solo con la ultima rendicion registrada
    LEFT JOIN puntajesrendicionespruebasalumnos pr 
           ON p.mrut = pr.mrut AND pr.idrendicionprueba = (SELECT MAX(idrendicionprueba) FROM rendicionespruebas)

    -- si el parametro viene nulo (IS NULL), la condicion da verdadero y no filtra nada
    -- si el parametro trae un dato, entonces obliga a que la columna sea igual a ese dato
    WHERE (arg_mrut IS NULL OR p.mrut = arg_mrut)
      AND (arg_fecha_nac IS NULL OR p.fecha_nacimiento = arg_fecha_nac)
      AND (arg_ano_egreso IS NULL OR p.anoegreso = arg_ano_egreso)
      AND (arg_colegio IS NULL OR e.nombre_unidad_educativa = arg_colegio)
      AND (arg_comuna IS NULL OR c.comuna = arg_comuna)
    -- agrupamos por los datos basicos del postulante para colapsar las filas y evitar duplicados
    GROUP BY 
        e.nombre_unidad_educativa, c.comuna, p.mrut, p.fecha_nacimiento, p.anoegreso;
END;
$$ LANGUAGE plpgsql;



-- FUNCION 2

create or replace function promedioxcomuna(arg_comuna varchar)
-- se define la estructura de la tabla final que va a devolver la funcion
returns table (
    nombre_colegio varchar,
    cantidad_alumnos integer,
    promedio_paes numeric(10,2), -- fijamos los decimales aqui para no usar la funcion round
    desviacion_estandar numeric(10,2)
) as $$
declare
    -- cursor 1  buscador de colegios 
    -- busca todos los colegios que pertenecen a la comuna ingresada
    c_colegios cursor for 
        select e.rbd, e.nombre_unidad_educativa 
        from establecimientos e
        join comunas c on e.codigocomuna = c.codigocomuna
        where c.comuna = arg_comuna;
        
    -- cursor 2 nuestra lista de alumnos por colegio
    -- recibe el rbd del colegio como parametro para buscar solo a sus alumnos
    c_alumnos cursor (p_rbd integer) for
        select pr1.puntaje as lec, pr2.puntaje as mat
        from postulantes p
        -- se unen los puntajes de comprension lectora 1
        join puntajesrendicionespruebasalumnos pr1 on p.mrut = pr1.mrut and pr1.idprueba = 1
        -- se unen los puntajes de matematica 1
        join puntajesrendicionespruebasalumnos pr2 on p.mrut = pr2.mrut and pr2.idprueba = 2
        where p.rdb = p_rbd 
          -- para la ultima rendicion se usa order by y limit 1 para evitar usar la funcion max 
          and pr1.idrendicionprueba = (select idrendicionprueba from rendicionespruebas order by idrendicionprueba desc limit 1)
          and pr2.idrendicionprueba = (select idrendicionprueba from rendicionespruebas order by idrendicionprueba desc limit 1);
          
    -- variables para guardar temporalmente los datos que lee el cursor
    v_rbd integer;
    v_nombre varchar;
    v_lec integer;
    v_mat integer;
    v_prom_alumno numeric;
    
    -- variables para hacer los calculos matematicos sin funciones de postgres
    v_n integer;
    v_sum numeric;
    v_sum2 numeric;
    v_avg numeric;
    v_var numeric;
    v_stddev numeric;
begin
    open c_colegios; -- abrimos el buscador de colegios
    loop
        fetch c_colegios into v_rbd, v_nombre; -- leemos el colegio actual
        exit when not found; -- si ya no hay mas colegios salimos del ciclo general
        
        -- reiniciamos las calculadoras a cero antes de contar a los alumnos de este colegio nuevo
        v_n := 0;
        v_sum := 0;
        v_sum2 := 0;
        
        open c_alumnos(v_rbd); -- abrimos la lista de alumnos de este colegio especifico
        loop
            fetch c_alumnos into v_lec, v_mat; -- leemos los puntajes del alumno actual
            exit when not found; -- si ya no hay mas alumnos en este colegio terminamos de contar
            
            -- matematica manual sin avg ni count
            -- 1 calculamos el promedio personal del alumno lectora mas mate 1 divido 2
            v_prom_alumno := (v_lec + v_mat) / 2.0;
            
            -- 2 simulamos la funcion count sumando 1 por cada alumno que leemos
            v_n := v_n + 1; 
            
            -- 3  acumulamos la suma de todos los promedios para luego sacar el promedio general del colegio
            v_sum := v_sum + v_prom_alumno; 
            
            -- 4 acumulamos la suma de los promedios al cuadrado 
            v_sum2 := v_sum2 + (v_prom_alumno * v_prom_alumno); 
        end loop;
        close c_alumnos; -- cerramos la lista de alumnos de este colegio
        
        -- si el colegio tuvo al menos 1 alumno que dio las pruebas hacemos los calculos finales
        if v_n > 0 then
            -- simulamos la funcion avg suma total dividida en la cantidad de alumnos
            v_avg := v_sum / v_n; 
            
            if v_n > 1 then
                -- calculamos la varianza poblacional suma de cuadrados dividido en cantidad menos promedio general al cuadrado
                v_var := (v_sum2 / v_n) - (v_avg * v_avg);
                
                --  si por problemas de decimales la varianza da un numero infimamente negativo lo dejamos en 0
                if v_var < 0 then v_var := 0; end if; 
                
                -- elevamos a 0.5 que es igual a sacar la raiz cuadrada
                v_stddev := v_var ^ 0.5; 
            else
                -- si hay solo 1 alumno no hay desviacion estandar
                v_stddev := 0;
            end if;
            
            -- traspasamos los resultados manuales a las columnas de la tabla final que escupira la funcion
            nombre_colegio := v_nombre;
            cantidad_alumnos := v_n;
            promedio_paes := v_avg::numeric(10,2);
            desviacion_estandar := v_stddev::numeric(10,2);
            
            -- return next guarda este colegio en la tabla de resultados y el loop sigue con el proximo colegio
            return next; 
        end if;
        
    end loop;
    close c_colegios; -- cerramos el buscador de colegios
end;
$$ language plpgsql;