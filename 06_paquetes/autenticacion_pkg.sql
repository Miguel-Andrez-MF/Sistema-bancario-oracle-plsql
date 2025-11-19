-- =======================================
-- ESPECIFICACIÓN DEL PAQUETE
-- =======================================
CREATE OR REPLACE PACKAGE PROYECTODB.AUTENTICACION_PKG IS
    
    -- Tipo de retorno para la función de validación
    TYPE t_resultado_auth IS RECORD (
        exitoso        BOOLEAN,
        usuario_id     NUMBER,
        cliente_id     VARCHAR2(20),
        nombre_usuario VARCHAR2(20),
        rol_id         NUMBER,
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
    
END AUTENTICACION_PKG;
/

-- =======================================
-- CUERPO DEL PAQUETE
-- =======================================
CREATE OR REPLACE PACKAGE BODY PROYECTODB.AUTENTICACION_PKG IS
    
    -- Constantes para mensajes
    c_usuario_no_existe    CONSTANT VARCHAR2(100) := 'Usuario no existe';
    c_password_incorrecta  CONSTANT VARCHAR2(100) := 'Contraseña incorrecta';
    c_auth_exitosa         CONSTANT VARCHAR2(100) := 'Autenticación exitosa';
    c_error_validacion     CONSTANT VARCHAR2(100) := 'Error durante validación';
    c_parametros_invalidos CONSTANT VARCHAR2(100) := 'Usuario o contraseña vacíos';
    
    -- =======================================
    -- FUNCIÓN: Validar Credenciales
    -- =======================================
    FUNCTION validar_credenciales(
        p_usuario  IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN t_resultado_auth IS
        
        v_resultado        t_resultado_auth;
        v_usuario_id       NUMBER;
        v_password_bd      VARCHAR2(20);
        v_rol_id           NUMBER;
        v_cliente_id       VARCHAR2(20);
        v_usuario_count    NUMBER := 0;
        
    BEGIN
        -- Inicializar resultado
        v_resultado.exitoso := FALSE;
        v_resultado.usuario_id := NULL;
        v_resultado.cliente_id := NULL;
        v_resultado.nombre_usuario := NULL;
        v_resultado.rol_id := NULL;
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
        
        -- Obtener datos del usuario y validar contraseña
        BEGIN
            SELECT 
                USUARIO_ID,
                PASSWORD,
                ROL_ID
            INTO 
                v_usuario_id,
                v_password_bd,
                v_rol_id
            FROM PROYECTODB.TBL_USUARIOS
            WHERE UPPER(USUARIO) = UPPER(TRIM(p_usuario));
            
            -- Validar contraseña
            IF v_password_bd != p_password THEN
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
                -- El usuario no tiene cliente asociado (puede ser admin/empleado)
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
    
    -- =======================================
    -- FUNCIÓN: Obtener Info Usuario
    -- =======================================
    FUNCTION obtener_info_usuario(
        p_usuario_id IN NUMBER
    ) RETURN t_resultado_auth IS
        
        v_resultado t_resultado_auth;
        
    BEGIN
        -- Inicializar resultado
        v_resultado.exitoso := FALSE;
        v_resultado.usuario_id := NULL;
        v_resultado.cliente_id := NULL;
        v_resultado.nombre_usuario := NULL;
        v_resultado.rol_id := NULL;
        v_resultado.mensaje := NULL;
        
        -- Validar parámetro
        IF p_usuario_id IS NULL THEN
            v_resultado.mensaje := 'ID de usuario inválido';
            RETURN v_resultado;
        END IF;
        
        -- Obtener información del usuario
        BEGIN
            SELECT 
                u.USUARIO_ID,
                u.USUARIO,
                u.ROL_ID,
                c.CLIENTE_ID
            INTO 
                v_resultado.usuario_id,
                v_resultado.nombre_usuario,
                v_resultado.rol_id,
                v_resultado.cliente_id
            FROM PROYECTODB.TBL_USUARIOS u
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
    
END AUTENTICACION_PKG;
/