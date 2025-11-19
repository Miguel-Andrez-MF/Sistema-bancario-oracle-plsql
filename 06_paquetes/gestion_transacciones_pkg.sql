-- =======================================
-- PAQUETE: gestion_transacciones_pkg (SPEC)
-- Descripción: Gestión completa de transacciones bancarias
-- =======================================

CREATE OR REPLACE PACKAGE PROYECTODB.gestion_transacciones_pkg AS

    -- ====================================
    -- PROCEDIMIENTO: Realizar Depósito
    -- ====================================
    PROCEDURE realizar_deposito(
        p_cuenta_id IN VARCHAR2,
        p_monto IN NUMBER,
        p_usuario_id IN NUMBER,
        p_transaccion_id OUT NUMBER,
        p_resultado OUT VARCHAR2
    );

    -- ====================================
    -- PROCEDIMIENTO: Realizar Retiro
    -- ====================================
    PROCEDURE realizar_retiro(
        p_cuenta_id IN VARCHAR2,
        p_monto IN NUMBER,
        p_usuario_id IN NUMBER,
        p_transaccion_id OUT NUMBER,
        p_resultado OUT VARCHAR2
    );

    -- ====================================
    -- PROCEDIMIENTO: Realizar Transferencia (ATÓMICO)
    -- ====================================
    PROCEDURE realizar_transferencia(
        p_cuenta_origen IN VARCHAR2,
        p_cuenta_destino IN VARCHAR2,
        p_monto IN NUMBER,
        p_usuario_id IN NUMBER,
        p_transaccion_id OUT NUMBER,
        p_resultado OUT VARCHAR2
    );

    -- ====================================
    -- FUNCIÓN: Consultar Saldo
    -- ====================================
    FUNCTION consultar_saldo(
        p_cuenta_id IN VARCHAR2
    ) RETURN NUMBER;

    -- ====================================
    -- FUNCIÓN: Generar Historial de Transacciones
    -- ====================================
    FUNCTION generar_historial(
        p_cuenta_id IN VARCHAR2,
        p_fecha_inicio IN DATE DEFAULT NULL,
        p_fecha_fin IN DATE DEFAULT NULL
    ) RETURN SYS_REFCURSOR;

    -- ====================================
    -- PROCEDIMIENTO: Consultar Últimas Transacciones
    -- ====================================
    PROCEDURE consultar_ultimas_transacciones(
        p_cuenta_id IN VARCHAR2,
        p_cantidad IN NUMBER DEFAULT 10
    );

END gestion_transacciones_pkg;
/


-- =======================================
-- PAQUETE: gestion_transacciones_pkg (BODY)
-- =======================================

