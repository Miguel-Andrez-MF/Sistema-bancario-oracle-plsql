-- =======================================
-- TRIGGER 1: trg_valida_transaccion_retiro
-- =======================================

CREATE OR REPLACE TRIGGER PROYECTODB.TRG_VALIDA_TRANSACCION_RETIRO
    BEFORE INSERT ON PROYECTODB.TBL_TRANSACCIONES
    FOR EACH ROW
DECLARE

    v_saldo_actual NUMBER;
    v_estado_nombre VARCHAR2(20);
    v_tipo_transaccion VARCHAR2(20);


    cuenta_inactiva EXCEPTION;
    PRAGMA EXCEPTION_INIT(cuenta_inactiva, -20100);

    saldo_insuficiente EXCEPTION;
    PRAGMA EXCEPTION_INIT(saldo_insuficiente, -20101);

    cuenta_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(cuenta_inexistente, -20102);

    tipo_transaccion_invalido EXCEPTION;
    PRAGMA EXCEPTION_INIT(tipo_transaccion_invalido, -20103);

BEGIN

    BEGIN
        SELECT NOMBRE
        INTO v_tipo_transaccion
        FROM PROYECTODB.TBL_TIPOS_PARAMETROS
        WHERE TIPO_PARAMETRO_ID = :NEW.TIPO_TRANSAC_ID;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20103, 'Tipo de transacción inválido: ' || :NEW.TIPO_TRANSAC_ID);
    END;

    IF UPPER(v_tipo_transaccion) = 'RETIRO' THEN

        BEGIN
            SELECT C.SALDO, TP.NOMBRE
            INTO v_saldo_actual, v_estado_nombre
            FROM PROYECTODB.TBL_CUENTAS C
                     JOIN PROYECTODB.TBL_TIPOS_PARAMETROS TP ON C.ESTADO_ID = TP.TIPO_PARAMETRO_ID
            WHERE C.CUENTA_ID = :NEW.CUENTA_ID;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20102, 'La cuenta ' || :NEW.CUENTA_ID || ' no existe');
        END;

        IF UPPER(v_estado_nombre) != 'ACTIVA' THEN
            RAISE_APPLICATION_ERROR(-20100, 'No se puede realizar el retiro. La cuenta está ' || v_estado_nombre);
        END IF;


        IF v_saldo_actual < :NEW.MONTO THEN
            RAISE_APPLICATION_ERROR(-20101,
                                    'Saldo insuficiente. Saldo disponible: $' ||
                                    TO_CHAR(v_saldo_actual, 'FM999,999,999.99') ||
                                    ' | Monto solicitado: $' ||
                                    TO_CHAR(:NEW.MONTO, 'FM999,999,999.99'));
        END IF;

        -- Si llegamos aquí, todas las validaciones pasaron
        DBMS_OUTPUT.PUT_LINE('Retiro validado correctamente');

    END IF;

EXCEPTION
    WHEN cuenta_inactiva THEN
        DBMS_OUTPUT.PUT_LINE('Error: Cuenta inactiva o bloqueada');
        RAISE; -- Relanzar el error para que el INSERT falle

    WHEN saldo_insuficiente THEN
        DBMS_OUTPUT.PUT_LINE('Error: Fondos insuficientes');
        RAISE;

    WHEN cuenta_inexistente THEN
        DBMS_OUTPUT.PUT_LINE('Error: La cuenta no existe en el sistema');
        RAISE;

    WHEN tipo_transaccion_invalido THEN
        DBMS_OUTPUT.PUT_LINE('Error: Tipo de transacción no válido');
        RAISE;

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        PRC_LOG_ERROR('TRG_VALIDA_TRANSACCION_RETIRO', SQLERRM || ' | Cuenta: ' || :NEW.CUENTA_ID || ', Monto: ' || :NEW.MONTO);
        RAISE;
END;
/