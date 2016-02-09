SELECT
        /*+ OPT_PARAM('_optimizer_adaptive_plans','false') */
        /*+ NO_MONITOR */
        inid "I#"
        ,ncpu
        ,round( load ,2 ) "OS Load"
        ,round( hcpu ,2 ) "Host CPU%"
        ,round( dcpu ,2 ) "CPU Usage/Sec"
        ,round( dbtm ,0 ) "DB Time/Sec"
        ,round( sgfr ,2 ) "Shared Pool Free%"
        ,round( utps ,2 ) "User Tx/Sec"
        ,round( ucps ,2 ) "User Calls/Sec"
        ,round( saas ,2 ) "AAS"
        ,round( mbps ,2 ) "I/O MB/Sec"
        ,round( logr ,0 ) "Logical Reads/Sec"
        ,round( phyr ,0 ) "Phy Reads/Sec"
        ,round( phyw ,0 ) "Phy Writes/Sec"
        ,round( rgps/1024 ,2 ) "Redo (KB) Per Sec"
        ,round( iops ,0 ) "I/O Request/Sec"
        ,round( ssrt ,2 ) "SQL Svc Resp Time"
        ,round( iorl ,2 ) "I/O Read Latency(ms)"
        ,round( upga / 1024 / 1024 ,2 ) "Total PGA Allocated (MB)"
        ,round( aspq ,0 ) "Active Parallel Sess"
        ,round( dbcp ,2 ) "DB CPU Time Ratio"
        ,round( dbwa ,2 ) "DB Wait Time Ratio"
        ,asct "Active Sessions"
        ,isct "Inactive Sessions"
        ,cpas
        ,ioas
        ,waas
        ,round( temp / 1024 / 1024 ,0 ) "Temp(MB)"
    FROM
        (
            SELECT
                    /*+ OPT_PARAM('_optimizer_adaptive_plans','false') */
                    inst_id inid
                    ,SUM (
                        decode (
                            metric_name
                            ,'CPU Usage Per Sec'
                            ,VALUE
                            ,0
                        )
                    ) dcpu
                    ,SUM (
                        decode (
                            metric_name
                            ,'Host CPU Utilization (%)'
                            ,VALUE
                            ,0
                        )
                    ) hcpu
                    ,SUM (
                        decode (
                            metric_name
                            ,'I/O Megabytes per Second'
                            ,VALUE
                            ,0
                        )
                    ) mbps
                    ,SUM (
                        decode (
                            metric_name
                            ,'SQL Service Response Time'
                            ,VALUE
                            ,0
                        )
                    ) ssrt
                    ,SUM (
                        decode (
                            metric_name
                            ,'Average Synchronous Single-Block Read Latency'
                            ,VALUE
                            ,0
                        )
                    ) iorl
                    ,SUM (
                        decode (
                            metric_name
                            ,'Current OS Load'
                            ,VALUE
                            ,0
                        )
                    ) load
                    ,SUM (
                        decode (
                            metric_name
                            ,'Active Parallel Sessions'
                            ,VALUE
                            ,0
                        )
                    ) aspq
                    ,SUM (
                        decode (
                            metric_name
                            ,'Database CPU Time Ratio'
                            ,VALUE
                            ,0
                        )
                    ) dbcp
                    ,SUM (
                        decode (
                            metric_name
                            ,'Database Wait Time Ratio'
                            ,VALUE
                            ,0
                        )
                    ) dbwa
                    ,SUM (
                        decode (
                            metric_name
                            ,'I/O Requests per Second'
                            ,VALUE
                            ,0
                        )
                    ) iops
                FROM
                    gv$sysmetric
                WHERE
                    metric_name IN (
                        'CPU Usage Per Sec'
                        ,'Host CPU Utilization (%)'
                        ,'I/O Megabytes per Second'
                        ,'SQL Service Response Time'
                        ,'Average Synchronous Single-Block Read Latency'
                        ,'Current OS Load'
                        ,'Active Parallel Sessions'
                        ,'Database CPU Time Ratio'
                        ,'Database Wait Time Ratio'
                        ,'I/O Requests per Second'
                    )
                    AND group_id = 2
                GROUP BY
                    inst_id
        )
        ,(
            SELECT
                    /*+ OPT_PARAM('_optimizer_adaptive_plans','false') */
                    inst_id id1
                    ,SUM (
                        decode (
                            metric_name
                            ,'Shared Pool Free %'
                            ,VALUE
                            ,0
                        )
                    ) sgfr
                    ,SUM (
                        decode (
                            metric_name
                            ,'User Transaction Per Sec'
                            ,VALUE
                            ,0
                        )
                    ) utps
                    ,SUM (
                        decode (
                            metric_name
                            ,'User Calls Per Sec'
                            ,VALUE
                            ,0
                        )
                    ) ucps
                    ,SUM (
                        decode (
                            metric_name
                            ,'Average Active Sessions'
                            ,VALUE
                            ,0
                        )
                    ) saas
                    ,SUM (
                        decode (
                            metric_name
                            ,'Total PGA Allocated'
                            ,VALUE
                            ,0
                        )
                    ) upga
                    ,SUM (
                        decode (
                            metric_name
                            ,'Logical Reads Per Sec'
                            ,VALUE
                            ,0
                        )
                    ) logr
                    ,SUM (
                        decode (
                            metric_name
                            ,'Physical Reads Per Sec'
                            ,VALUE
                            ,0
                        )
                    ) phyr
                    ,SUM (
                        decode (
                            metric_name
                            ,'Physical Writes Per Sec'
                            ,VALUE
                            ,0
                        )
                    ) phyw
                    ,SUM (
                        decode (
                            metric_name
                            ,'Temp Space Used'
                            ,VALUE
                            ,0
                        )
                    ) temp
                    ,SUM (
                        decode (
                            metric_name
                            ,'Database Time Per Sec'
                            ,VALUE
                            ,0
                        )
                    ) dbtm
                    ,SUM (
                        decode (
                            metric_name
                            ,'Redo Generated Per Sec'
                            ,VALUE
                            ,0
                        )
                    ) rgps
                FROM
                    gv$sysmetric
                WHERE
                    metric_name IN (
                        'Shared Pool Free %'
                        ,'User Transaction Per Sec'
                        ,'User Calls Per Sec'
                        ,'Logical Reads Per Sec'
                        ,'Physical Reads Per Sec'
                        ,'Physical Writes Per Sec'
                        ,'Temp Space Used'
                        ,'Database Time Per Sec'
                        ,'Average Active Sessions'
                        ,'Total PGA Allocated'
                        ,'Redo Generated Per Sec'
                    )
                    AND group_id = 3
                GROUP BY
                    inst_id
        )
        ,(
            SELECT
                    id2
                    ,SUM (asct) asct
                    ,SUM (isct) isct
                    ,SUM (cpas) cpas
                    ,SUM (ioas) ioas
                    ,SUM (waas) waas
                FROM
                    (
                        SELECT
                                /*+ OPT_PARAM('_optimizer_adaptive_plans','false') */
                                inst_id id2
                                ,SUM (
                                    DECODE (
                                        status
                                        ,'ACTIVE'
                                        ,1
                                        ,0
                                    )
                                ) asct
                                ,COUNT (*) isct
                                ,SUM (
                                    DECODE (
                                        status
                                        ,'ACTIVE'
                                        ,decode (
                                            WAIT_TIME
                                            ,0
                                            ,0
                                            ,1
                                        )
                                        ,0
                                    )
                                ) cpas
                                ,SUM (
                                    DECODE (
                                        status
                                        ,'ACTIVE'
                                        ,decode (
                                            wait_class
                                            ,'User I/O'
                                            ,1
                                            ,0
                                        )
                                        ,0
                                    )
                                ) ioas
                                ,SUM (
                                    DECODE (
                                        status
                                        ,'ACTIVE'
                                        ,decode (
                                            WAIT_TIME
                                            ,0
                                            ,decode (
                                                wait_class
                                                ,'User I/O'
                                                ,0
                                                ,1
                                            )
                                            ,0
                                        )
                                        ,0
                                    )
                                ) waas
                            FROM
                                gv$session
                            WHERE
                                type <> 'BACKGROUND'
                                AND username IS NOT NULL
                                AND SCHEMA# ! = 0
                            GROUP BY
                                inst_id
                        UNION
                        ALL SELECT
                                /*+ OPT_PARAM('_optimizer_adaptive_plans','false') */
                                inst_id id2
                                ,0 asct
                                ,0 isct
                                ,0 cpas
                                ,0 ioas
                                ,0 waas
                            FROM
                                gv$instance
                    )
                GROUP BY
                    id2
        )
        ,(
            SELECT
                    /*+ OPT_PARAM('_optimizer_adaptive_plans','false') */
                    inst_id id3
                    ,TO_NUMBER( VALUE ) ncpu
                FROM
                    gv$osstat
                WHERE
                    stat_name = 'NUM_CPUS'
        )
    WHERE
        id1 = inid
        AND id2 = inid
        AND id3 = inid
        AND ROWNUM <= 5
    ORDER BY
        dbtm DESC
;
