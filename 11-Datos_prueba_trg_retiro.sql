-- =======================================
-- SCRIPT DE PRUEBAS: TRG_VALIDA_TRANSACCION_RETIRO
-- =======================================

SET SERVEROUTPUT ON;

-- =======================================
-- PREPARACIÓN: Verificar datos existentes
-- =======================================

-- Ver cuentas disponibles
SELECT 
    C.CUENTA_ID,
    CL.NOMBRE AS CLIENTE,
    TP_TIPO.NOMBRE AS TIPO_CUENTA,
    TP_ESTADO.NOMBRE AS ESTADO,
    C.SALDO
FROM PROYECTODB.TBL_CUENTAS C
JOIN PROYECTODB.TBL_CLIENTES CL ON C.CLIENTE_ID = CL.CLIENTE_ID
JOIN PROYECTODB.TBL_TIPOS_PARAMETROS TP_TIPO ON C.TIPO_CUENTA_ID = TP_TIPO.TIPO_PARAMETRO_ID
JOIN PROYECTODB.TBL_TIPOS_PARAMETROS TP_ESTADO ON C.ESTADO_ID = TP_ESTADO.TIPO_PARAMETRO_ID
ORDER BY C.CUENTA_ID;

-- Ver tipos de transacción
SELECT 
    TIPO_PARAMETRO_ID,
    NOMBRE,
    DESCRIPCION
FROM PROYECTODB.TBL_TIPOS_PARAMETROS
WHERE VALOR = 3  -- Tipos de transacción
ORDER BY TIPO_PARAMETRO_ID;



-- =======================================
-- PRUEBA 1: Retiro EXITOSO (válido)
-- =======================================
DECLARE
    v_tipo_retiro NUMBER;
    v_transaccion_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== PRUEBA 1: Retiro exitoso =====');
    
    -- Obtener ID del tipo RETIRO
    SELECT TIPO_PARAMETRO_ID INTO v_tipo_retiro
    FROM PROYECTODB.TBL_TIPOS_PARAMETROS
    WHERE UPPER(NOMBRE) = 'RETIRO' AND VALOR = 3;
    
    DBMS_OUTPUT.PUT_LINE('Intentando retiro de $100,000 en cuenta CTA-0001...');
    
    -- Insertar retiro válido
    INSERT INTO PROYECTODB.TBL_TRANSACCIONES (
        TRANSACCION_ID,
        CUENTA_ID,
        TIPO_TRANSAC_ID,
        MONTO,
        FECHA_TRANSAC
    ) VALUES (
        PROYECTODB.SEQ_TRANSACCION.NEXTVAL,
        'CTA-0001',
        v_tipo_retiro,
        100000,
        SYSDATE
    )
    RETURNING TRANSACCION_ID INTO v_transaccion_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Retiro exitoso. Transacción ID: ' || v_transaccion_id);
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
END;
/


