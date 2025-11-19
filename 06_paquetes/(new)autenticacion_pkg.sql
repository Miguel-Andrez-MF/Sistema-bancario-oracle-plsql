-- =======================================
-- ESPECIFICACIÓN DEL PAQUETE (CON HASH)
-- =======================================
CREATE OR REPLACE PACKAGE PROYECTODB.AUTENTICACION_PKG IS

    -- Tipo de retorno para la función de validación
    TYPE t_resultado_auth IS RECORD (
                                        exitoso        BOOLEAN,
                                        usuario_id     NUMBER,
                                        cliente_id     VARCHAR2(20),
                                        nombre_usuario VARCHAR2(20),
                                        rol_id         NUMBER,
                                        nombre_rol     VARCHAR2(20),
                                        mensaje        VARCHAR2(500)
                                    );

    -- Función principal de validación de credenciales
    FUNCTION validar_credenciales(
        p_usuario  IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN t_resultado_auth;

    -- Función auxiliar para obtener información del usuario autenticado
    FUNCTION obtener_info_usuario(
        p_usuario_id IN NUMBER
    ) RETURN t_resultado_auth;

    -- Funciones de validación de roles
    FUNCTION es_superadmin(p_usuario_id IN NUMBER) RETURN BOOLEAN;
    FUNCTION es_administrador(p_usuario_id IN NUMBER) RETURN BOOLEAN;
    FUNCTION es_analista(p_usuario_id IN NUMBER) RETURN BOOLEAN;
    FUNCTION es_cliente(p_usuario_id IN NUMBER) RETURN BOOLEAN;

    -- ✅ NUEVA: Función de hash de contraseñas
    FUNCTION hash_password(p_password IN VARCHAR2) RETURN VARCHAR2;

END AUTENTICACION_PKG;
/

-- =======================================
-- CUERPO DEL PAQUETE (CON HASH)
-- =======================================
CREATE OR REPLACE PACKAGE BODY PROYECTODB.AUTENTICACION_PKG IS

    -- Constantes para mensajes
    c_usuario_no_existe    CONSTANT VARCHAR2(100) := 'Usuario no existe';
    c_password_incorrecta  CONSTANT VARCHAR2(100) := 'Contraseña incorrecta';
    c_auth_exitosa         CONSTANT VARCHAR2(100) := 'Autenticación exitosa';
    c_error_validacion     CONSTANT VARCHAR2(100) := 'Error durante validación';
    c_parametros_invalidos CONSTANT VARCHAR2(100) := 'Usuario o contraseña vacíos';

    -- =======================================
    -- ✅ FUNCIÓN: Hash de contraseñas (con STANDARD_HASH)
    -- =======================================
    FUNCTION hash_password(p_password IN VARCHAR2) RETURN VARCHAR2 IS
        v_hash VARCHAR2(200);
    BEGIN
        EXECUTE IMMEDIATE
            'SELECT STANDARD_HASH(:1, ''SHA256'') FROM dual'
            INTO v_hash
            USING p_password;

        RETURN LOWER(REPLACE(v_hash, '0x',''));
    END;

    -- =======================================
    -- FUNCIÓN: Validar Credenciales (CON HASH)
    -- =======================================
    FUNCTION validar_credenciales(
        p_usuario  IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN t_resultado_auth IS

        v_resultado        t_resultado_auth;
        v_usuario_id       NUMBER;
        v_password_bd      VARCHAR2(64);
        v_rol_id           NUMBER;
        v_nombre_rol       VARCHAR2(20);
        v_cliente_id       VARCHAR2(20);
        v_usuario_count    NUMBER := 0;
        v_password_hash    VARCHAR2(64);    -- ✅ NUEVO: Hash de la contraseña ingresada

    BEGIN
        -- Inicializar resultado
        v_resultado.exitoso := FALSE;
        v_resultado.usuario_id := NULL;
        v_resultado.cliente_id := NULL;
        v_resultado.nombre_usuario := NULL;
        v_resultado.rol_id := NULL;
        v_resultado.nombre_rol := NULL;
        v_resultado.mensaje := NULL;

        -- Validar que los parámetros no vengan vacíos
        IF p_usuario IS NULL OR TRIM(p_usuario) IS NULL OR
           p_password IS NULL OR TRIM(p_password) IS NULL THEN
            v_resultado.mensaje := c_parametros_invalidos;
            PROYECTODB.PRC_LOG_ERROR(
                    'AUTENTICACION_PKG.validar_credenciales',
                    'Intento de login con parámetros vacíos'
            );
            RETURN v_resultado;
        END IF;

        -- Verificar si el usuario existe
        BEGIN
            SELECT COUNT(*)
            INTO v_usuario_count
            FROM PROYECTODB.TBL_USUARIOS
            WHERE UPPER(USUARIO) = UPPER(TRIM(p_usuario));

            IF v_usuario_count = 0 THEN
                v_resultado.mensaje := c_usuario_no_existe;
                PROYECTODB.PRC_LOG_ERROR(
                        'AUTENTICACION_PKG.validar_credenciales',
                        'Intento de login con usuario inexistente: ' || p_usuario
                );
                RETURN v_resultado;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                v_resultado.mensaje := c_error_validacion;
                PROYECTODB.PRC_LOG_ERROR(
                        'AUTENTICACION_PKG.validar_credenciales',
                        'Error al verificar existencia del usuario: ' || SQLERRM
                );
                RETURN v_resultado;
        END;

        -- ✅ NUEVO: Generar hash de la contraseña ingresada
        v_password_hash := hash_password(p_password);

        -- Obtener datos del usuario y validar contraseña
        BEGIN
            SELECT
                U.USUARIO_ID,
                U.PASSWORD,
                U.ROL_ID,
                R.NOMBRE
            INTO
                v_usuario_id,
                v_password_bd,
                v_rol_id,
                v_nombre_rol
            FROM PROYECTODB.TBL_USUARIOS U
                     JOIN PROYECTODB.TBL_ROLES R ON U.ROL_ID = R.ROL_ID
            WHERE UPPER(U.USUARIO) = UPPER(TRIM(p_usuario));

            -- ✅ NUEVO: Validar HASH o TEXTO PLANO (compatibilidad)
            -- Esto permite que funcione con contraseñas antiguas (texto plano)
            -- y nuevas (con hash)
            IF v_password_bd != p_password AND v_password_bd != v_password_hash THEN
                v_resultado.mensaje := c_password_incorrecta;
                PROYECTODB.PRC_LOG_ERROR(
                        'AUTENTICACION_PKG.validar_credenciales',
                        'Intento de login fallido (password incorrecta) para usuario: ' || p_usuario
                );
                RETURN v_resultado;
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_resultado.mensaje := c_usuario_no_existe;
                PROYECTODB.PRC_LOG_ERROR(
                        'AUTENTICACION_PKG.validar_credenciales',
                        'Usuario no encontrado: ' || p_usuario
                );
                RETURN v_resultado;
            WHEN OTHERS THEN
                v_resultado.mensaje := c_error_validacion;
                PROYECTODB.PRC_LOG_ERROR(
                        'AUTENTICACION_PKG.validar_credenciales',
                        'Error al obtener datos del usuario: ' || SQLERRM
                );
                RETURN v_resultado;
        END;

        -- Obtener CLIENTE_ID si existe relación
        BEGIN
            SELECT CLIENTE_ID
            INTO v_cliente_id
            FROM PROYECTODB.TBL_CLIENTES
            WHERE USUARIO_ID = v_usuario_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_cliente_id := NULL;
            WHEN OTHERS THEN
                PROYECTODB.PRC_LOG_ERROR(
                        'AUTENTICACION_PKG.validar_credenciales',
                        'Error al obtener CLIENTE_ID para USUARIO_ID ' || v_usuario_id || ': ' || SQLERRM
                );
                v_cliente_id := NULL;
        END;

        -- Autenticación exitosa
        v_resultado.exitoso := TRUE;
        v_resultado.usuario_id := v_usuario_id;
        v_resultado.cliente_id := v_cliente_id;
        v_resultado.nombre_usuario := TRIM(p_usuario);
        v_resultado.rol_id := v_rol_id;
        v_resultado.nombre_rol := v_nombre_rol;
        v_resultado.mensaje := c_auth_exitosa;

        -- Guardar usuario activo en el contexto de sesión
        DBMS_SESSION.SET_CONTEXT('PROYECTO_CTX', 'USUARIO_ID', v_usuario_id);
        DBMS_SESSION.SET_CONTEXT('PROYECTO_CTX', 'ROL_ID', v_rol_id);

        RETURN v_resultado;

    EXCEPTION
        WHEN OTHERS THEN
            v_resultado.exitoso := FALSE;
            v_resultado.mensaje := c_error_validacion || ': ' || SQLERRM;
            PROYECTODB.PRC_LOG_ERROR(
                    'AUTENTICACION_PKG.validar_credenciales',
                    'Error general: ' || SQLERRM || ' | Usuario: ' || p_usuario
            );
            RETURN v_resultado;
    END validar_credenciales;

    -- (El resto de las funciones quedan IGUAL al código anterior)
    -- obtener_info_usuario, es_superadmin, es_administrador, es_analista, es_cliente

    FUNCTION obtener_info_usuario(
        p_usuario_id IN NUMBER
    ) RETURN t_resultado_auth IS
        v_resultado t_resultado_auth;
    BEGIN
        v_resultado.exitoso := FALSE;
        v_resultado.usuario_id := NULL;
        v_resultado.cliente_id := NULL;
        v_resultado.nombre_usuario := NULL;
        v_resultado.rol_id := NULL;
        v_resultado.nombre_rol := NULL;
        v_resultado.mensaje := NULL;

        IF p_usuario_id IS NULL THEN
            v_resultado.mensaje := 'ID de usuario inválido';
            RETURN v_resultado;
        END IF;

        BEGIN
            SELECT
                u.USUARIO_ID,
                u.USUARIO,
                u.ROL_ID,
                r.NOMBRE,
                c.CLIENTE_ID
            INTO
                v_resultado.usuario_id,
                v_resultado.nombre_usuario,
                v_resultado.rol_id,
                v_resultado.nombre_rol,
                v_resultado.cliente_id
            FROM PROYECTODB.TBL_USUARIOS u
                     JOIN PROYECTODB.TBL_ROLES r ON u.ROL_ID = r.ROL_ID
                     LEFT JOIN PROYECTODB.TBL_CLIENTES c ON u.USUARIO_ID = c.USUARIO_ID
            WHERE u.USUARIO_ID = p_usuario_id;

            v_resultado.exitoso := TRUE;
            v_resultado.mensaje := 'Información obtenida correctamente';

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_resultado.mensaje := 'Usuario no encontrado';
                PROYECTODB.PRC_LOG_ERROR(
                        'AUTENTICACION_PKG.obtener_info_usuario',
                        'Usuario no encontrado con ID: ' || p_usuario_id
                );
            WHEN OTHERS THEN
                v_resultado.mensaje := 'Error al obtener información: ' || SQLERRM;
                PROYECTODB.PRC_LOG_ERROR(
                        'AUTENTICACION_PKG.obtener_info_usuario',
                        'Error: ' || SQLERRM || ' | Usuario ID: ' || p_usuario_id
                );
        END;

        RETURN v_resultado;

    EXCEPTION
        WHEN OTHERS THEN
            v_resultado.mensaje := 'Error general: ' || SQLERRM;
            PROYECTODB.PRC_LOG_ERROR(
                    'AUTENTICACION_PKG.obtener_info_usuario',
                    'Error general: ' || SQLERRM
            );
            RETURN v_resultado;
    END obtener_info_usuario;

    FUNCTION es_superadmin(p_usuario_id IN NUMBER) RETURN BOOLEAN IS
        v_rol_id NUMBER;
    BEGIN
        SELECT ROL_ID INTO v_rol_id
        FROM TBL_USUARIOS
        WHERE USUARIO_ID = p_usuario_id;

        RETURN v_rol_id = 1;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END es_superadmin;

    FUNCTION es_administrador(p_usuario_id IN NUMBER) RETURN BOOLEAN IS
        v_rol_id NUMBER;
    BEGIN
        SELECT ROL_ID INTO v_rol_id
        FROM TBL_USUARIOS
        WHERE USUARIO_ID = p_usuario_id;

        RETURN v_rol_id IN (1, 2);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END es_administrador;

    FUNCTION es_analista(p_usuario_id IN NUMBER) RETURN BOOLEAN IS
        v_rol_id NUMBER;
    BEGIN
        SELECT ROL_ID INTO v_rol_id
        FROM TBL_USUARIOS
        WHERE USUARIO_ID = p_usuario_id;

        RETURN v_rol_id = 3;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END es_analista;

    FUNCTION es_cliente(p_usuario_id IN NUMBER) RETURN BOOLEAN IS
        v_rol_id NUMBER;
    BEGIN
        SELECT ROL_ID INTO v_rol_id
        FROM TBL_USUARIOS
        WHERE USUARIO_ID = p_usuario_id;

        RETURN v_rol_id = 4;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END es_cliente;

END AUTENTICACION_PKG;
/