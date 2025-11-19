-- =======================================
-- SUITE DE PRUEBAS: TRANSACCIONES
-- =======================================

-- ========================================
--   PRUEBAS - GESTIÓN DE TRANSACCIONES
-- ========================================
--

-- =======================================
-- PREPARACIÓN: Verificar datos de prueba
-- =======================================
-- ===== Verificando cuentas de prueba =====
SELECT
    CUENTA_ID,
    CLIENTE_ID,
    SALDO,
    ESTADO_ID
FROM PROYECTODB.TBL_CUENTAS
WHERE CUENTA_ID IN ('CTA-0001', 'CTA-0002', 'CTA-0003')
ORDER BY CUENTA_ID;

--
-- ===== Saldos iniciales =====
DECLARE
    v_saldo NUMBER;
BEGIN
    v_saldo := PROYECTODB.gestion_transacciones_pkg.consultar_saldo('CTA-0001');
    DBMS_OUTPUT.PUT_LINE('CTA-0001: $' || TO_CHAR(v_saldo, 'FM999,999,999'));

    v_saldo := PROYECTODB.gestion_transacciones_pkg.consultar_saldo('CTA-0002');
    DBMS_OUTPUT.PUT_LINE('CTA-0002: $' || TO_CHAR(v_saldo, 'FM999,999,999'));

    v_saldo := PROYECTODB.gestion_transacciones_pkg.consultar_saldo('CTA-0003');
    DBMS_OUTPUT.PUT_LINE('CTA-0003: $' || TO_CHAR(v_saldo, 'FM999,999,999'));
END;
/

--
-- ========================================
--   PRUEBAS DE DEPÓSITOS
-- ========================================

-- =======================================
-- PRUEBA 1: Depósito exitoso
-- =======================================
--
-- ===== PRUEBA 1: Depósito Exitoso =====
DECLARE
    v_transaccion_id NUMBER;
    v_resultado VARCHAR2(500);
BEGIN
    PROYECTODB.gestion_transacciones_pkg.realizar_deposito(
            p_cuenta_id => 'CTA-0001',
            p_monto => 500000,
            p_usuario_id => 1,
            p_transaccion_id => v_transaccion_id,
            p_resultado => v_resultado
    );

    DBMS_OUTPUT.PUT_LINE('Transacción ID: ' || v_transaccion_id);
    DBMS_OUTPUT.PUT_LINE('Resultado: ' || v_resultado);
    DBMS_OUTPUT.PUT_LINE('✅ PRUEBA EXITOSA');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
END;
/

-- =======================================
-- PRUEBA 2: Depósito con monto negativo (debe fallar)
-- =======================================
--
-- ===== PRUEBA 2: Depósito con Monto Negativo =====
DECLARE
    v_transaccion_id NUMBER;
    v_resultado VARCHAR2(500);
BEGIN
    PROYECTODB.gestion_transacciones_pkg.realizar_deposito(
            p_cuenta_id => 'CTA-0001',
            p_monto => -100000,
            p_usuario_id => 1,
            p_transaccion_id => v_transaccion_id,
            p_resultado => v_resultado
    );

    DBMS_OUTPUT.PUT_LINE('❌ PRUEBA FALLIDA: Debió rechazar monto negativo');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLERRM LIKE '%mayor a cero%' THEN
            DBMS_OUTPUT.PUT_LINE('✅ PRUEBA EXITOSA: Monto negativo rechazado correctamente');
        ELSE
            DBMS_OUTPUT.PUT_LINE('❌ Error inesperado: ' || SQLERRM);
        END IF;
END;
/

-- =======================================
-- PRUEBA 3: Depósito en cuenta inexistente (debe fallar)
-- =======================================
--
-- ===== PRUEBA 3: Depósito en Cuenta Inexistente =====
DECLARE
    v_transaccion_id NUMBER;
    v_resultado VARCHAR2(500);
BEGIN
    PROYECTODB.gestion_transacciones_pkg.realizar_deposito(
            p_cuenta_id => 'CTA-9999',
            p_monto => 100000,
            p_usuario_id => 1,
            p_transaccion_id => v_transaccion_id,
            p_resultado => v_resultado
    );

    DBMS_OUTPUT.PUT_LINE('❌ PRUEBA FALLIDA: Debió rechazar cuenta inexistente');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLERRM LIKE '%no existe%' THEN
            DBMS_OUTPUT.PUT_LINE('✅ PRUEBA EXITOSA: Cuenta inexistente detectada');
        ELSE
            DBMS_OUTPUT.PUT_LINE('❌ Error inesperado: ' || SQLERRM);
        END IF;
END;
/

--
-- ========================================
--   PRUEBAS DE RETIROS
-- ========================================

-- =======================================
-- PRUEBA 4: Retiro exitoso
-- =======================================
--
-- ===== PRUEBA 4: Retiro Exitoso =====
DECLARE
    v_transaccion_id NUMBER;
    v_resultado VARCHAR2(500);
