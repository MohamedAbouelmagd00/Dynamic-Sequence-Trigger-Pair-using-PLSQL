DECLARE
    CURSOR tables_cursor IS
    -- u_c user_constraints -- u_c_c user_cons_columns -- u_t_c user_tab_columns
        SELECT DISTINCT U_C.table_name, U_C_C.column_name, U_T_C.data_type
            FROM         user_constraints U_C
            INNER JOIN   user_cons_columns U_C_C 
                ON           U_C.TABLE_NAME           = U_C_C.TABLE_NAME
                AND          U_C.CONSTRAINT_NAME      = U_C_C.CONSTRAINT_NAME
            INNER JOIN   user_tab_columns U_T_C 
                ON           U_T_C.TABLE_NAME         = U_C.TABLE_NAME
            WHERE          UPPER( U_T_C.DATA_TYPE)       = UPPER('NUMBER')
            AND            UPPER(U_C.CONSTRAINT_TYPE)    = UPPER('P')
            AND               U_C_C.COLUMN_NAME NOT IN 
                                ('START_DATE', 'JOB_ID', 'COUNTRY_ID');
col_max number(8,2);
check_sequence number(7,2);

BEGIN
    FOR tables_record IN tables_cursor
        LOOP
        
        
            EXECUTE IMMEDIATE ' SELECT ( NVL(MAX( ' ||tables_record.column_name||' ),0) +1) 
                                                FROM ' || tables_record.table_name
                                                INTO col_max;
                                                
            SELECT count(*)
            INTO check_sequence
            FROM USER_SEQUENCES
            WHERE SEQUENCE_NAME = tables_record.table_name||'_SEQ';
            
            IF check_sequence = 0
            THEN
                    EXECUTE IMMEDIATE
                       ' CREATE SEQUENCE '||tables_record.table_name||'_SEQ '||
                                            ' START WITH ' || col_max;
            ELSE
                   EXECUTE IMMEDIATE 
                        ' DROP SEQUENCE '||tables_record.table_name||'_SEQ';
                   EXECUTE IMMEDIATE 
                        ' CREATE SEQUENCE '||tables_record.table_name||'_SEQ '||
                                                    ' START WITH ' || col_max 
                                            ||' INCREMENT BY ' || 1;
            END IF;
--SELECT (NVL(MAX( tables_record.column_name ),0) + 1) FROM tables_record.table_name ;  
         EXECUTE IMMEDIATE                    
                     ' CREATE OR REPLACE TRIGGER ' || tables_record.table_name ||'_SEQ_TRG'
                 ||' BEFORE INSERT ON '|| tables_record.table_name
                 ||' FOR EACH ROW '
                 ||' BEGIN '
                 ||' :NEW.'||tables_record.column_name ||' := ' || tables_record.table_name|| '_SEQ.NEXTVAL; '
                 ||'  END; ';
        END LOOP;

END;
show errors