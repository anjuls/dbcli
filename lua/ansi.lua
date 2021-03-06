local rawget,env=rawget,env
local ansi={}
local cfg
local reader,writer,str_completer,arg_completer,add=reader
local terminal=reader:getTerminal()
local isAnsiSupported=terminal:isAnsiSupported()


local enabled=isAnsiSupported

--Color definitions from MUD, not all features are support in Ansicon/Jansi library
local base_color={
    --For the ansi controls that have parameter, used '$<code>[,parameters]$' format
    --For example: $SET,1,2$ 
    SET        =function(r,c) return "\27["..r..";"..c.."H" end, --'Set Cursor position, Usage: SET,<n rows>,<n cols>'
--  FRSCREEN   =function(a,b) return"\27["..a..";"..b.."r" end,
--  FR         =function(a) return "\27["..a.."r" end,
    DELLINE    ={"\27[1K\27[1G",'Erase the whole line',1},
    DELAFT     ={"\27[0K",'Erase from cursor to the end of line',1},


    --Foreground Colors
    BLK={"\27[0;30m","Foreground Color: Black"},
    RED={"\27[0;31m","Foreground Color: Red"},
    GRN={"\27[0;32m","Foreground Color: Green"},
    YEL={"\27[0;33m","Foreground Color: Yellow"},
    BLU={"\27[0;34m","Foreground Color: Blue"},
    MAG={"\27[0;35m","Foreground Color: Magenta"},
    CYN={"\27[0;36m","Foreground Color: Cyan"},
    WHT={"\27[0;37m","Foreground Color: White"},
    GRY={"\27[30;1;40m","Foreground Color: Gray"}, 

    --High Intensity Foreground Colors
   --BG Light gray
    
    HIR={"\27[31;1m","High Intensity Foreground Color: Red"},
    HIG={"\27[32;1m","High Intensity Foreground Color: Green"},
    HIY={"\27[33;1m","High Intensity Foreground Color: Yellow"},
    HIB={"\27[34;1m","High Intensity Foreground Color: Blue"},
    HIM={"\27[35;1m","High Intensity Foreground Color: Magenta"},
    HIC={"\27[36;1m","High Intensity Foreground Color: Cyan"},
    HIW={"\27[37;1m","High Intensity Foreground Color: White"},

    --High Intensity Background Colors
    HBRED={"\27[4;41m","High Intensity Background Color: Red"},
    HBGRN={"\27[4;42m","High Intensity Background Color: Green"},
    HBYEL={"\27[4;43m","High Intensity Background Color: Yellow"},
    HBBLU={"\27[4;44m","High Intensity Background Color: Blue"},
    HBMAG={"\27[4;45m","High Intensity Background Color: Magenta"},
    HBCYN={"\27[4;46m","High Intensity Background Color: Cyan"},
    HBWHT={"\27[4;47m","High Intensity Background Color: White"},

    

    --Background Colors
    BBLK={"\27[40m","Background Color: Black"},
    BRED={"\27[41m","Background Color: Red"},
    BGRN={"\27[42m","Background Color: Green"},
    BYEL={"\27[43m","Background Color: Yellow"},
    BBLU={"\27[44m","Background Color: Blue"},
    BMAG={"\27[45m","Background Color: Magenta"},
    BCYN={"\27[46m","Background Color: Cyan"},
    BWHT={"\27[47m","Background Color: White"},
    BGRY={"\27[4;40m","Background Color: Gray"}, 
    NOR ={"\27[0m","Puts every color back to normal"},


    --Additional ansi Esc codes added to ansi.h by Gothic  april 23,1993
    --Note, these are Esc codes for VT100 terminals, and emmulators
    --and they may not all work within the mud
    BOLD    ={"\27[1m","Turn on bold mode",0},
    CLR     ={"\27[2J","Clear the screen",1},
    HOME    ={"\27[H","Send cursor to home position",1},
    REF     ={"\27[2J;H" , "Clear screen and home cursor",1},
    BIGTOP  ={"\27#3","Dbl height characters, top half",1},
    BIGBOT  ={"\27#4","Dbl height characters, bottem half",1},
    SAVEC   ={"\27[s","Save cursor position",1},
    REST    ={"\27[u","Restore cursor to saved position",1},
 -- REVINDEX={"\27M","Scroll screen in opposite direction",1},
 -- SINGW   ={"\27#5","Normal, single-width characters",1},
 -- DBL     ={"\27#6","Creates double-width characters",1},
 -- FRTOP   ={"\27[2;25r","Freeze top line",1},
 -- FRBOT   ={"\27[1;24r","Freeze bottom line",1},
 -- UNFR    ={"\27[r","Unfreeze top and bottom lines",1},
    BLINK   ={"\27[5m","Blink on",0},
    UBLNK   ={"\27[25m","Blink off",0},
    UDL     ={"\27[4m","Underline on",0},
    UUDL    ={"\27[24m","Underline off",0},
    REV     ={"\27[7m","Reverse video mode on",1},
    UREV    ={"\27[27m","Reverse video mode off",1},
    CONC    ={"\27[8m","Concealed(foreground becomes background)",1},
    uCONC   ={"\27[28m","Concealed off",1},
    HIREV   ={"\27[1,7m","High intensity reverse video",1},
    WRAP    ={"\27[?7h","Wrap lines at screen edge",1},
    UNWRAP  ={"\27[?7l","Don't wrap lines at screen edge",1}
}