CREATE OR REPLACE PACKAGE BODY PROYECTODB.gestion_transacciones_pkg AS

    -- ====================================
    -- CONSTANTES PRIVADAS
    -- ====================================
    c_TIPO_DEPOSITO CONSTANT NUMBER := 10;
    c_TIPO_RETIRO CONSTANT NUMBER := 11;
    c_TIPO_TRANSFERENCIA CONSTANT NUMBER := 12;
    
    c_ESTADO_ACTIVA CONSTANT NUMBER := 1;
    c_ESTADO_INACTIVA CONSTANT NUMBER := 2;
    c_ESTADO_BLOQUEADA CONSTANT NUMBER := 3;

    -- ====================================
    -- FUNCIÓN PRIVADA: Obtener ID del tipo de transacción
    -- ====================================
    FUNCTION obtener_tipo_transaccion_id(
        p_valor IN NUMBER
    ) RETURN NUMBER IS
        v_tipo_id NUMBER;
    BEGIN
        SELECT TIPO_PARAMETRO_ID INTO v_tipo_id
        FROM TBL_TIPOS_PARAMETROS
        WHERE NOMBRE = 'TIPO_TRANSACCION' AND VALOR = p_valor;
        
        RETURN v_tipo_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20400, 'Tipo de transacción no encontrado');
    END;

    -- ====================================
    -- FUNCIÓN PRIVADA: Validar estado de cuenta
    -- ====================================
    FUNCTION validar_cuenta_activa(
        p_cuenta_id IN VARCHAR2
    ) RETURN BOOLEAN IS
        v_estado_valor NUMBER;
    BEGIN
        SELECT TP.VALOR INTO v_estado_valor
        FROM TBL_CUENTAS C
        JOIN TBL_TIPOS_PARAMETROS TP ON C.ESTADO_ID = TP.TIPO_PARAMETRO_ID
        WHERE C.CUENTA_ID = p_cuenta_id
        AND TP.NOMBRE = 'ESTADO';
        
        RETURN v_estado_valor = c_ESTADO_ACTIVA;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END;

    -- ====================================
    -- PROCEDIMIENTO: Realizar Depósito
    -- ====================================
    PROCEDURE realizar_deposito(
        p_cuenta_id IN VARCHAR2,
        p_monto IN NUMBER,
        p_usuario_id IN NUMBER,
        p_transaccion_id OUT NUMBER,
        p_resultado OUT VARCHAR2
    ) IS
        v_tipo_deposito_id NUMBER;
        v_saldo_anterior NUMBER;
        v_saldo_nuevo NUMBER;
    BEGIN
        -- Validaciones
        IF p_monto <= 0 THEN
            RAISE_APPLICATION_ERROR(-20401, 'El monto debe ser mayor a cero');
        END IF;

        -- Verificar que la cuenta existe y obtener saldo
        BEGIN
            SELECT SALDO INTO v_saldo_anterior
            FROM TBL_CUENTAS
            WHERE CUENTA_ID = p_cuenta_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20402, 'La cuenta no existe');
        END;

        -- Obtener ID del tipo depósito
        v_tipo_deposito_id := obtener_tipo_transaccion_id(c_TIPO_DEPOSITO);

        -- Insertar transacción
        INSERT INTO TBL_TRANSACCIONES (
            TRANSACCION_ID,
            CUENTA_ID,
            TIPO_TRANSAC_ID,
            MONTO,
            FECHA_TRANSAC
        ) VALUES (
            SEQ_TRANSACCION.NEXTVAL,
            p_cuenta_id,
            v_tipo_deposito_id,
            p_monto,
            SYSDATE
        ) RETURNING TRANSACCION_ID INTO p_transaccion_id;

        -- El trigger TRG_ACTUALIZA_SALDO se encarga de actualizar el saldo
        
        -- Obtener nuevo saldo
        SELECT SALDO INTO v_saldo_nuevo
        FROM TBL_CUENTAS
        WHERE CUENTA_ID = p_cuenta_id;

        COMMIT;

        p_resultado := 'EXITO: Depósito realizado. Saldo anterior: $' || 
                      TO_CHAR(v_saldo_anterior, 'FM999,999,999') || 
                      ' | Saldo nuevo: $' || 
                      TO_CHAR(v_saldo_nuevo, 'FM999,999,999');

        DBMS_OUTPUT.PUT_LINE('✓ ' || p_resultado);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_resultado := 'ERROR: ' || SQLERRM;
            DBMS_OUTPUT.PUT_LINE('✗ ' || p_resultado);
            RAISE;
    END realizar_deposito;

    -- ====================================
    -- PROCEDIMIENTO: Realizar Retiro
    -- ====================================
    PROCEDURE realizar_retiro(
        p_cuenta_id IN VARCHAR2,
        p_monto IN NUMBER,
        p_usuario_id IN NUMBER,
        p_transaccion_id OUT NUMBER,
        p_resultado OUT VARCHAR2
    ) IS
        v_tipo_retiro_id NUMBER;
        v_saldo_anterior NUMBER;
        v_saldo_nuevo NUMBER;
    BEGIN
        -- Validaciones
        IF p_monto <= 0 THEN
            RAISE_APPLICATION_ERROR(-20403, 'El monto debe ser mayor a cero');
        END IF;

        -- Verificar que la cuenta está activa
        IF NOT validar_cuenta_activa(p_cuenta_id) THEN
            RAISE_APPLICATION_ERROR(-20404, 'La cuenta no está activa');
        END IF;

        -- Obtener saldo actual
        SELECT SALDO INTO v_saldo_anterior
        FROM TBL_CUENTAS
        WHERE CUENTA_ID = p_cuenta_id;

        -- Validar saldo suficiente
        IF v_saldo_anterior < p_monto THEN
            RAISE_APPLICATION_ERROR(-20405, 
                'Saldo insuficiente. Disponible: $' || 
                TO_CHAR(v_saldo_anterior, 'FM999,999,999') ||
                ' | Solicitado: $' || 
                TO_CHAR(p_monto, 'FM999,999,999'));
        END IF;

        -- Obtener ID del tipo retiro
        v_tipo_retiro_id := obtener_tipo_transaccion_id(c_TIPO_RETIRO);

        -- Insertar transacción (el trigger valida y actualiza saldo)
        INSERT INTO TBL_TRANSACCIONES (
            TRANSACCION_ID,
            CUENTA_ID,
            TIPO_TRANSAC_ID,
            MONTO,
            FECHA_TRANSAC
        ) VALUES (
            SEQ_TRANSACCION.NEXTVAL,
            p_cuenta_id,
            v_tipo_retiro_id,
            p_monto,
            SYSDATE
        ) RETURNING TRANSACCION_ID INTO p_transaccion_id;

        -- Obtener nuevo saldo
        SELECT SALDO INTO v_saldo_nuevo
        FROM TBL_CUENTAS
        WHERE CUENTA_ID = p_cuenta_id;

        COMMIT;

        p_resultado := 'EXITO: Retiro realizado. Saldo anterior: $' || 
                      TO_CHAR(v_saldo_anterior, 'FM999,999,999') || 
                      ' | Saldo nuevo: $' || 
                      TO_CHAR(v_saldo_nuevo, 'FM999,999,999');

        DBMS_OUTPUT.PUT_LINE('✓ ' || p_resultado);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_resultado := 'ERROR: ' || SQLERRM;
            DBMS_OUTPUT.PUT_LINE('✗ ' || p_resultado);
            RAISE;
    END realizar_retiro;

    -- ====================================
    -- PROCEDIMIENTO: Realizar Transferencia (ATÓMICO)
    -- ====================================
    PROCEDURE realizar_transferencia(
        p_cuenta_origen IN VARCHAR2,
        p_cuenta_destino IN VARCHAR2,
        p_monto IN NUMBER,
        p_usuario_id IN NUMBER,
        p_transaccion_id OUT NUMBER,
        p_resultado OUT VARCHAR2
    ) IS
        v_tipo_transferencia_id NUMBER;
        v_tipo_deposito_id NUMBER;
        v_saldo_origen_anterior NUMBER;
        v_saldo_destino_anterior NUMBER;
        v_saldo_origen_nuevo NUMBER;
        v_saldo_destino_nuevo NUMBER;
        v_transaccion_deposito NUMBER;
    BEGIN
        -- Validaciones básicas
        IF p_monto <= 0 THEN
            RAISE_APPLICATION_ERROR(-20406, 'El monto debe ser mayor a cero');
        END IF;

        IF p_cuenta_origen = p_cuenta_destino THEN
            RAISE_APPLICATION_ERROR(-20407, 'No se puede transferir a la misma cuenta');
        END IF;

        -- Validar que ambas cuentas existen y están activas
        IF NOT validar_cuenta_activa(p_cuenta_origen) THEN
            RAISE_APPLICATION_ERROR(-20408, 'La cuenta origen no está activa');
        END IF;

        IF NOT validar_cuenta_activa(p_cuenta_destino) THEN
            RAISE_APPLICATION_ERROR(-20409, 'La cuenta destino no está activa');
        END IF;

        -- Obtener saldos actuales
        SELECT SALDO INTO v_saldo_origen_anterior
        FROM TBL_CUENTAS
        WHERE CUENTA_ID = p_cuenta_origen;

        SELECT SALDO INTO v_saldo_destino_anterior
        FROM TBL_CUENTAS
        WHERE CUENTA_ID = p_cuenta_destino;

        -- Validar saldo suficiente en origen
        IF v_saldo_origen_anterior < p_monto THEN
            RAISE_APPLICATION_ERROR(-20410, 
                'Saldo insuficiente en cuenta origen. Disponible: $' || 
                TO_CHAR(v_saldo_origen_anterior, 'FM999,999,999'));
        END IF;

        -- Obtener IDs de tipos de transacción
        v_tipo_transferencia_id := obtener_tipo_transaccion_id(c_TIPO_TRANSFERENCIA);
        v_tipo_deposito_id := obtener_tipo_transaccion_id(c_TIPO_DEPOSITO);

        -- =============================================
        -- OPERACIÓN ATÓMICA: Débito + Crédito
        -- =============================================
        
        -- 1. Registrar débito en cuenta origen (transferencia saliente)
        INSERT INTO TBL_TRANSACCIONES (
            TRANSACCION_ID,
            CUENTA_ID,
            TIPO_TRANSAC_ID,
            MONTO,
            FECHA_TRANSAC
        ) VALUES (
            SEQ_TRANSACCION.NEXTVAL,
            p_cuenta_origen,
            v_tipo_transferencia_id,
            p_monto,
            SYSDATE
        ) RETURNING TRANSACCION_ID INTO p_transaccion_id;

        -- El trigger TRG_ACTUALIZA_SALDO resta el monto de la cuenta origen

        -- 2. Registrar crédito en cuenta destino (depósito)
        INSERT INTO TBL_TRANSACCIONES (
            TRANSACCION_ID,
            CUENTA_ID,
            TIPO_TRANSAC_ID,
            MONTO,
            FECHA_TRANSAC
        ) VALUES (
            SEQ_TRANSACCION.NEXTVAL,
            p_cuenta_destino,
            v_tipo_deposito_id,
            p_monto,
            SYSDATE
        ) RETURNING TRANSACCION_ID INTO v_transaccion_deposito;

        -- El trigger TRG_ACTUALIZA_SALDO suma el monto a la cuenta destino

        -- Obtener saldos finales
        SELECT SALDO INTO v_saldo_origen_nuevo
        FROM TBL_CUENTAS
        WHERE CUENTA_ID = p_cuenta_origen;

        SELECT SALDO INTO v_saldo_destino_nuevo
        FROM TBL_CUENTAS
        WHERE CUENTA_ID = p_cuenta_destino;

        COMMIT;

        p_resultado := 'EXITO: Transferencia realizada.' || CHR(10) ||
                      'Origen (' || p_cuenta_origen || '): $' || 
                      TO_CHAR(v_saldo_origen_anterior, 'FM999,999,999') || ' → $' || 
                      TO_CHAR(v_saldo_origen_nuevo, 'FM999,999,999') || CHR(10) ||
                      'Destino (' || p_cuenta_destino || '): $' || 
                      TO_CHAR(v_saldo_destino_anterior, 'FM999,999,999') || ' → $' || 
                      TO_CHAR(v_saldo_destino_nuevo, 'FM999,999,999');

        DBMS_OUTPUT.PUT_LINE('✓ Transferencia exitosa');
        DBMS_OUTPUT.PUT_LINE('  Transacción débito: ' || p_transaccion_id);
        DBMS_OUTPUT.PUT_LINE('  Transacción crédito: ' || v_transaccion_deposito);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_resultado := 'ERROR: ' || SQLERRM;
            DBMS_OUTPUT.PUT_LINE('✗ ' || p_resultado);
            RAISE;
    END realizar_transferencia;

    -- ====================================
    -- FUNCIÓN: Consultar Saldo
    -- ====================================
    FUNCTION consultar_saldo(
        p_cuenta_id IN VARCHAR2
    ) RETURN NUMBER IS
        v_saldo NUMBER;
    BEGIN
        SELECT SALDO INTO v_saldo
        FROM TBL_CUENTAS
        WHERE CUENTA_ID = p_cuenta_id;

        RETURN v_saldo;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20411, 'La cuenta no existe');
        WHEN OTHERS THEN
            RAISE;
    END consultar_saldo;

    -- ====================================
    -- FUNCIÓN: Generar Historial de Transacciones
    -- ====================================
    FUNCTION generar_historial(
        p_cuenta_id IN VARCHAR2,
        p_fecha_inicio IN DATE DEFAULT NULL,
        p_fecha_fin IN DATE DEFAULT NULL
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
        v_fecha_inicio DATE;
        v_fecha_fin DATE;
    BEGIN
        -- Definir fechas por defecto si no se proporcionan
        v_fecha_inicio := NVL(p_fecha_inicio, ADD_MONTHS(SYSDATE, -3)); -- Últimos 3 meses
        v_fecha_fin := NVL(p_fecha_fin, SYSDATE);

        OPEN v_cursor FOR
            SELECT 
                T.TRANSACCION_ID,
                T.CUENTA_ID,
                TP.DESCRIPCION AS TIPO_TRANSACCION,
                T.MONTO,
                T.FECHA_TRANSAC,
                TO_CHAR(T.FECHA_TRANSAC, 'DD/MM/YYYY HH24:MI:SS') AS FECHA_FORMATEADA
            FROM TBL_TRANSACCIONES T
            JOIN TBL_TIPOS_PARAMETROS TP ON T.TIPO_TRANSAC_ID = TP.TIPO_PARAMETRO_ID
            WHERE T.CUENTA_ID = p_cuenta_id
            AND T.FECHA_TRANSAC BETWEEN v_fecha_inicio AND v_fecha_fin
            ORDER BY T.FECHA_TRANSAC DESC;

        RETURN v_cursor;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20412, 'Error al generar historial: ' || SQLERRM);
    END generar_historial;

    -- ====================================
    -- PROCEDIMIENTO: Consultar Últimas Transacciones
    -- ====================================
    PROCEDURE consultar_ultimas_transacciones(
        p_cuenta_id IN VARCHAR2,
        p_cantidad IN NUMBER DEFAULT 10
    ) IS
        v_contador NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('===== ÚLTIMAS ' || p_cantidad || ' TRANSACCIONES =====');
        DBMS_OUTPUT.PUT_LINE('Cuenta: ' || p_cuenta_id);
        DBMS_OUTPUT.PUT_LINE('');

        FOR rec IN (
            SELECT 
                T.TRANSACCION_ID,
                TP.DESCRIPCION AS TIPO,
                T.MONTO,
                TO_CHAR(T.FECHA_TRANSAC, 'DD/MM/YYYY HH24:MI:SS') AS FECHA
            FROM TBL_TRANSACCIONES T
            JOIN TBL_TIPOS_PARAMETROS TP ON T.TIPO_TRANSAC_ID = TP.TIPO_PARAMETRO_ID
            WHERE T.CUENTA_ID = p_cuenta_id
            ORDER BY T.FECHA_TRANSAC DESC
            FETCH FIRST p_cantidad ROWS ONLY
        ) LOOP
            v_contador := v_contador + 1;

            DBMS_OUTPUT.PUT_LINE('Transacción #' || v_contador);
            DBMS_OUTPUT.PUT_LINE('  ID: ' || rec.TRANSACCION_ID);
            DBMS_OUTPUT.PUT_LINE('  Tipo: ' || rec.TIPO);
            DBMS_OUTPUT.PUT_LINE('  Monto: $' || TO_CHAR(rec.MONTO, 'FM999,999,999'));
            DBMS_OUTPUT.PUT_LINE('  Fecha: ' || rec.FECHA);
            DBMS_OUTPUT.PUT_LINE('-----------------------------------');
        END LOOP;

        IF v_contador = 0 THEN
            DBMS_OUTPUT.PUT_LINE('No hay transacciones registradas');
        ELSE
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('Total mostrado: ' || v_contador || ' transacciones');
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error al consultar transacciones: ' || SQLERRM);
            RAISE;
    END consultar_ultimas_transacciones;

END gestion_transacciones_pkg;
/