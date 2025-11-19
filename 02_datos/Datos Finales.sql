////////////////////////////////////////////////////////////////////////////////////////////////////// REINICIAR COUNT USUARIO


DROP SEQUENCE PROYECTODB.SEQ_USUARIO;

CREATE SEQUENCE PROYECTODB.SEQ_USUARIO
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;


////////////////////////////////////////////////////////////////////////////////////////////////////// CREAR USUARIOS

DECLARE
    v_cant_usuarios NUMBER := 1000; -- cantidad de usuarios a generar
    v_usuario_id    NUMBER;
    v_rol_id        NUMBER := 3;
    v_usuario       VARCHAR2(50);
    v_password      VARCHAR2(50);

    TYPE t_array IS TABLE OF VARCHAR2(30);
  v_prefijos  SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
    'Fin','Bank','Safe','Cred','Trust','Core','First','Prime','Union','Smart',
    'Global','Secure','Nation','Metro','Next','Capital','Delta','Advance','Future','Urban',
    'Apex','Vantage','Alpha','Beta','Summit','Focus','Peak','Vertex','Optima','Civic',
    'Orbit','Central','Valor','Silver','Golden','Ever','True','Blue','Vision','Quantum',
    'Stream','Vertex','Solid','Bright','Claro','Nova','Credix','Max','Neon','Allied'
  );

  v_sufijos   SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
    'corp','net','sys','data','pay','hub','flow','fund','serv','one',
    'ops','line','zone','plus','bank','safe','cred','link','core','base',
    'tech','soft','key','logic','form','trust','map','point','grid','byte',
    'dash','prime','unit','cast','mark','gate','chain','rise','path','mode',
    'root','cube','gen','ware','sync','scope','beam','node','logic','edge'
  );
BEGIN
    FOR i IN 1..v_cant_usuarios LOOP
        -- obtener siguiente ID
        v_usuario_id := PROYECTODB.SEQ_USUARIO.NEXTVAL;

        -- combinar prefijo y sufijo aleatorio
        v_usuario := LOWER(
            v_prefijos(TRUNC(DBMS_RANDOM.VALUE(1, v_prefijos.COUNT + 1))) ||
            v_sufijos(TRUNC(DBMS_RANDOM.VALUE(1, v_sufijos.COUNT + 1)))
        );

        -- agregar un separador y el ID (garantiza unicidad absoluta)
        v_usuario := v_usuario || '_' || TO_CHAR(v_usuario_id);

        -- generar contraseña mixta
        v_password :=
            SUBSTR(DBMS_RANDOM.STRING('A', 1), 1) ||
            TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000, 9999))) ||
            SUBSTR(DBMS_RANDOM.STRING('A', 2), 1);

        -- insertar
        INSERT INTO PROYECTODB.TBL_USUARIOS (USUARIO_ID, ROL_ID, USUARIO, PASSWORD)
        VALUES (v_usuario_id, v_rol_id, v_usuario, v_password);
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE(v_cant_usuarios || ' usuarios únicos tipo alias generados correctamente.');
END;
/
////////////////////////////////////////////////////////////////////////////////////////////////////// REINICIAR COUNT CLIENTE

DROP SEQUENCE PROYECTODB.SEQ_CLIENTE;

CREATE SEQUENCE PROYECTODB.SEQ_CLIENTE
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

////////////////////////////////////////////////////////////////////////////////////////////////////// CREAR CLIENTES

