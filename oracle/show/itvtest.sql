itv start 5 Checking Active sessions in interval mode, type 'Ctrl + C' to abort
PRO
ora actives
PRO determine if need to abort(10%) ...
var next_action varchar2
set printvar off

begin
    if dbms_random.value(0,10)>9 then
        :next_action := 'off';
    else
        :next_action := 'end';
    end if;
end;
/
pro next_action: itv &next_action
itv &next_action