CREATE OR REPLACE TRIGGER PROYECTODB.TRG_VERIFICAR_ROL_TRANSACCION
    BEFORE UPDATE ON PROYECTODB.TBL_TRANSACCIONES
    FOR EACH ROW
DECLARE
    v_rol NUMBER;
    v_rol_str VARCHAR2(20);
BEGIN
    -- 1. Leer el rol de la sesión actual
    v_rol_str := TRIM(SYS_CONTEXT('PROYECTO_CTX', 'ROL_ID'));

    -- 2. Validar que exista
    IF v_rol_str IS NULL THEN
        RAISE_APPLICATION_ERROR(-20601, 'No hay usuario logueado');
    END IF;

    -- 3. Convertir a número
    v_rol := TO_NUMBER(v_rol_str);

    -- 4. Solo rol 4 (Super_Admin) puede actualizar transacciones
    IF v_rol <> 1 THEN
        RAISE_APPLICATION_ERROR(-20602, 'Solo Super Admin puede actualizar');
    END IF;
END;