DECLARE
  -- Listas de nombres y apellidos
  v_nombres   SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
    'Santiago','Valeria','Mateo','Isabella','Sebastián','Mariana','Daniel','Camila',
    'Juan','Sara','Andrés','Laura','Nicolás','Lucía','Tomás','Ana','Felipe','Martina',
    'David','Paula','Emilio','Carolina','Samuel','Renata','Adrián','Julieta','Gabriel','Manuela',
    'Cristian','Antonia','Bruno','Mía','Simón','Sofía','Pablo','Elena','Axel','Valentina'
  );

  v_apellidos SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
    'Montenegro','Ruales','Gómez','Rodríguez','Martínez','García','López','Pérez',
    'Torres','Hernández','Vargas','Ramírez','Muñoz','Rojas','Suárez','Moreno',
    'Jiménez','Castro','Reyes','Mendoza','Romero','Cruz','Cortés','Navarro',
    'Guerrero','Ortega','Silva','Campos','Ruiz','Velasco','Trujillo','Palacios',
    'Valencia','Patiño','Salazar','Escobar','Zapata','Peña','Cárdenas','Mora'
  );

  v_calles SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
    'Cra.','Cl.','Av.','Tv.','Diag.'
  );

  v_email_dominios SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
    'gmail.com','hotmail.com','yahoo.com','outlook.com','proton.me','icloud.com'
  );

  v_nombre         VARCHAR2(100);
  v_identificacion VARCHAR2(15);
  v_direccion      VARCHAR2(200);
  v_usuario_id     NUMBER;
  v_telefono       VARCHAR2(15);
  v_email          VARCHAR2(120);
  v_fecha_reg      DATE;
  v_cliente_id     VARCHAR2(20);
  v_count          NUMBER := 0;
  v_total          NUMBER := 1001;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Generando clientes aleatorios ---');
  FOR i IN 6..1006 LOOP
    v_cliente_id := 'CLI-' || TO_CHAR(PROYECTODB.SEQ_CLIENTE.NEXTVAL);
    
    -- Nombre completo
    v_nombre := v_nombres(TRUNC(DBMS_RANDOM.VALUE(1, v_nombres.COUNT+1))) || ' ' ||
                v_apellidos(TRUNC(DBMS_RANDOM.VALUE(1, v_apellidos.COUNT+1))) || ' ' ||
                v_apellidos(TRUNC(DBMS_RANDOM.VALUE(1, v_apellidos.COUNT+1)));

    -- Cédula aleatoria
    v_identificacion := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000000000,9999999999)));

    -- Dirección aleatoria
    v_direccion := v_calles(TRUNC(DBMS_RANDOM.VALUE(1, v_calles.COUNT+1))) || ' ' ||
                   TRUNC(DBMS_RANDOM.VALUE(1, 100)) || ' #' ||
                   TRUNC(DBMS_RANDOM.VALUE(1, 50)) || '-' ||
                   TRUNC(DBMS_RANDOM.VALUE(1, 100));

    -- Usuario asociado (6 a 1006)
    v_usuario_id := i;

    -- Número telefónico colombiano (empieza por 3 y tiene 10 dígitos)
    v_telefono := '3' || TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(100000000, 999999999)));

    -- Email coherente con el nombre
    v_email := LOWER(
                  REPLACE(SUBSTR(v_nombre, 1, INSTR(v_nombre, ' ')-1), ' ', '') ||
                  TRUNC(DBMS_RANDOM.VALUE(10,9999)) || '@' ||
                  v_email_dominios(TRUNC(DBMS_RANDOM.VALUE(1, v_email_dominios.COUNT+1)))
               );

    -- Fecha aleatoria entre 2024-01-01 y 2025-10-29
    v_fecha_reg := DATE '2024-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, (DATE '2025-10-29' - DATE '2024-01-01')));

    BEGIN
      INSERT INTO TBL_CLIENTES (CLIENTE_ID, NOMBRE, IDENTIFICACION, DIRECCION, USUARIO_ID, TELEFONO, EMAIL, FECHA_REGISTRO)
      VALUES (v_cliente_id, v_nombre, v_identificacion, v_direccion, v_usuario_id, v_telefono, v_email, v_fecha_reg);
      v_count := v_count + 1;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        NULL; -- evita duplicados en identificación o email
    END;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Clientes generados: ' || v_count);
END;
/