BEGIN
    PROYECTODB.gestion_transacciones_pkg.realizar_retiro(
            p_cuenta_id => 'CTA-0001',
            p_monto => 100000,
            p_usuario_id => 1,
            p_transaccion_id => v_transaccion_id,
            p_resultado => v_resultado
    );

    DBMS_OUTPUT.PUT_LINE('Transacción ID: ' || v_transaccion_id);
    DBMS_OUTPUT.PUT_LINE('Resultado: ' || v_resultado);
    DBMS_OUTPUT.PUT_LINE('✅ PRUEBA EXITOSA');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
END;
/

-- =======================================
-- PRUEBA 5: Retiro con saldo insuficiente (debe fallar)
-- =======================================
--
-- ===== PRUEBA 5: Retiro con Saldo Insuficiente =====
DECLARE
    v_transaccion_id NUMBER;
    v_resultado VARCHAR2(500);
BEGIN
    PROYECTODB.gestion_transacciones_pkg.realizar_retiro(
            p_cuenta_id => 'CTA-0001',
            p_monto => 999999999,
            p_usuario_id => 1,
            p_transaccion_id => v_transaccion_id,
            p_resultado => v_resultado
    );

    DBMS_OUTPUT.PUT_LINE('❌ PRUEBA FALLIDA: Debió rechazar por saldo insuficiente');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLERRM LIKE '%insuficiente%' THEN
            DBMS_OUTPUT.PUT_LINE('✅ PRUEBA EXITOSA: Saldo insuficiente detectado');
        ELSE
            DBMS_OUTPUT.PUT_LINE('❌ Error inesperado: ' || SQLERRM);
        END IF;
END;
/

-- =======================================
-- PRUEBA 6: Retiro de cuenta inactiva (debe fallar)
-- =======================================
--
-- ===== PRUEBA 6: Retiro de Cuenta Inactiva =====
DECLARE
    v_transaccion_id NUMBER;
    v_resultado VARCHAR2(500);
BEGIN
    -- Primero asegurarse de que CTA-0005 esté inactiva
    UPDATE PROYECTODB.TBL_CUENTAS
    SET ESTADO_ID = 5  -- 5 = Inactiva
    WHERE CUENTA_ID = 'CTA-0005';
    COMMIT;

    PROYECTODB.gestion_transacciones_pkg.realizar_retiro(
            p_cuenta_id => 'CTA-0005',
            p_monto => 10000,
            p_usuario_id => 1,
            p_transaccion_id => v_transaccion_id,
            p_resultado => v_resultado
    );

    DBMS_OUTPUT.PUT_LINE('❌ PRUEBA FALLIDA: Debió rechazar cuenta inactiva');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLERRM LIKE '%no está activa%' THEN
            DBMS_OUTPUT.PUT_LINE('✅ PRUEBA EXITOSA: Cuenta inactiva detectada');
        ELSE
            DBMS_OUTPUT.PUT_LINE('❌ Error inesperado: ' || SQLERRM);
        END IF;
END;
/

--
-- ========================================
--   PRUEBAS DE TRANSFERENCIAS
-- ========================================

-- =======================================
-- PRUEBA 7: Transferencia exitosa
-- =======================================
--
-- ===== PRUEBA 7: Transferencia Exitosa =====
DECLARE
    v_transaccion_id NUMBER;
    v_resultado VARCHAR2(500);
BEGIN
    PROYECTODB.gestion_transacciones_pkg.realizar_transferencia(
            p_cuenta_origen => 'CTA-0001',
            p_cuenta_destino => 'CTA-0002',
            p_monto => 250000,
            p_usuario_id => 1,
            p_transaccion_id => v_transaccion_id,
            p_resultado => v_resultado
    );

    DBMS_OUTPUT.PUT_LINE('Transacción ID: ' || v_transaccion_id);
    DBMS_OUTPUT.PUT_LINE('Resultado: ' || v_resultado);
    DBMS_OUTPUT.PUT_LINE('✅ PRUEBA EXITOSA');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
END;
/

-- =======================================
-- PRUEBA 8: Transferencia a la misma cuenta (debe fallar)
-- =======================================
--
-- ===== PRUEBA 8: Transferencia a la Misma Cuenta =====
DECLARE
    v_transaccion_id NUMBER;
    v_resultado VARCHAR2(500);
BEGIN
    PROYECTODB.gestion_transacciones_pkg.realizar_transferencia(
            p_cuenta_origen => 'CTA-0001',
            p_cuenta_destino => 'CTA-0001',
            p_monto => 100000,
            p_usuario_id => 1,
            p_transaccion_id => v_transaccion_id,
            p_resultado => v_resultado
    );

    DBMS_OUTPUT.PUT_LINE('❌ PRUEBA FALLIDA: Debió rechazar transferencia a misma cuenta');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLERRM LIKE '%misma cuenta%' THEN
            DBMS_OUTPUT.PUT_LINE('✅ PRUEBA EXITOSA: Transferencia a misma cuenta rechazada');
        ELSE
            DBMS_OUTPUT.PUT_LINE('❌ Error inesperado: ' || SQLERRM);
        END IF;
