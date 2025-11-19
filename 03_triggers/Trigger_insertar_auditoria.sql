-- =======================================
-- TRIGGER 2: trg_insertar_auditoria_transaccion
-- =======================================

CREATE OR REPLACE TRIGGER PROYECTODB.TRG_AUDITORIA_TRANSACCIONES
    AFTER INSERT OR UPDATE ON PROYECTODB.TBL_TRANSACCIONES
    FOR EACH ROW
DECLARE
    v_usuario_id NUMBER;
BEGIN

    SELECT CL.USUARIO_ID
    INTO v_usuario_id
    FROM PROYECTODB.TBL_CUENTAS C
             JOIN PROYECTODB.TBL_CLIENTES CL ON C.CLIENTE_ID = CL.CLIENTE_ID
    WHERE C.CUENTA_ID = :NEW.CUENTA_ID;

    IF INSERTING THEN
        INSERT INTO PROYECTODB.TBL_AUDITORIAS_TRANSACCION (
            AUDITORIA_ID,
            TRANSACCION_ID,
            USUARIO_ID,
            FECHA_OPERACION,
            MONTO_ANTERIOR,
            MONTO_NUEVO,
            TIPO_TRANSACCION_ANTERIOR,
            TIPO_TRANSACCION_NUEVO,
            OPERACION
        ) VALUES (
                     PROYECTODB.SEQ_AUDITORIA.NEXTVAL,
                     :NEW.TRANSACCION_ID,
                     v_usuario_id,
                     SYSDATE,
                     NULL,
                     :NEW.MONTO,
                     NULL,
                     :NEW.TIPO_TRANSAC_ID,
                     'INSERT'
                 );

    ELSIF UPDATING THEN
        INSERT INTO PROYECTODB.TBL_AUDITORIAS_TRANSACCION (
            AUDITORIA_ID,
            TRANSACCION_ID,
            USUARIO_ID,
            FECHA_OPERACION,
            MONTO_ANTERIOR,
            MONTO_NUEVO,
            TIPO_TRANSACCION_ANTERIOR,
            TIPO_TRANSACCION_NUEVO,
            OPERACION
        ) VALUES (
                     PROYECTODB.SEQ_AUDITORIA.NEXTVAL,
                     :NEW.TRANSACCION_ID,
                     v_usuario_id,
                     SYSDATE,
                     :OLD.MONTO,
                     :NEW.MONTO,
                     :OLD.TIPO_TRANSAC_ID,
                     :NEW.TIPO_TRANSAC_ID,
                     'UPDATE'
                 );
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado en auditoría: ' || SQLERRM);
        PRC_LOG_ERROR('TRG_AUDITORIA_TRANSACCIONES', SQLERRM || ' | Transacción ID: ' || :NEW.TRANSACCION_ID || ', Cuenta: ' || :NEW.CUENTA_ID);
        RAISE;
END;