-- =======================================
-- PRUEBA 2: Retiro con SALDO INSUFICIENTE
-- =======================================
DECLARE
    v_tipo_retiro NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== PRUEBA 2: Saldo insuficiente =====');
    
    SELECT TIPO_PARAMETRO_ID INTO v_tipo_retiro
    FROM PROYECTODB.TBL_TIPOS_PARAMETROS
    WHERE UPPER(NOMBRE) = 'RETIRO' AND VALOR = 3;
    
    DBMS_OUTPUT.PUT_LINE('Intentando retiro de $999,999,999 en cuenta CTA-0001...');
    
    -- Intentar retiro mayor al saldo
    INSERT INTO PROYECTODB.TBL_TRANSACCIONES (
        TRANSACCION_ID,
        CUENTA_ID,
        TIPO_TRANSAC_ID,
        MONTO,
        FECHA_TRANSAC
    ) VALUES (
        PROYECTODB.SEQ_TRANSACCION.NEXTVAL,
        'CTA-0001',
        v_tipo_retiro,
        999999999,
        SYSDATE
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERROR: Este retiro debió fallar');
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Retiro bloqueado correctamente');
        DBMS_OUTPUT.PUT_LINE('   Razón: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
END;
/


-- =======================================
-- PRUEBA 3: Retiro en CUENTA INACTIVA
-- =======================================
DECLARE
    v_tipo_retiro NUMBER;
    v_estado_inactiva NUMBER;
    v_cuenta_inactiva VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== PRUEBA 3: Cuenta inactiva =====');
    
    -- Buscar una cuenta inactiva o crear una temporal
    BEGIN
        SELECT CUENTA_ID INTO v_cuenta_inactiva
        FROM PROYECTODB.TBL_CUENTAS C
        JOIN PROYECTODB.TBL_TIPOS_PARAMETROS TP ON C.ESTADO_ID = TP.TIPO_PARAMETRO_ID
        WHERE UPPER(TP.NOMBRE) = 'INACTIVA'
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Si no hay cuenta inactiva, cambiar una temporalmente
            SELECT TIPO_PARAMETRO_ID INTO v_estado_inactiva
            FROM PROYECTODB.TBL_TIPOS_PARAMETROS
            WHERE UPPER(NOMBRE) = 'INACTIVA' AND VALOR = 2;
            
            -- Usar CTA-0005 (cambiarla a inactiva temporalmente)
            v_cuenta_inactiva := 'CTA-0005';
            UPDATE PROYECTODB.TBL_CUENTAS
            SET ESTADO_ID = v_estado_inactiva
            WHERE CUENTA_ID = v_cuenta_inactiva;
            COMMIT;
            
            DBMS_OUTPUT.PUT_LINE('   (Cuenta ' || v_cuenta_inactiva || ' cambiada a INACTIVA temporalmente)');
    END;
    
    SELECT TIPO_PARAMETRO_ID INTO v_tipo_retiro
    FROM PROYECTODB.TBL_TIPOS_PARAMETROS
    WHERE UPPER(NOMBRE) = 'RETIRO' AND VALOR = 3;
    
    DBMS_OUTPUT.PUT_LINE('Intentando retiro en cuenta ' || v_cuenta_inactiva || ' (INACTIVA)...');
    
    -- Intentar retiro en cuenta inactiva
    INSERT INTO PROYECTODB.TBL_TRANSACCIONES (
        TRANSACCION_ID,
        CUENTA_ID,
        TIPO_TRANSAC_ID,
        MONTO,
        FECHA_TRANSAC
    ) VALUES (
        PROYECTODB.SEQ_TRANSACCION.NEXTVAL,
        v_cuenta_inactiva,
        v_tipo_retiro,
        50000,
        SYSDATE
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERROR: Este retiro debió fallar');
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Retiro bloqueado correctamente');
        DBMS_OUTPUT.PUT_LINE('   Razón: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
END;
/


-- =======================================
-- PRUEBA 4: Cuenta INEXISTENTE
-- =======================================
DECLARE
    v_tipo_retiro NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== PRUEBA 4: Cuenta inexistente =====');
    
    SELECT TIPO_PARAMETRO_ID INTO v_tipo_retiro
    FROM PROYECTODB.TBL_TIPOS_PARAMETROS
    WHERE UPPER(NOMBRE) = 'RETIRO' AND VALOR = 3;
    
    DBMS_OUTPUT.PUT_LINE('Intentando retiro en cuenta CTA-9999 (no existe)...');
    
    -- Intentar retiro en cuenta que no existe
    INSERT INTO PROYECTODB.TBL_TRANSACCIONES (
        TRANSACCION_ID,
        CUENTA_ID,
        TIPO_TRANSAC_ID,
        MONTO,
        FECHA_TRANSAC
    ) VALUES (
        PROYECTODB.SEQ_TRANSACCION.NEXTVAL,
        'CTA-9999',
        v_tipo_retiro,
        100000,
        SYSDATE
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERROR: Este retiro debió fallar');
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Retiro bloqueado correctamente');
        DBMS_OUTPUT.PUT_LINE('   Razón: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
END;
/


-- =======================================
-- PRUEBA 5: Tipo de transacción INVÁLIDO
-- =======================================
DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== PRUEBA 5: Tipo de transacción inválido =====');
    
    DBMS_OUTPUT.PUT_LINE('Intentando transacción con tipo_transac_id = 9999 (no existe)...');
    
    -- Intentar con tipo de transacción que no existe
    INSERT INTO PROYECTODB.TBL_TRANSACCIONES (
        TRANSACCION_ID,
        CUENTA_ID,
        TIPO_TRANSAC_ID,
        MONTO,
        FECHA_TRANSAC
    ) VALUES (
        PROYECTODB.SEQ_TRANSACCION.NEXTVAL,
        'CTA-0001',
        9999,
        100000,
        SYSDATE
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERROR: Esta transacción debió fallar');
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Transacción bloqueada correctamente');
        DBMS_OUTPUT.PUT_LINE('   Razón: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
END;
/


-- =======================================
-- PRUEBA 6: DEPÓSITO (NO debe validarse)
-- =======================================
DECLARE
    v_tipo_deposito NUMBER;
    v_transaccion_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== PRUEBA 6: Depósito (no se valida) =====');
    
    SELECT TIPO_PARAMETRO_ID INTO v_tipo_deposito
    FROM PROYECTODB.TBL_TIPOS_PARAMETROS
    WHERE UPPER(NOMBRE) = 'DEPOSITO' AND VALOR = 3;
    
    DBMS_OUTPUT.PUT_LINE('Realizando depósito de $500,000 en cuenta CTA-0001...');
    
    -- Insertar depósito (no debe validarse)
    INSERT INTO PROYECTODB.TBL_TRANSACCIONES (
        TRANSACCION_ID,
        CUENTA_ID,
        TIPO_TRANSAC_ID,
        MONTO,
        FECHA_TRANSAC
    ) VALUES (
        PROYECTODB.SEQ_TRANSACCION.NEXTVAL,
        'CTA-0001',
        v_tipo_deposito,
        500000,
        SYSDATE
    )
    RETURNING TRANSACCION_ID INTO v_transaccion_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Depósito exitoso (no requiere validación)');
    DBMS_OUTPUT.PUT_LINE('   Transacción ID: ' || v_transaccion_id);
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
END;
/


-- =======================================
-- TRANSACCIONES CREADAS
-- =======================================

SELECT 
    T.TRANSACCION_ID,
    T.CUENTA_ID,
    TP.NOMBRE AS TIPO_TRANSACCION,
    T.MONTO,
    TO_CHAR(T.FECHA_TRANSAC, 'DD/MM/YYYY HH24:MI:SS') AS FECHA
FROM PROYECTODB.TBL_TRANSACCIONES T
JOIN PROYECTODB.TBL_TIPOS_PARAMETROS TP ON T.TIPO_TRANSAC_ID = TP.TIPO_PARAMETRO_ID
ORDER BY T.FECHA_TRANSAC DESC
FETCH FIRST 10 ROWS ONLY;

//////////////////////////////////////////////////////////////////////////////////////////////////////