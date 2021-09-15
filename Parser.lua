
Parser = {}

function Parser:New(strParam)
    local PS = {};
    PS.line = 0;
    PS.position = 0;
    PS.curtokem = 0;
    PS.token = {};

    if not strParam or type(strParam) ~= 'string' then
        print("Parser recebou arquivo nao valido "..tostring(strParam));
        return nil;
    end
    PS.vmfile = io.open(strParam, "r");

    if not PS.vmfile then
        print("nao foi possivel abri o arquivo "..tostring(strParam));
        return nil;
    end
    function IsCommand(cmd)
        local comands = {"pop", "push", "add", "sub", "neg", "eq", "gt", "lt", "and", "or", "not", "label", "if-goto", "function", "return", "call", "label", "goto"};

        for i, v in pairs(comands) do
            --print("comapar "..tostring(cmd).." "..i);
            if v == cmd then return true
            end
        end
        return false;
    end
    function PS:Advance()
        local line = PS.vmfile:read();

        while line  do
            PS.token.cmd, PS.token.segment, PS.token.index = line:match('^(.-)%s(.-)%s(%d+)');
            if not PS.token.cmd and not line:match("^(//)")then
                local s= {};
                for str in line:gmatch("([^%s]+)") do
                    table.insert(s, str);
                end
                PS.token.cmd, PS.token.segment = s[1], s[2];
            end
            
            if IsCommand(PS.token.cmd) then
                PS.line = PS.line + 1;
                return true;
            else
                PS.token.cmd = line:match('^(.+)');
                if IsCommand(PS.token.cmd) then
                    PS.line = PS.line + 1;
                    return true;
                end
            end
            line = PS.vmfile:read();
        end
        return nil;
    end
    --print("retornando")
    return PS;
end