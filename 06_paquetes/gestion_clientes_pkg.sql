-- =======================================
-- PAQUETE: gestion_clientes_pkg (SPEC) - CORREGIDO
-- =======================================

CREATE OR REPLACE PACKAGE PROYECTODB.gestion_clientes_pkg AS

    PROCEDURE crear_cliente(
        p_nombre IN VARCHAR2,
        p_identificacion IN NUMBER,
        p_direccion IN VARCHAR2,
        p_telefono IN VARCHAR2,
        p_email IN VARCHAR2,
        p_usuario_id IN NUMBER DEFAULT NULL,
        p_cliente_id OUT VARCHAR2,
        p_resultado OUT VARCHAR2
    );

    PROCEDURE actualizar_cliente(
        p_cliente_id IN VARCHAR2,
        p_nombre IN VARCHAR2 DEFAULT NULL,
        p_direccion IN VARCHAR2 DEFAULT NULL,
        p_telefono IN VARCHAR2 DEFAULT NULL,
        p_email IN VARCHAR2 DEFAULT NULL,
        p_resultado OUT VARCHAR2
    );

    PROCEDURE eliminar_cliente(
        p_cliente_id IN VARCHAR2,
        p_usuario_id IN NUMBER,
        p_resultado OUT VARCHAR2
    );

    PROCEDURE consultar_cliente(
        p_cliente_id IN VARCHAR2
    );

    FUNCTION buscar_por_identificacion(
        p_identificacion IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION listar_clientes(
        p_filtro_nombre IN VARCHAR2 DEFAULT NULL
    ) RETURN SYS_REFCURSOR;

    PROCEDURE obtener_resumen_cliente(
        p_cliente_id IN VARCHAR2
    );

    FUNCTION validar_cliente_existe(
        p_cliente_id IN VARCHAR2
    ) RETURN BOOLEAN;

END gestion_clientes_pkg;
/

-- =======================================
-- PAQUETE: gestion_clientes_pkg (BODY) - CORREGIDO
-- =======================================

CREATE OR REPLACE PACKAGE BODY PROYECTODB.gestion_clientes_pkg AS

    PROCEDURE crear_cliente(
        p_nombre IN VARCHAR2,
        p_identificacion IN NUMBER,
        p_direccion IN VARCHAR2,
        p_telefono IN VARCHAR2,
        p_email IN VARCHAR2,
        p_usuario_id IN NUMBER DEFAULT NULL,
        p_cliente_id OUT VARCHAR2,
        p_resultado OUT VARCHAR2
    ) IS
        v_count NUMBER;
        v_secuencia NUMBER;
    BEGIN
        -- Validaciones actualizadas
        IF p_nombre IS NULL OR p_identificacion IS NULL OR
           p_direccion IS NULL OR p_telefono IS NULL OR p_email IS NULL THEN
            RAISE_APPLICATION_ERROR(-20600, 'Todos los datos del cliente son obligatorios');
        END IF;

        -- Validar identificación única
        SELECT COUNT(*) INTO v_count
        FROM TBL_CLIENTES
        WHERE IDENTIFICACION = p_identificacion;

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20601,
                                    'Ya existe un cliente con la identificación: ' || p_identificacion);
        END IF;

        -- Si se proporciona usuario_id, validar que existe
        IF p_usuario_id IS NOT NULL THEN
            SELECT COUNT(*) INTO v_count
            FROM TBL_USUARIOS
            WHERE USUARIO_ID = p_usuario_id;

            IF v_count = 0 THEN
                RAISE_APPLICATION_ERROR(-20602, 'El usuario especificado no existe');
            END IF;
        END IF;

        -- Generar CLIENTE_ID
        SELECT COUNT(*) + 1 INTO v_secuencia FROM TBL_CLIENTES;
        p_cliente_id := 'CLI-' || LPAD(v_secuencia, 3, '0');

        -- Insertar con todos los campos
        INSERT INTO TBL_CLIENTES (
            CLIENTE_ID,
            NOMBRE,
            IDENTIFICACION,
            DIRECCION,
            TELEFONO,
            EMAIL,
            USUARIO_ID
        ) VALUES (
                     p_cliente_id,
                     p_nombre,
                     p_identificacion,
                     p_direccion,
                     p_telefono,
                     p_email,
                     p_usuario_id
                 );

        COMMIT;

        p_resultado := 'EXITO: Cliente creado con ID: ' || p_cliente_id;
        DBMS_OUTPUT.PUT_LINE('✓ ' || p_resultado);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_resultado := 'ERROR: ' || SQLERRM;
            DBMS_OUTPUT.PUT_LINE('✗ ' || p_resultado);
            RAISE;
    END crear_cliente;

    PROCEDURE actualizar_cliente(
        p_cliente_id IN VARCHAR2,
        p_nombre IN VARCHAR2 DEFAULT NULL,
        p_direccion IN VARCHAR2 DEFAULT NULL,
        p_telefono IN VARCHAR2 DEFAULT NULL,
        p_email IN VARCHAR2 DEFAULT NULL,
        p_resultado OUT VARCHAR2
    ) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM TBL_CLIENTES
        WHERE CLIENTE_ID = p_cliente_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20603, 'El cliente no existe');
        END IF;

        -- Actualizar con nuevos campos
        UPDATE TBL_CLIENTES
        SET NOMBRE = NVL(p_nombre, NOMBRE),
            DIRECCION = NVL(p_direccion, DIRECCION),
            TELEFONO = NVL(p_telefono, TELEFONO),
            EMAIL = NVL(p_email, EMAIL)
        WHERE CLIENTE_ID = p_cliente_id;

        COMMIT;

        p_resultado := 'EXITO: Cliente actualizado';
        DBMS_OUTPUT.PUT_LINE('✓ ' || p_resultado);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_resultado := 'ERROR: ' || SQLERRM;
            DBMS_OUTPUT.PUT_LINE('✗ ' || p_resultado);
            RAISE;
    END actualizar_cliente;

    -- Resto de procedimientos quedan igual
    PROCEDURE eliminar_cliente(
        p_cliente_id IN VARCHAR2,
        p_usuario_id IN NUMBER,
        p_resultado OUT VARCHAR2
    ) IS
        v_count_cuentas NUMBER;
        v_es_superadmin BOOLEAN;
    BEGIN
        v_es_superadmin := PROYECTODB.AUTENTICACION_PKG.es_superadmin(p_usuario_id);

        IF NOT v_es_superadmin THEN
            RAISE_APPLICATION_ERROR(-20604,
                                    'Solo SuperAdmin puede eliminar clientes');
        END IF;

        SELECT COUNT(*) INTO v_count_cuentas
        FROM TBL_CUENTAS
        WHERE CLIENTE_ID = p_cliente_id;

        IF v_count_cuentas > 0 THEN
            RAISE_APPLICATION_ERROR(-20605,
                                    'No se puede eliminar el cliente. Tiene ' || v_count_cuentas || ' cuenta(s) asociada(s)');
        END IF;

        DELETE FROM TBL_CLIENTES
        WHERE CLIENTE_ID = p_cliente_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20606, 'El cliente no existe');
        END IF;

        COMMIT;

        p_resultado := 'EXITO: Cliente eliminado';
        DBMS_OUTPUT.PUT_LINE('✓ ' || p_resultado);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_resultado := 'ERROR: ' || SQLERRM;
            DBMS_OUTPUT.PUT_LINE('✗ ' || p_resultado);
            RAISE;
    END eliminar_cliente;

    PROCEDURE consultar_cliente(
        p_cliente_id IN VARCHAR2
    ) IS
        v_cliente TBL_CLIENTES%ROWTYPE;
        v_total_cuentas NUMBER;
        v_saldo_total NUMBER;
    BEGIN
        SELECT * INTO v_cliente
        FROM TBL_CLIENTES
        WHERE CLIENTE_ID = p_cliente_id;

        SELECT COUNT(*), NVL(SUM(SALDO), 0)
        INTO v_total_cuentas, v_saldo_total
        FROM TBL_CUENTAS
        WHERE CLIENTE_ID = p_cliente_id;

        DBMS_OUTPUT.PUT_LINE('======= INFORMACIÓN DEL CLIENTE =======');
        DBMS_OUTPUT.PUT_LINE('ID Cliente: ' || v_cliente.CLIENTE_ID);
        DBMS_OUTPUT.PUT_LINE('Nombre: ' || v_cliente.NOMBRE);
        DBMS_OUTPUT.PUT_LINE('Identificación: ' || v_cliente.IDENTIFICACION);
        DBMS_OUTPUT.PUT_LINE('Dirección: ' || v_cliente.DIRECCION);
        DBMS_OUTPUT.PUT_LINE('Teléfono: ' || v_cliente.TELEFONO);
        DBMS_OUTPUT.PUT_LINE('Email: ' || v_cliente.EMAIL);
        DBMS_OUTPUT.PUT_LINE('Usuario ID: ' || NVL(TO_CHAR(v_cliente.USUARIO_ID), 'N/A'));
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('--- RESUMEN FINANCIERO ---');
        DBMS_OUTPUT.PUT_LINE('Total de cuentas: ' || v_total_cuentas);
        DBMS_OUTPUT.PUT_LINE('Saldo total: $' || TO_CHAR(v_saldo_total, 'FM999,999,999'));
        DBMS_OUTPUT.PUT_LINE('========================================');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('✗ El cliente no existe');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
            RAISE;
    END consultar_cliente;

    FUNCTION buscar_por_identificacion(
        p_identificacion IN NUMBER
    ) RETURN VARCHAR2 IS
        v_cliente_id VARCHAR2(20);
    BEGIN
        SELECT CLIENTE_ID INTO v_cliente_id
        FROM TBL_CLIENTES
        WHERE IDENTIFICACION = p_identificacion;

        RETURN v_cliente_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END buscar_por_identificacion;

    FUNCTION listar_clientes(
        p_filtro_nombre IN VARCHAR2 DEFAULT NULL
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        IF p_filtro_nombre IS NULL THEN
            OPEN v_cursor FOR
                SELECT
                    C.CLIENTE_ID,
                    C.NOMBRE,
                    C.IDENTIFICACION,
                    C.DIRECCION,
                    COUNT(CU.CUENTA_ID) AS TOTAL_CUENTAS,
                    NVL(SUM(CU.SALDO), 0) AS SALDO_TOTAL
                FROM TBL_CLIENTES C
                         LEFT JOIN TBL_CUENTAS CU ON C.CLIENTE_ID = CU.CLIENTE_ID
                GROUP BY C.CLIENTE_ID, C.NOMBRE, C.IDENTIFICACION, C.DIRECCION
                ORDER BY C.CLIENTE_ID;
        ELSE
            OPEN v_cursor FOR
                SELECT
                    C.CLIENTE_ID,
                    C.NOMBRE,
                    C.IDENTIFICACION,
                    C.DIRECCION,
                    COUNT(CU.CUENTA_ID) AS TOTAL_CUENTAS,
                    NVL(SUM(CU.SALDO), 0) AS SALDO_TOTAL
                FROM TBL_CLIENTES C
                         LEFT JOIN TBL_CUENTAS CU ON C.CLIENTE_ID = CU.CLIENTE_ID
                WHERE UPPER(C.NOMBRE) LIKE '%' || UPPER(p_filtro_nombre) || '%'
                GROUP BY C.CLIENTE_ID, C.NOMBRE, C.IDENTIFICACION, C.DIRECCION
                ORDER BY C.CLIENTE_ID;
        END IF;

        RETURN v_cursor;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20607, 'Error al listar clientes: ' || SQLERRM);
    END listar_clientes;

    PROCEDURE obtener_resumen_cliente(
        p_cliente_id IN VARCHAR2
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('===== RESUMEN COMPLETO DEL CLIENTE =====');
        DBMS_OUTPUT.PUT_LINE('');

        consultar_cliente(p_cliente_id);

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('--- DETALLE DE CUENTAS ---');

        FOR rec IN (
            SELECT
                C.CUENTA_ID,
                TP_TIPO.DESCRIPCION AS TIPO_CUENTA,
                C.SALDO,
                TP_ESTADO.DESCRIPCION AS ESTADO
            FROM TBL_CUENTAS C
                     JOIN TBL_TIPOS_PARAMETROS TP_TIPO ON C.TIPO_CUENTA_ID = TP_TIPO.TIPO_PARAMETRO_ID
                     JOIN TBL_TIPOS_PARAMETROS TP_ESTADO ON C.ESTADO_ID = TP_ESTADO.TIPO_PARAMETRO_ID
            WHERE C.CLIENTE_ID = p_cliente_id
            ORDER BY C.SALDO DESC
            ) LOOP
                DBMS_OUTPUT.PUT_LINE('  • ' || rec.CUENTA_ID || ' | ' ||
                                     rec.TIPO_CUENTA || ' | $' || TO_CHAR(rec.SALDO, 'FM999,999,999') ||
                                     ' | ' || rec.ESTADO);
            END LOOP;

        DBMS_OUTPUT.PUT_LINE('========================================');

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
    END obtener_resumen_cliente;

    FUNCTION validar_cliente_existe(
        p_cliente_id IN VARCHAR2
    ) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM TBL_CLIENTES
        WHERE CLIENTE_ID = p_cliente_id;

        RETURN v_count > 0;

    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END validar_cliente_existe;

END gestion_clientes_pkg;
/