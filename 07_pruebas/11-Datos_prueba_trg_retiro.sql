SET SERVEROUTPUT ON;

-- ===================================
-- PRUEBA 1: Retiro exitoso
-- ===================================
DECLARE
    v_tipo_retiro NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== PRUEBA 1: Retiro exitoso =====');
    
    -- Obtener ID del tipo RETIRO (VALOR = 11)
    SELECT TIPO_PARAMETRO_ID INTO v_tipo_retiro
    FROM PROYECTODB.TBL_TIPOS_PARAMETROS
    WHERE NOMBRE = 'TIPO_TRANSACCION' AND VALOR = 11;
    
    INSERT INTO PROYECTODB.TBL_TRANSACCIONES (
        TRANSACCION_ID, CUENTA_ID, TIPO_TRANSAC_ID, MONTO, FECHA_TRANSAC
    ) VALUES (
        PROYECTODB.SEQ_TRANSACCION.NEXTVAL, 'CTA-0001', v_tipo_retiro, 100000, SYSDATE
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ Prueba exitosa');
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
END;
/

-- ===================================
-- PRUEBA 2: Retiro con saldo insuficiente
-- ===================================
DECLARE
    v_tipo_retiro NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== PRUEBA 2: Saldo insuficiente =====');
    
    SELECT TIPO_PARAMETRO_ID INTO v_tipo_retiro
    FROM PROYECTODB.TBL_TIPOS_PARAMETROS
    WHERE NOMBRE = 'TIPO_TRANSACCION' AND VALOR = 11;
    
    INSERT INTO PROYECTODB.TBL_TRANSACCIONES (
        TRANSACCION_ID, CUENTA_ID, TIPO_TRANSAC_ID, MONTO, FECHA_TRANSAC
    ) VALUES (
        PROYECTODB.SEQ_TRANSACCION.NEXTVAL, 'CTA-0001', v_tipo_retiro, 999999999, SYSDATE
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('❌ ERROR: Este retiro debió fallar');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✅ Retiro bloqueado correctamente');
        DBMS_OUTPUT.PUT_LINE('   Razón: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
END;
/