SELECT 
    t.tablespace_name,
    f.file_name,
    ROUND(f.bytes/1024/1024, 2) AS size_MB,
    f.autoextensible,
    f.status
FROM 
    dba_tablespaces t
JOIN 
    dba_data_files f 
ON 
    t.tablespace_name = f.tablespace_name
ORDER BY 
    t.tablespace_name;



lsnrctl status
