-- =======================================
-- MIGRAR CONTRASEÑAS A HASH SHA-256
-- =======================================
SET SERVEROUTPUT ON;

DECLARE
    v_password_original VARCHAR2(64);
    v_password_hash     VARCHAR2(64);
    v_count             NUMBER := 0;
    
    CURSOR c_usuarios IS
        SELECT USUARIO_ID, PASSWORD
        FROM PROYECTODB.TBL_USUARIOS
        WHERE LENGTH(PASSWORD) < 64; -- Solo migrar las que no son hash
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== MIGRACIÓN DE CONTRASEÑAS =====');
    DBMS_OUTPUT.PUT_LINE('');
    
    FOR rec IN c_usuarios LOOP
        v_password_original := rec.PASSWORD;
        
        -- Generar hash
        v_password_hash := PROYECTODB.AUTENTICACION_PKG.hash_password(v_password_original);
        
        IF v_password_hash IS NOT NULL THEN
            -- Actualizar en BD
            UPDATE PROYECTODB.TBL_USUARIOS
            SET PASSWORD = v_password_hash
            WHERE USUARIO_ID = rec.USUARIO_ID;
            
            v_count := v_count + 1;
            
            DBMS_OUTPUT.PUT_LINE('✓ Usuario ID ' || rec.USUARIO_ID || 
                               ' | Hash: ' || SUBSTR(v_password_hash, 1, 16) || '...');
        ELSE
            DBMS_OUTPUT.PUT_LINE('✗ Error en Usuario ID ' || rec.USUARIO_ID);
        END IF;
    END LOOP;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('===== COMPLETADO =====');
    DBMS_OUTPUT.PUT_LINE('Contraseñas migradas: ' || v_count);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
END;
/