local default_color={
    ['0']={'BBLK','BLK'},
    ['1']={'BBLU','BLU'},
    ['2']={'BGRN','GRN'},
    ['3']={'BCYN','CYN'},
    ['4']={'BRED','RED'},
    ['5']={'BMAG','MAG'},
    ['6']={'BYEL','YEL'},
    ['7']={'BGRY','WHT'},
    ['8']={'BWHT','GRY'},
    ['9']={'HBBLU','HIB'},
    ['A']={'HBGRN','HIG'},
    ['B']={'HBCYN','HIC'},
    ['C']={'HBRED','HIR'},
    ['D']={'HBMAG','HIM'},
    ['E']={'HBYEL','HIY'},
    ['F']={'HBWHT','HIW'},
}

ansi.ansi_mode=os.getenv("ANSICON_DEF")
local console_color=os.getenv("CONSOLE_COLOR")
if console_color then
    ansi.ansi_default=console_color
    local fg,bg=default_color[console_color:sub(2)][2],default_color[console_color:sub(1,1)][1]
    if bg and fg then
        base_color['NOR'][1]=base_color['NOR'][1]..base_color[fg][1]..base_color[bg][1]
    end
end

if not ansi.ansi_mode then
    ansi.ansi_mode="jline"
else
    ansi.ansi_mode="ansicon"
    isAnsiSupported=true
end


local color=setmetatable({},{__index=function(self,k) return rawget(self,k:upper()) end})

function ansi.cfg(name,value,module,description)
    if not cfg then cfg={} end
    if not name then return cfg end
    if not cfg[name] then cfg[name]={} end
    if not value then return cfg[name][1] end
    cfg[name][1]=value
    if description then
        cfg[name][2]=module
        cfg[name][3]=description
        cfg[name][4]=value
    end
end

function ansi.string_color(code,...)
    if not code then return end
    local c=color[code:upper()]
    if not c then return end
    if type(c)=="table" then return c[1] end
    local v1,v2=select(1,...) or '',select(2,...) or ''
    if type(c)=="function" then return c(v1~='' and v1 or 1,v2~='' and v2 or 1) end
    return c
end

function ansi.mask(codes,msg,continue)
    local str
    for v in codes:gmatch("([^; \t,]+)") do
        v=v:upper()
        local c=ansi.string_color(v)
        if not c then
            v=ansi.cfg(v)
            if v then return ansi.mask(v,msg,continue) end
        else
            if not str then
                str=c
            elseif c~="" then
                str=str:gsub("([%d;]+)","%1;"..c:match("([%d;]+)"),1)
            end
        end
    end
    if str and not enabled then str="" end
    return str and (str..(msg or "")..(continue and "" or ansi.string_color('NOR'))) or msg
end

function ansi.addCompleter(name,args)
--[[
    if not reader then return end
    if type(name)~='table' then
        name={tostring(name)}
    end

    local c=str_completer:new(table.unpack(name))
    for i,k in ipairs(name) do name[i]=tostring(k):lower() end
    c=str_completer:new(table.unpack(name))
    reader:addCompleter(c)
    if type(args)=="table" then
        for i,k in ipairs(args) do args[i]=tostring(k):lower() end
        for i,k in ipairs(name) do
            c=arg_completer:new(str_completer:new(k,table.unpack(args)))
            reader:addCompleter(c)
        end
    end
--]]
end

function ansi.clear_sceen()
    os.execute(env.OS == "windows" and "cls" or "clear")
end

function ansi.define_color(name,value,module,description)
    if not value or not enabled then return end
    name,value=name:upper(),value:upper()
    value=value:gsub("%$(%u+)%$",'%1')
    env.checkerr(not color[name],"Cannot define color ["..name.."] as a name!")
    if ansi.mask(value,"")=="" then
        env.raise("Undefined color code ["..value.."]!")
    end

    if description then
        ansi.cfg(name,ansi.cfg(name) or value,module,description)
        env.set.init(name,value,ansi.define_color,module,description)
        if value ~= ansi.cfg(name) then
            env.set.force_set(name,ansi.cfg(name))
        end
    else
        ansi.cfg(name,value)
        return value
    end
end

