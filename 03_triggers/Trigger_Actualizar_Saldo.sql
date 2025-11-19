-- =======================================
-- TRIGGER: trg_actualiza_saldo
-- Descripción: Actualiza automáticamente el saldo de las cuentas
--              después de cada transacción (depósito, retiro, transferencia)
-- =======================================

CREATE OR REPLACE TRIGGER PROYECTODB.TRG_ACTUALIZA_SALDO
AFTER INSERT ON PROYECTODB.TBL_TRANSACCIONES
FOR EACH ROW
DECLARE
    v_tipo_transaccion_valor NUMBER;
BEGIN
    -- Obtener el VALOR del tipo de transacción
    SELECT VALOR INTO v_tipo_transaccion_valor
    FROM TBL_TIPOS_PARAMETROS
    WHERE TIPO_PARAMETRO_ID = :NEW.TIPO_TRANSAC_ID
    AND NOMBRE = 'TIPO_TRANSACCION';
    
    -- Actualizar saldo según tipo de transacción
    IF v_tipo_transaccion_valor = 10 THEN  
        -- DEPOSITO: Sumar monto
        UPDATE TBL_CUENTAS
        SET SALDO = SALDO + :NEW.MONTO
        WHERE CUENTA_ID = :NEW.CUENTA_ID;
        
        DBMS_OUTPUT.PUT_LINE('✓ Saldo actualizado (Depósito): +$' || 
            TO_CHAR(:NEW.MONTO, 'FM999,999,999'));
        
    ELSIF v_tipo_transaccion_valor = 11 THEN  
        -- RETIRO: Restar monto
        UPDATE TBL_CUENTAS
        SET SALDO = SALDO - :NEW.MONTO
        WHERE CUENTA_ID = :NEW.CUENTA_ID;
        
        DBMS_OUTPUT.PUT_LINE('✓ Saldo actualizado (Retiro): -$' || 
            TO_CHAR(:NEW.MONTO, 'FM999,999,999'));
        
    ELSIF v_tipo_transaccion_valor = 12 THEN  
        -- TRANSFERENCIA: Restar de cuenta origen
        UPDATE TBL_CUENTAS
        SET SALDO = SALDO - :NEW.MONTO
        WHERE CUENTA_ID = :NEW.CUENTA_ID;
        
        DBMS_OUTPUT.PUT_LINE('✓ Saldo actualizado (Transferencia): -$' || 
            TO_CHAR(:NEW.MONTO, 'FM999,999,999'));
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20500, 
            'Tipo de transacción no encontrado: ' || :NEW.TIPO_TRANSAC_ID);
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20501, 
            'Error al actualizar saldo: ' || SQLERRM);
END;
/

-- Mostrar estado del trigger
SHOW ERRORS TRIGGER TRG_ACTUALIZA_SALDO;

-- Mensaje de confirmación
PROMPT ✓ Trigger TRG_ACTUALIZA_SALDO creado exitosamente