////////////////////////////////////////////////////////////////////////////////////////////////////// REINICIAR SECUENCIA CUENTA

DROP SEQUENCE PROYECTODB.SEQ_CUENTA;

CREATE SEQUENCE PROYECTODB.SEQ_CUENTA
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

////////////////////////////////////////////////////////////////////////////////////////////////////// CREAR CUENTA

DECLARE
  v_cuenta_id      VARCHAR2(20);
  v_cliente_id     VARCHAR2(20);
  v_tipo_cuenta_id NUMBER;
  v_estado_id      NUMBER := 4;
  v_saldo          NUMBER;
  v_fecha_apertura DATE;
  v_count          NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Generando cuentas de clientes ---');
  
  FOR i IN 1..1000 LOOP
    -- ID de cuenta
    v_cuenta_id := 'CTA-' || TO_CHAR(PROYECTODB.SEQ_CUENTA.NEXTVAL);
    
    -- ID del cliente correspondiente
    v_cliente_id := 'CLI-' || TO_CHAR(i);
    
    -- Tipo de cuenta aleatorio: 1 = ahorro, 2 = corriente, 3 = nómina (por ejemplo)
    v_tipo_cuenta_id := TRUNC(DBMS_RANDOM.VALUE(1,4));
    
    -- Saldo aleatorio entre 0 y 50 millones (puedes ajustar)
    v_saldo := ROUND(DBMS_RANDOM.VALUE(0, 50000000), 2);
    
    -- Fecha de apertura aleatoria entre 24/abr/2025 y 29/oct/2025
    v_fecha_apertura := DATE '2025-04-24' + TRUNC(DBMS_RANDOM.VALUE(0, (DATE '2025-10-29' - DATE '2025-04-24')));

    INSERT INTO PROYECTODB.TBL_CUENTAS (CUENTA_ID, CLIENTE_ID, TIPO_CUENTA_ID, ESTADO_ID, SALDO, FECHA_APERTURA)
    VALUES (v_cuenta_id, v_cliente_id, v_tipo_cuenta_id, v_estado_id, v_saldo, v_fecha_apertura);
    
    v_count := v_count + 1;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Cuentas generadas: ' || v_count);
END;
/

////////////////////////////////////////////////////////////////////////////////////////////////////// CREAR 20 ANALISTAS

BEGIN
    FOR i IN 0..19 LOOP
        INSERT INTO PROYECTODB.TBL_USUARIOS (
            USUARIO_ID,
            ROL_ID,
            USUARIO,
            PASSWORD
        )
        VALUES (
            1001 + i,
            2,
            CASE i
                WHEN 0 THEN 'analista_datos'
                WHEN 1 THEN 'data_mind'
                WHEN 2 THEN 'metric_master'
                WHEN 3 THEN 'info_watcher'
                WHEN 4 THEN 'vision_num'
                WHEN 5 THEN 'trend_analyst'
                WHEN 6 THEN 'report_genius'
                WHEN 7 THEN 'insight_seeker'
                WHEN 8 THEN 'query_runner'
                WHEN 9 THEN 'data_hunter'
                WHEN 10 THEN 'metric_eye'
                WHEN 11 THEN 'analyst_core'
                WHEN 12 THEN 'dataflow_expert'
                WHEN 13 THEN 'pattern_finder'
                WHEN 14 THEN 'num_researcher'
                WHEN 15 THEN 'vision_data'
                WHEN 16 THEN 'data_navigator'
                WHEN 17 THEN 'analytic_mind'
                WHEN 18 THEN 'smart_query'
                WHEN 19 THEN 'info_mapper'
            END,
            CASE i
                WHEN 0 THEN 'Datos2025*'
                WHEN 1 THEN 'Mind@123'
                WHEN 2 THEN 'Metric#9'
                WHEN 3 THEN 'WatcherX!'
                WHEN 4 THEN 'Vision_24'
                WHEN 5 THEN 'Trend$$'
                WHEN 6 THEN 'Report++'
                WHEN 7 THEN 'Insight_7'
                WHEN 8 THEN 'Runner88'
                WHEN 9 THEN 'Hunter2024'
                WHEN 10 THEN 'Eye_44'
                WHEN 11 THEN 'CoreData*'
                WHEN 12 THEN 'Flow@45'
                WHEN 13 THEN 'Finder_2'
                WHEN 14 THEN 'Research#1'
                WHEN 15 THEN 'Data_09'
                WHEN 16 THEN 'Navigator!'
                WHEN 17 THEN 'Analytic*'
                WHEN 18 THEN 'Smart_33'
                WHEN 19 THEN 'MapperX_'
            END
        );
    END LOOP;
    COMMIT;
