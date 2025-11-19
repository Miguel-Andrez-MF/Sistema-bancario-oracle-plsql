-- =======================================
-- CONSTRAINTS ADICIONALES
-- =======================================

-- Validar que el saldo no sea negativo
ALTER TABLE PROYECTODB.TBL_CUENTAS
    ADD CONSTRAINT CHK_SALDO_POSITIVO
        CHECK (SALDO >= 0);

-- Validar que el monto de transacción sea positivo
ALTER TABLE PROYECTODB.TBL_TRANSACCIONES
    ADD CONSTRAINT CHK_MONTO_POSITIVO
        CHECK (MONTO > 0);

-- Validar que la identificación sea positiva
ALTER TABLE PROYECTODB.TBL_CLIENTES
    ADD CONSTRAINT CHK_IDENTIFICACION_POSITIVA
        CHECK (IDENTIFICACION > 0);

-- Hacer único el campo IDENTIFICACION (no puede haber clientes duplicados)
ALTER TABLE PROYECTODB.TBL_CLIENTES
    ADD CONSTRAINT UQ_IDENTIFICACION_CLIENTE
        UNIQUE (IDENTIFICACION);

-- Hacer único el campo USUARIO
ALTER TABLE PROYECTODB.TBL_USUARIOS
    ADD CONSTRAINT UQ_USUARIO
        UNIQUE (USUARIO);

-- Hacer único el nombre del rol
ALTER TABLE PROYECTODB.TBL_ROLES
    ADD CONSTRAINT UQ_NOMBRE_ROL
        UNIQUE (NOMBRE);