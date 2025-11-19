-- =======================================
-- TRIGGER 1: trg_valida_transaccion
-- =======================================

CREATE OR REPLACE TRIGGER PROYECTODB.TRG_VALIDA_TRANSACCION
    BEFORE INSERT ON PROYECTODB.TBL_TRANSACCIONES
    FOR EACH ROW
DECLARE

    -- Variables
    v_saldo_actual NUMBER;
    v_estado_valor NUMBER;
    v_tipo_transaccion_valor NUMBER;

    -- Constantes
    c_TIPO_DEPOSITO CONSTANT NUMBER := 10;
    c_TIPO_RETIRO CONSTANT NUMBER := 11;
    c_TIPO_TRANSFERENCIA CONSTANT NUMBER := 12;

    c_ESTADO_ACTIVA CONSTANT NUMBER := 1;
    c_ESTADO_INACTIVA CONSTANT NUMBER := 2;
    c_ESTADO_BLOQUEADA CONSTANT NUMBER := 3;


    cuenta_inactiva EXCEPTION;
    PRAGMA EXCEPTION_INIT(cuenta_inactiva, -20100);

    saldo_insuficiente EXCEPTION;
    PRAGMA EXCEPTION_INIT(saldo_insuficiente, -20101);

    cuenta_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(cuenta_inexistente, -20102);

    tipo_transaccion_invalido EXCEPTION;
    PRAGMA EXCEPTION_INIT(tipo_transaccion_invalido, -20103);

BEGIN

    -- Obtener el tipo de transacción
    BEGIN
        SELECT VALOR
        INTO v_tipo_transaccion_valor
        FROM PROYECTODB.TBL_TIPOS_PARAMETROS
        WHERE TIPO_PARAMETRO_ID = :NEW.TIPO_TRANSAC_ID
          AND NOMBRE = 'TIPO_TRANSACCION';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20103, 'Tipo de transacción inválido: ' || :NEW.TIPO_TRANSAC_ID);
    END;

    -- Validar RETIRO o TRANSFERENCIA (ambos requieren saldo suficiente)
    IF v_tipo_transaccion_valor IN (c_TIPO_RETIRO, c_TIPO_TRANSFERENCIA) THEN

        -- Obtener saldo y estado de la cuenta
        BEGIN
            SELECT C.SALDO, TP.VALOR
            INTO v_saldo_actual, v_estado_valor
            FROM TBL_CUENTAS C
                     JOIN TBL_TIPOS_PARAMETROS TP ON C.ESTADO_ID = TP.TIPO_PARAMETRO_ID
            WHERE C.CUENTA_ID = :NEW.CUENTA_ID
              AND TP.NOMBRE = 'ESTADO';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20102, 'La cuenta ' || :NEW.CUENTA_ID || ' no existe');
        END;

        -- Validar que la cuenta esté activa
        IF v_estado_valor != c_ESTADO_ACTIVA THEN
            RAISE_APPLICATION_ERROR(-20100,
                                    'No se puede realizar ' ||
                                    CASE v_tipo_transaccion_valor
                                        WHEN c_TIPO_RETIRO THEN 'el retiro'
                                        WHEN c_TIPO_TRANSFERENCIA THEN 'la transferencia'
                                        ELSE 'la operación'
                                        END ||
                                    '. La cuenta está ' ||
                                    CASE v_estado_valor
                                        WHEN c_ESTADO_INACTIVA THEN 'INACTIVA'
                                        WHEN c_ESTADO_BLOQUEADA THEN 'BLOQUEADA'
                                        ELSE 'EN ESTADO DESCONOCIDO'
                                        END);
        END IF;

        -- Validar saldo suficiente
        IF v_saldo_actual < :NEW.MONTO THEN
            RAISE_APPLICATION_ERROR(-20101,
                                    'Saldo insuficiente para ' ||
                                    CASE v_tipo_transaccion_valor
                                        WHEN c_TIPO_RETIRO THEN 'retiro'
                                        WHEN c_TIPO_TRANSFERENCIA THEN 'transferencia'
                                        ELSE 'operación'
                                        END ||
                                    '. Saldo disponible: $' ||
                                    TO_CHAR(v_saldo_actual, 'FM999,999,999.99') ||
                                    ' | Monto solicitado: $' ||
                                    TO_CHAR(:NEW.MONTO, 'FM999,999,999.99'));
        END IF;

        -- Si llegamos aquí, todas las validaciones pasaron
        DBMS_OUTPUT.PUT_LINE(
                CASE v_tipo_transaccion_valor
                    WHEN c_TIPO_RETIRO THEN 'Retiro'
                    WHEN c_TIPO_TRANSFERENCIA THEN 'Transferencia'
                    ELSE 'Operación'
                    END || ' validada correctamente'
        );

    ELSIF v_tipo_transaccion_valor = c_TIPO_DEPOSITO THEN
        -- Para depósitos, solo verificar que la cuenta exista
        BEGIN
            SELECT C.SALDO
            INTO v_saldo_actual
            FROM TBL_CUENTAS C
            WHERE C.CUENTA_ID = :NEW.CUENTA_ID;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20102, 'La cuenta ' || :NEW.CUENTA_ID || ' no existe');
        END;

        DBMS_OUTPUT.PUT_LINE('Depósito validado correctamente');

    END IF;

EXCEPTION
    WHEN cuenta_inactiva THEN
        DBMS_OUTPUT.PUT_LINE('Error: Cuenta inactiva o bloqueada');
        PRC_LOG_ERROR('TRG_VALIDA_TRANSACCION',
                      'Cuenta inactiva o bloqueada | Cuenta: ' || :NEW.CUENTA_ID || ', Monto: ' || :NEW.MONTO || ', Tipo: ' || v_tipo_transaccion_valor);
        RAISE;

    WHEN saldo_insuficiente THEN
        DBMS_OUTPUT.PUT_LINE('Error: Fondos insuficientes');
        PRC_LOG_ERROR('TRG_VALIDA_TRANSACCION',
                      'Fondos insuficientes | Cuenta: ' || :NEW.CUENTA_ID || ', Monto: ' || :NEW.MONTO || ', Saldo: ' || v_saldo_actual || ', Tipo: ' || v_tipo_transaccion_valor);
        RAISE;

    WHEN cuenta_inexistente THEN
        DBMS_OUTPUT.PUT_LINE('Error: La cuenta no existe en el sistema');
        PRC_LOG_ERROR('TRG_VALIDA_TRANSACCION',
                      'Cuenta inexistente | Cuenta: ' || :NEW.CUENTA_ID);
        RAISE;

    WHEN tipo_transaccion_invalido THEN
        DBMS_OUTPUT.PUT_LINE('Error: Tipo de transacción no válido');
        PRC_LOG_ERROR('TRG_VALIDA_TRANSACCION',
                      'Tipo de transacción inválido | Tipo: ' || :NEW.TIPO_TRANSAC_ID);
        RAISE;

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        PRC_LOG_ERROR('TRG_VALIDA_TRANSACCION',
                      SQLERRM || ' | Cuenta: ' || :NEW.CUENTA_ID || ', Monto: ' || :NEW.MONTO);
        RAISE;
END;
/