END;
/

////////////////////////////////////////////////////////////////////////////////////////////////////// CREAR 5 ADMINISTRADORES

BEGIN
    FOR i IN 0..4 LOOP
        INSERT INTO PROYECTODB.TBL_USUARIOS (
            USUARIO_ID,
            ROL_ID,
            USUARIO,
            PASSWORD
        )
        VALUES (
            1021 + i,
            1,
            CASE i
                WHEN 0 THEN 'admin_master'
                WHEN 1 THEN 'root_control'
                WHEN 2 THEN 'sys_guardian'
                WHEN 3 THEN 'main_admin'
                WHEN 4 THEN 'core_leader'
            END,
            CASE i
                WHEN 0 THEN 'Root#2025'
                WHEN 1 THEN 'Ctrl@Sys'
                WHEN 2 THEN 'Secure!Adm'
                WHEN 3 THEN 'Main*Root'
                WHEN 4 THEN 'Core@Lead'
            END
        );
    END LOOP;
    COMMIT;
END;
/

////////////////////////////////////////////////////////////////////////////////////////////////////// TRANSACCIONES

DECLARE
  v_cuenta_id VARCHAR2(20);
  v_monto NUMBER;
  v_fecha DATE;
  v_total_transacciones NUMBER := 0;
  v_trans_por_cuenta NUMBER;
  v_tipo_transac CONSTANT NUMBER := 7; -- 7 = Depósito
BEGIN
  FOR i IN 1..800 LOOP
    v_cuenta_id := 'CTA-' || TO_CHAR(i);

    -- Determinar cuántas transacciones tendrá esta cuenta
    IF i <= 400 THEN
      v_trans_por_cuenta := 1;
    ELSIF i <= 700 THEN
      v_trans_por_cuenta := 2;
    ELSE
      v_trans_por_cuenta := 3;
    END IF;

    FOR j IN 1..v_trans_por_cuenta LOOP
      EXIT WHEN v_total_transacciones >= 1200;

      -- Generar monto aleatorio entre 50,000 y 5,000,000
      v_monto := TRUNC(DBMS_RANDOM.VALUE(50000, 5000000));

      -- Generar fecha aleatoria entre los últimos 10 días
      v_fecha := TRUNC(SYSDATE - DBMS_RANDOM.VALUE(0, 10));

      -- Insertar transacción tipo "Depósito"
      INSERT INTO PROYECTODB.TBL_TRANSACCIONES (
        TRANSACCION_ID,
        CUENTA_ID,
        TIPO_TRANSAC_ID,
        MONTO,
        FECHA_TRANSAC
      ) VALUES (
        PROYECTODB.SEQ_TRANSACCION.NEXTVAL,
        v_cuenta_id,
        v_tipo_transac,
        v_monto,
        v_fecha
      );

      -- Actualizar el saldo de la cuenta
      UPDATE PROYECTODB.TBL_CUENTAS
      SET SALDO = NVL(SALDO, 0) + v_monto
      WHERE CUENTA_ID = v_cuenta_id;

      v_total_transacciones := v_total_transacciones + 1;
    END LOOP;
  END LOOP;

  COMMIT;
END;
/

