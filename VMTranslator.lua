require('CodeWriter');
require('Parser');

VMTranslator = {};

function VMTranslator:Init()
    local parser = Parser:New(arg[1]);
    local codeWriter = CodeWriter:New(arg[1]);

    
    while parser:Advance() do
        print("cmd: "..tostring(parser.token.cmd).." seg: "..tostring(parser.token.segment).." index: "..tostring(parser.token.index));
        codeWriter.line = parser.line;
        if parser.token.cmd == 'push' then
            codeWriter:WritePush(parser.token.segment, parser.token.index);
        elseif parser.token.cmd == "pop" then
            codeWriter:WritePop(parser.token.segment, parser.token.index);
        elseif codeWriter:IsArithmetic(parser.token.cmd) then
            codeWriter:WriteArithmetic(parser.token.cmd);
        end
    end

end

VMTranslator:Init();