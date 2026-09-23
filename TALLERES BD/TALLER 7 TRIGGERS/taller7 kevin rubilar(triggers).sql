-- funcion 1 para validar que los puntajes sean proporcionales
create or replace function fn_validar_ranking()
returns trigger as $$
declare
    v_errores integer;
begin
    -- buscamos si existe algun companero en el mismo colegio que rompa la regla
    -- la regla dice que el porcentaje es inversamente proporcional al ranking
    select count(*) into v_errores from postulantes
    where rdb = new.rdb
      and (
          -- error 1 tiene mejor porcentaje numericamente menor pero peor puntaje
          (porc_sup_not < new.porc_sup_not and ptjeranking < new.ptjeranking) or
          -- error 2 tiene peor porcentaje numericamente mayor pero mejor puntaje
          (porc_sup_not > new.porc_sup_not and ptjeranking > new.ptjeranking) or
          -- error 3 tienen el mismo porcentaje exacto pero distinto puntaje
          (porc_sup_not = new.porc_sup_not and ptjeranking <> new.ptjeranking)
      );

    -- si pillamos al menos un error bloqueamos el ingreso lanzando una alerta
    if v_errores > 0 then
        raise exception 'el puntaje de ranking no es proporcional comparado con sus companeros';
    end if;

    -- si todo esta en orden dejamos que el alumno nuevo se guarde sin problemas
    return new;
end;
$$ language plpgsql;

-- creamos la alarma que dispara esta funcion justo antes de hacer un insert en la tabla
create trigger trg_validar_ranking
before insert on postulantes
for each row
execute procedure fn_validar_ranking();





-- primero creamos la tabla para guardar los promedios
create table puntajesxcolegios (
    rdb integer,
    prueba integer,
    promedio numeric(10,2),
    primary key (rdb, prueba)
);

-- funcion 2 que hace el calculo matematico de forma automatica
create or replace function fn_actualizar_promedios()
returns trigger as $$
declare
    v_mrut integer;
    v_idprueba integer;
    v_rdb integer;
    v_nuevo_promedio numeric;
begin
    -- identificamos al alumno dependiendo de si borraron actualizaron o insertaron su dato
    -- la variable tg_op guarda la accion exacta que disparo este trigger
    if tg_op = 'DELETE' then
        v_mrut := old.mrut;
        v_idprueba := old.idprueba;
    else
        v_mrut := new.mrut;
        v_idprueba := new.idprueba;
    end if;

    -- buscamos a que colegio pertenece este alumno en especifico
    select rdb into v_rdb from postulantes where mrut = v_mrut;

    -- recalculamos el promedio general de ese colegio para esa prueba juntando todos sus alumnos
    select avg(pr.puntaje) into v_nuevo_promedio
    from puntajesrendicionespruebasalumnos pr
    join postulantes p on pr.mrut = p.mrut
    where p.rdb = v_rdb and pr.idprueba = v_idprueba;

    -- si queda al menos un alumno en el colegio actualizamos o insertamos el dato en nuestra tabla
    if v_nuevo_promedio is not null then
        update puntajesxcolegios 
        set promedio = v_nuevo_promedio 
        where rdb = v_rdb and prueba = v_idprueba;
        
        -- si el update no encontro el registro significa que es primera vez que se calcula asi que lo insertamos
        if not found then
            insert into puntajesxcolegios (rdb, prueba, promedio)
            values (v_rdb, v_idprueba, v_nuevo_promedio);
        end if;
    else
        -- si el calculo da nulo es porque borraron al ultimo alumno de ese colegio asi que limpiamos el promedio
        delete from puntajesxcolegios where rdb = v_rdb and prueba = v_idprueba;
    end if;

    return null;
end;
$$ language plpgsql;

-- creamos el disparador para que reaccione despues de cualquier cambio que afecte los puntajes
create trigger trg_actualizar_promedios
after insert or update or delete on puntajesrendicionespruebasalumnos
for each row
execute procedure fn_actualizar_promedios();