function ansi.get_color(name,...)
    --io.stdout:write(name,ansi.cfg(name),enabled and 1 or 0)
    if not name or not enabled then return "" end
    name=name:upper()
    if color[name] then return ansi.string_color(name,...) or "" end
    return ansi.cfg(name) and ansi.mask(ansi.cfg(name),"",true) or ""
end

function ansi.enable_color(name,value)
    if not isAnsiSupported then return 'off' end
    if value=="off" then
        if not enabled then return end
        --env.remove_command("clear")
        for k,v in pairs(ansi.cfg()) do env.set.remove(k) end
        for k,v in pairs(base_color) do color[k]="" end
        enabled=false
    else
        if enabled then return end
        for k,v in pairs(base_color) do color[k]=v end
        --env.set_command(nil,{"clear","cls"},"Clear screen ",ansi.clear_sceen,false,1)
        for k,v in pairs(ansi.map or {}) do
            env.set.init(k,v[4],ansi.define_color,v[2],v[3])
            if v[1] ~= v[4] then
                env.set.doset(k,v[1])
            end
        end
        enabled=true
    end
    return value
end

function ansi.onload()
    env.set_command(nil,{"clear","cls"},"Clear screen ",ansi.clear_sceen,false,1)
    writer=reader:getOutput()
    ansi.loaded=true
    str_completer=java.require("jline.console.completer.StringsCompleter",true)
    arg_completer=java.require("jline.console.completer.ArgumentCompleter",true)
    for k,v in pairs(base_color) do color[k]=isAnsiSupported and v or '' end
    env.set.init("ansicolor",isAnsiSupported and 'on' or 'off',ansi.enable_color,"core","Enable color masking inside the intepreter.",'on,off')
    env.set_command(nil,'ansi',"Show and test ansi colors, run 'ansi' for more details",ansi.test_text,false,2)
    ansi.color,ansi.map=color,cfg
end

function ansi.strip_ansi(str)
    if not enabled then return str end
    return str:gsub("\27%[[%d;]*[mK]","")
end

function ansi.strip_len(str)
    return #ansi.strip_ansi(str)
end

function ansi.convert_ansi(str)
    return str and str:gsub("%$((%u+)([, ]?)(%d*)([, ]?)(%d*))%$",
        function(all,code,x,pos1,x,pos2) 
            if pos1~="" then return ansi.string_color(code,pos1,pos2) or '$'..all..'$' end
            return ansi.mask(code,nil,true) or '$'..all..'$'
        end)
end

function ansi.test_text(str)
    if not isAnsiSupported then return print("Ansi color is not supported!") end
    if not str or str=="" then
        rawprint(env.space.."ANSI SGR Codes, where '$E' means ascii code 27(a.k.a chr(27)): ")
        rawprint(env.space..string.rep("=",140))
        print(env.load_data(env.WORK_DIR.."bin"..env.PATH_DEL.."ANSI.txt",false))
        rawprint(env.space..string.rep("=",140))
        local bf,wf,bb,wb=base_color['BLK'][1],base_color['HIW'][1],base_color['BBLK'][1],base_color['HBWHT'][1]
        if env.grid then
            local row=env.grid.new()
            local is_fg,max_len=nil,0
            row:add{"Ansi Code","Ansi Type","Description","Demo #1(White)","Demo #2(Black)"}
            for k,v in pairs(base_color) do if type(v)=="table" and v[2] and max_len<#v[2] then max_len=#v[2] end end
            local fmt="%s%s"..base_color['NOR'][1]
            for k,v in pairs(base_color) do
                if type(v)=="table" then
                    local text=string.format('%-'..max_len..'s',v[2])
                    is_fg=text:lower():match("foreground")
                    local ctl=v[3] or 0
                    row:add{k,
                        v[3] and " Control" or is_fg and 'FG color' or 'BG color',
                        text,
                        ctl>0 and "N/A" or fmt:format(is_fg and v[1]..wb or wf..v[1],text),
                        ctl>0 and "N/A" or fmt:format(is_fg and v[1]..bb or bf..v[1],text)}
                end
            end
            row:sort("-2,3,1",true)
            row:print()
        end
        rawprint(env.space..string.rep("=",140))
        rawprint(env.space.."Use `$<code>$<other text>` to mask color in all outputs, including query, echo, etc. Not all listed control codes are supported.")
        rawprint(env.space.."For the color settings defined in command 'set', use '<code1>[;<code2>[...]]' format")
        rawprint(env.space.."Run 'ansi <text>' to test the color, i.e.: ansi $HIR$ Hello $HIC$$HBGRN$ ANSI!")
        rawprint(env.space.."Or SQL:  select '$HIR$'||owner||'$HIB$.$NOR$'||object_name obj,a.* from all_objects a where rownum<10;")
        return
    end
   
    return rawprint(env.space.."ANSI result: "..ansi.convert_ansi(str)..ansi.string_color('NOR'))
end


return ansi