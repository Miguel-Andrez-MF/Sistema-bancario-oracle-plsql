-- =======================================
-- PROCEDIMIENTO: Registrar errores
-- =======================================
CREATE OR REPLACE PROCEDURE PROYECTODB.PRC_LOG_ERROR(
    p_origen IN VARCHAR2,
    p_mensaje IN VARCHAR2
) IS
    PRAGMA AUTONOMOUS_TRANSACTION; -- Esto guarda el log aunque haya ROLLBACK
BEGIN
    INSERT INTO PROYECTODB.TBL_LOG_ERRORES (ORIGEN, MENSAJE_ERROR)
    VALUES (p_origen, SUBSTR(p_mensaje, 1, 4000));
    -- ↑ No necesitas poner LOG_ID ni FECHA_ERROR (se generan automáticamente)

    COMMIT; -- Guarda el log inmediatamente

EXCEPTION
    WHEN OTHERS THEN
        -- Si falla el log, no romper el sistema
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error al registrar log: ' || SQLERRM);
END;
/

