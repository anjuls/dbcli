/*[[
    Show the data that generated by dbms_profiler. Usage: @@NAME [<runid>] [<sort_by>]
    --[[
        @CHECK_ACCESS: dba_source={DBA_SOURCE}, all_source={ALL_SOURCE}
        @CHECK_ACCESS2: PLSQL_PROFILER_DATA={}
        &V2: default={TOTAL_TIME}
    --]]
]]*/
set feed off
VAR cur REFCURSOR
BEGIN
    IF :V1 IS NULL THEN
        OPEN :cur FOR
            SELECT RUNID,RELATED_RUN,RUN_OWNER,RUN_DATE,RUN_COMMENT,LTRIM(RTRIM(to_char(NUMTODSINTERVAL(RUN_TOTAL_TIME*1E-9,'SECOND')),'0.'),'0+') RUN_TIME,RUN_SYSTEM_INFO,RUN_COMMENT1,SPARE1
            FROM PLSQL_PROFILER_RUNS ORDER BY RUNID DESC;
    ELSE
        OPEN :cur FOR
            WITH SRC AS
             (SELECT /*+MATERIALIZE no_merge(u)*/
                    U.*, EXTRACTVALUE(b.COLUMN_VALUE,'//TEXT') text,EXTRACTVALUE(b.COLUMN_VALUE,'//LINE')+0 line#,EXTRACTVALUE(b.COLUMN_VALUE,'//SUB_NAME') subname
              FROM  (SELECT * FROM PLSQL_PROFILER_UNITS WHERE RUNID = :V1) u,
                     TABLE(XMLSEQUENCE(EXTRACT(dbms_xmlgen.getxmltype(
                         q'[SELECT line,ltrim(TEXT,chr(9)||' ') text,
                                   regexp_substr(regexp_substr(text,'(procedure|function) +[^ \(]+',1,1,'i'),'[^ ]+',1,2) sub_name
                           FROM &CHECK_ACCESS
                           WHERE ']'||UNIT_TYPE ||''' NOT LIKE ''ANONYMOUS%'' AND OWNER=''' ||unit_owner ||
                                ''' AND NAME=''' || unit_name ||
                                ''' AND TYPE=''' || unit_type ||''''),'//ROW')))(+) B),
            rs as(
                SELECT /*+ORDERED use_hash(dat src) MATERIALIZE*/
                         src.unit_owner, src.unit_name, dat.line#, dat.TOTAL_OCCUR,unit_number,
                         rownum r,
                         LTRIM(RTRIM(to_char(NUMTODSINTERVAL(round(dat.TOTAL_TIME * 1E-9,3), 'SECOND')), ':0.'), '0+') TOTAL_TIME,
                         LTRIM(RTRIM(to_char(NUMTODSINTERVAL(round(dat.MIN_TIME * 1E-9,3), 'SECOND')), ':0.'), '0+') MIN_TIME,
                         LTRIM(RTRIM(to_char(NUMTODSINTERVAL(round(dat.MAX_TIME * 1E-9,3), 'SECOND')), ':0.'), '0+') MAX_TIME,
                         src.text
                FROM   PLSQL_PROFILER_DATA dat
                JOIN   src
                USING  (RUNID, UNIT_NUMBER)
                WHERE  RUNID = :V1 AND dat.line#=nvl(src.line#,dat.line#))
            SELECT unit_number unit#,unit_owner,unit_name,subname,line#,total_occur,total_time,min_time ,max_time,text
            FROM(
                SELECT /*+ordered use_hash(rs src)*/
                      rs.*,row_number() over(partition by rs.r order by src.line# desc) seq, src.subname
                FROM rs, src
                WHERE rs.unit_number=src.unit_number(+)
                AND   rs.line#>=src.line#(+)
                AND   src.subname(+) IS NOT NULL
            ) WHERE SEQ=1
            ORDER BY &V2 DESC NULLS LAST;
    END IF;
END;
/
    