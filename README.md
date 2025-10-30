# 🏦 Sistema de Gestión Bancaria - Oracle PL/SQL

![Oracle](https://img.shields.io/badge/Oracle-F80000?style=for-the-badge&logo=oracle&logoColor=white)
![PL/SQL](https://img.shields.io/badge/PL%2FSQL-F80000?style=for-the-badge&logo=oracle&logoColor=white)
![Status](https://img.shields.io/badge/Status-Entrega%201%20Completada-green?style=for-the-badge)
![License](https://img.shields.io/badge/License-Academic-blue?style=for-the-badge)

Sistema bancario completo implementado en Oracle Database con PL/SQL, desarrollado como proyecto académico para la materia de Bases de Datos I.

## 📋 Descripción

Sistema de gestión bancaria que permite administrar clientes, cuentas y transacciones con validaciones automáticas, auditoría y registro de errores mediante triggers y procedimientos almacenados.

---

## 📦 Entregas del Proyecto

### 🟢 Entrega 1 - COMPLETADA (50% del Proyecto)

#### Entregables:
- [x] **Diagrama MER** del sistema bancario en formato PDF o imagen de alta calidad
- [x] **Script DDL completo** para tablas bancarias (`2-Tablas.sql`)
- [x] **Triggers PL/SQL**: `trg_valida_transaccion_retiro` y `trg_auditoria_transacciones` completos
- [x] **Script de datos de prueba** bancarios
- [x] **Documento de diseño** explicando arquitectura del sistema bancario
- [x] **Scripts de prueba** para validar funcionamiento de paquetes PL/SQL

#### Implementado:
- ✅ 7 Tablas principales con constraints completos
- ✅ Secuencias para generación automática de IDs
- ✅ 2 Triggers de validación y auditoría
- ✅ Procedimiento de logging de errores
- ✅ Datos de prueba con múltiples escenarios

---

### 🟡 Entrega 2 - EN PROCESO (25% del Proyecto)

#### Entregables:
- [ ] **Paquetes PL/SQL bancarios** implementados y documentados
  - `gestion_transacciones_pkg`
  - `autenticacion_pkg`
- [ ] **Funciones de autenticación y validación** con casos de prueba
  - Función `validar_credenciales`
  - Sistema de login seguro
- [ ] **Triggers de validación y auditoría bancaria**
  - Validaciones adicionales de negocio
  - Auditoría completa de operaciones
- [ ] **Scripts de administración**
  - Gestión de usuarios bancarios
  - Asignación de roles
  - Configuración de seguridad
- [ ] **Suite completa de pruebas** de transacciones bancarias
  - Pruebas de depósitos
  - Pruebas de retiros
  - Pruebas de transferencias

#### Por implementar:
- ⏳ Procedimiento `realizar_transferencia`
- ⏳ Función `generar_historial`
- ⏳ Sistema de autenticación completo
- ⏳ Gestión avanzada de permisos

---

### ⚪ Entrega 3 - PENDIENTE (25% del Proyecto)

#### Preparación del Sistema Bancario:
- [ ] **Preparar demo de operaciones bancarias**
  - Demostración de depósitos
  - Demostración de retiros
  - Demostración de transferencias
- [ ] **Explicar arquitectura del MER bancario**
  - Relaciones entre entidades
  - Justificación del diseño
- [ ] **Demostrar funcionamiento de paquetes PL/SQL**
  - Ejecución en vivo de procedimientos
  - Validación de triggers
- [ ] **Mostrar sistema de auditoría**
  - Trazabilidad de transacciones
  - Consultas de auditoría
- [ ] **Practicar respuestas sobre seguridad**
  - Manejo de errores bancarios
  - Validaciones implementadas
  - Integridad de datos

#### Entregables finales:
- ⏳ Presentación ejecutiva del sistema
- ⏳ Documentación técnica completa
- ⏳ Manual de usuario
- ⏳ Video demo del sistema (opcional)

---

## 🎯 Características Principales

### ✅ Implementado - Entrega 1

- **Modelo Entidad-Relación (MER)** completo
- **7 Tablas principales:**
  - Clientes
  - Cuentas
  - Transacciones
  - Usuarios
  - Roles
  - Tipos de Parámetros
  - Auditoría de Transacciones
  - Log de Errores

- **Triggers implementados:**
  - `TRG_VALIDA_TRANSACCION_RETIRO`: Valida retiros antes de insertarlo.
  - `TRG_INSERTAR_AUDITORIAS`: Registra automáticamente cada operación en la tabla de auditoría.