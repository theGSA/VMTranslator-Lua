require('Parser');
require('CodeWriter');
require('FileMananger');

VMTranslator = {};

function VMTranslator:Init()

    local File = FileMananger:New(arg[1]);
    local codeWriter = CodeWriter:New(arg[1]);
    
    for index, value in ipairs(File.ListFile) do
        local parser = Parser:New(value);
        codeWriter:SetVmFile(value);
        print("traduz: "..value);
        while parser:Advance() do
            --print("cmd: "..tostring(parser.token.cmd).." seg: "..tostring(parser.token.segment).." index: "..tostring(parser.token.index));
            codeWriter.line = parser.line;
            if parser.token.cmd == 'push' then
                codeWriter:WritePush(parser.token.segment, parser.token.index);
            elseif parser.token.cmd == "pop" then
                codeWriter:WritePop(parser.token.segment, parser.token.index);
            elseif parser.token.cmd == "function" then
                codeWriter:WriteFunction(parser.token.segment, parser.token.index);
            elseif parser.token.cmd == "return" then
                codeWriter:WriteReturn();
            elseif parser.token.cmd == "call" then
                codeWriter:WriteCall(parser.token.segment, parser.token.index);
            elseif parser.token.cmd == "label" then
                codeWriter:WriteLabel(parser.token.segment);
            elseif parser.token.cmd == "goto" then
                codeWriter:WriteGoto(parser.token.segment);
            elseif parser.token.cmd == "if-goto" then
                codeWriter:WriteIf(parser.token.segment);
            elseif codeWriter:IsArithmetic(parser.token.cmd) then
                codeWriter:WriteArithmetic(parser.token.cmd);
            else
                print("warning: ("..parser.token.cmd..")");
            end
        end
    end

end

VMTranslator:Init();