END;
/

-- =======================================
-- PRUEBA 9: Transferencia con saldo insuficiente (debe fallar)
-- =======================================
--
-- ===== PRUEBA 9: Transferencia con Saldo Insuficiente =====
DECLARE
    v_transaccion_id NUMBER;
    v_resultado VARCHAR2(500);
BEGIN
    PROYECTODB.gestion_transacciones_pkg.realizar_transferencia(
            p_cuenta_origen => 'CTA-0001',
            p_cuenta_destino => 'CTA-0002',
            p_monto => 999999999,
            p_usuario_id => 1,
            p_transaccion_id => v_transaccion_id,
            p_resultado => v_resultado
    );

    DBMS_OUTPUT.PUT_LINE('❌ PRUEBA FALLIDA: Debió rechazar por saldo insuficiente');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLERRM LIKE '%insuficiente%' THEN
            DBMS_OUTPUT.PUT_LINE('✅ PRUEBA EXITOSA: Saldo insuficiente detectado');
        ELSE
            DBMS_OUTPUT.PUT_LINE('❌ Error inesperado: ' || SQLERRM);
        END IF;
END;
/

--
-- ========================================
--   PRUEBAS DE CONSULTAS
-- ========================================

-- =======================================
-- PRUEBA 10: Consultar saldo
-- =======================================
--
-- ===== PRUEBA 10: Consultar Saldo =====
DECLARE
    v_saldo NUMBER;
BEGIN
    v_saldo := PROYECTODB.gestion_transacciones_pkg.consultar_saldo('CTA-0001');
    DBMS_OUTPUT.PUT_LINE('Saldo CTA-0001: $' || TO_CHAR(v_saldo, 'FM999,999,999'));
    DBMS_OUTPUT.PUT_LINE('✅ PRUEBA EXITOSA');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
END;
/

-- =======================================
-- PRUEBA 11: Consultar últimas transacciones
-- =======================================
--
-- ===== PRUEBA 11: Últimas Transacciones =====
BEGIN
    PROYECTODB.gestion_transacciones_pkg.consultar_ultimas_transacciones(
            p_cuenta_id => 'CTA-0001',
            p_cantidad => 5
    );
    DBMS_OUTPUT.PUT_LINE('✅ PRUEBA EXITOSA');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
END;
/

-- =======================================
-- PRUEBA 12: Generar historial (con cursor)
-- =======================================
--
-- ===== PRUEBA 12: Generar Historial (Cursor) =====
DECLARE
    v_cursor SYS_REFCURSOR;
    v_transaccion_id NUMBER;
    v_cuenta_id VARCHAR2(20);
    v_tipo VARCHAR2(100);
    v_monto NUMBER;
    v_fecha DATE;
    v_fecha_fmt VARCHAR2(50);
    v_count NUMBER := 0;
BEGIN
    v_cursor := PROYECTODB.gestion_transacciones_pkg.generar_historial(
            p_cuenta_id => 'CTA-0001',
            p_fecha_inicio => ADD_MONTHS(SYSDATE, -1),
            p_fecha_fin => SYSDATE
                );

    DBMS_OUTPUT.PUT_LINE('--- HISTORIAL DE CTA-0001 (último mes) ---');
    LOOP
        FETCH v_cursor INTO v_transaccion_id, v_cuenta_id, v_tipo, v_monto, v_fecha, v_fecha_fmt;
        EXIT WHEN v_cursor%NOTFOUND;

        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE(v_count || '. ' || v_tipo || ' | $' ||
                             TO_CHAR(v_monto, 'FM999,999,999') || ' | ' || v_fecha_fmt);
    END LOOP;
    CLOSE v_cursor;

    DBMS_OUTPUT.PUT_LINE('Total: ' || v_count || ' transacciones');
    DBMS_OUTPUT.PUT_LINE('✅ PRUEBA EXITOSA');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;
/

--
-- ========================================
--   RESUMEN FINAL
-- ========================================
--
-- ===== Saldos finales =====
DECLARE
    v_saldo NUMBER;
BEGIN
    v_saldo := PROYECTODB.gestion_transacciones_pkg.consultar_saldo('CTA-0001');
    DBMS_OUTPUT.PUT_LINE('CTA-0001: $' || TO_CHAR(v_saldo, 'FM999,999,999'));

    v_saldo := PROYECTODB.gestion_transacciones_pkg.consultar_saldo('CTA-0002');
    DBMS_OUTPUT.PUT_LINE('CTA-0002: $' || TO_CHAR(v_saldo, 'FM999,999,999'));

    v_saldo := PROYECTODB.gestion_transacciones_pkg.consultar_saldo('CTA-0003');
    DBMS_OUTPUT.PUT_LINE('CTA-0003: $' || TO_CHAR(v_saldo, 'FM999,999,999'));
END;
/

--
-- ========================================
--   PRUEBAS COMPLETADAS
-- ========================================