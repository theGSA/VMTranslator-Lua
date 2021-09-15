
CodeWriter = {};

function CodeWriter:New(fileName)
    local CW = {};
    local sep = package.config:sub(1,1);
    local m_filename = fileName:gsub("[/|\\]",sep);
    local File = FileMananger:New(fileName);
    local symbol = {['local']='LCL', argument='ARG',this ='THIS' ,that='THAT',temp=5, pointer=3, statisc=tostring(CW.fileName)..'.'};

    function CW:SetVmFile(strfileName)
        CW.path, CW.fileName = tostring(strfileName):match('(.+)'..sep..'(.+).vm');
        self.asmfile:write('// arquivo '..CW.fileName ..".vm\n");
    end

    function CW:Init()
        CW.path, CW.fileName = tostring(m_filename):match('(.+)'..sep..'(.+).vm');
        CW.line = 1;

        --print("path ("..tostring(CW.path)..") file: ("..tostring(CW.fileName)..")");
        if File.isdir then
            CW.asmfile = io.open(m_filename..sep..File.lastdir..'.asm','w+');
            
            if not CW.asmfile then 
                print("nao foi possviel criar o arquivo "..tostring(File.lastdir)..".asm");
            else
                CW:WriteInit();
            end
        else
            
            if CW.path and CW.fileName then
                CW.asmfile = io.open(CW.path..sep..CW.fileName..'.asm','w+');
                if not CW.asmfile then
                    print("nao foi possviel criar o arquivo "..CW.fileName..".asm");
                end
            else
                print('nao pode criar o asmfile (path: '..tostring(CW.path)..')(file: '..tostring(CW.fileName)..')')
            end
        end
        return self;
    end

    function CW:WriteArithmetic(strParam)
        local arithmetic = {add="D=D+M", sub="D=M-D", ['or']="M=D|M", ['not']="M=!M",['neg']="M=-M", ['and'] = 'M=D&M'}
    
        if strParam == 'add' or strParam == 'sub' then
            self:write( ' // '..strParam..'\n'..
                        '@SP\n'..
                        'M=M-1\n'..
                        'A=M\n'..
                        'D=M\n'..
                        'A=A-1\n'..
                        tostring(arithmetic[strParam])..'\n'..
                        'M=D\n');
        elseif (strParam == 'eq' or strParam == 'gt' or strParam == 'lt')then
            self:write( ''..'// '..strParam..'\n'..
                        '@SP\n'..
                        'M=M-1\n'..
                        'A=M\n'..
                        'D=M\n'..
                        'A=A-1\n'..
                        'D=M-D\n'..
                        '@'..strParam:upper()..'_'..CW.line..'\n'..
                        'D;J'..strParam:upper()..'\n'..
                        '@SP\n'..
                        'A=M-1\n'..
                        'M=0\n'..
                        '@END_'..CW.line..'\n'..
                        '0;JMP\n'..
                        '('..strParam:upper()..'_'..CW.line..')\n'..
                        '@SP\n'..
                        'A=M-1\n'..
                        'M=-1\n'..
                        '(END_'..CW.line..')\n');
        elseif  strParam == 'neg' or strParam == 'not' then
            self:write( ' // '..strParam..'\n'..
                        '@SP\n'..
                        'A=M-1\n'..
                        arithmetic[strParam]..'\n')
        elseif strParam == 'and' or strParam == 'or' then
            self:write( '// '..strParam..'\n'..
                        '@SP\n'..
                        'M=M-1\n'..
                        'A=M\n'..
                        'D=M\n'..
                        'A=A-1\n'..
                        arithmetic[strParam]..'\n');
        end
    end

    function CW:IsArithmetic(strParam)
        local arithmetic = {"add", "sub", "neg", "eq", "gt", "lt", "and", "or", "not" }
        for i, v in pairs(arithmetic) do
            if v == strParam then
                return true;
            end
        end
        return false;
    end

    function CW:WritePush(segment, index)
        --print("escrevendo "..segment.." "..index);
        if segment == 'static' then
            self:write(' // push '..segment..' '..index..'\n'..
                        '@'..CW.fileName..'.'..index..'\n'..
                        'D=M\n'..
                        '@SP\n'..
                        'A=M\n'..
                        'M=D\n'..
                        '@SP\n'..
                        'M=M+1\n');
        else
            self:write('// push '..segment.." "..index);
            if symbol[segment] then
                self:write('@'..symbol[segment]..'\n'..
                'D='..((segment == 'temp' or segment == 'pointer') and 'A' or 'M')..'\n'..
                '@'..index..'\n'..
                'D=D+A\n'..
                'A=D\n'..
                'D=M')
            else
                self:write('@'..index); 
                self:write("D=A");
            end
            self:write("@SP");
            self:write("A=M");
            self:write("M=D");
            self:write("@SP");
            self:write("M=M+1\n");
        end
    end
    
    function CW:write(str)
        self.asmfile:write(str.."\n");
    end
    
    function CW:WritePop(segment, index)
        --print("escrevendo "..segment.." "..index);

        if symbol[segment] then
            self:write( '// pop '..segment.." "..index..'\n'..
                        '@'..tostring(symbol[segment])..'\n'..
                        'D='..((segment == 'temp' or segment == 'pointer') and 'A' or 'M')..'\n'.. --operador ternario em lua. operation ? true:false;
                        '@'..index..'\n'..
                        'D=D+A\n'..
                        '@addr_'..CW.fileName.."_"..CW.line..'\n'..
                        'M=D\n'..
                        '@SP\n'..
                        'M=M-1\n'..
                        'A=M\n'..
                        'D=M\n'..
                        '@addr_'..CW.fileName.."_"..CW.line..'\n'..
                        'A=M\n'..
                        'M=D\n');
        elseif segment == 'static' then
            self:write(  '// pop '..segment.." "..index..'\n'..
                        '@SP\n'..
                        'M=M-1\n'..
                        'A=M\n'..
                        'D=M\n'..
                        '@'..CW.fileName..'.'..index..'\n'..
                        'M=D\n')
        end
    end

    function CW:WriteFunction(segment, index)
        self:write(" // function "..segment.." "..index);
        self:write('('..segment..')');
        for i = 1, index do
            self:write( "@SP\n"..
                        "A=M\n"..
                        "M=0\n"..
                        "@SP\n"..
                        "M=M+1\n");
        end
    end

    function CW:WriteReturn()
        self:write("// return\n"..
                    "@LCL\n"..
                    "D=M\n"..
                    "@frame\n"..
                    "M=D\n"..-- FRAME = LCL
                    "@5\n"..
                    "D=D-A\n"..
                    "A=D\n"..
                    "D=M\n"..
                    "@return_address\n"..
                    "M=D\n".. --RET = *(FRAME-5)
                    "@SP\n"..
                    "M=M-1\n"..
                    "A=M\n"..
                    "D=M\n"..
                    "@ARG\n"..
                    "A=M\n"..
                    "M=D\n".. -- *ARG = pop()
                    "@ARG\n"..
                    "D=M+1\n"..
                    "@SP\n"..
                    "M=D\n"..-- SP = ARG+1
                    "@frame\n"..
                    "D=M-1\n"..
                    "A=D\n"..
                    "D=M\n"..
                    "@THAT\n"..
                    "M=D\n"..-- THAT = *(FRAME-1)
                    "@2\n"..
                    "D=A\n"..
                    "@frame\n"..
                    "D=M-D\n"..
                    "A=D\n"..
                    "D=M\n"..
                    "@THIS\n"..
                    "M=D\n".. -- THIS = *(FRAME-2)
                    "@3\n"..
                    "D=A\n"..
                    "@frame\n"..
                    "D=M-D\n"..
                    "A=D\n"..
                    "D=M\n"..
                    "@ARG\n"..
                    "M=D\n"..-- ARG = *(FRAME-3)
                    "@4\n"..
                    "D=A\n"..
                    "@frame\n"..
                    "D=M-D\n"..
                    "A=D\n"..
                    "D=M\n"..
                    "@LCL\n"..
                    "M=D\n"..-- LCL = *(FRAME-4)
                    "@return_address\n"..
                    "A=M\n"..
                    "0;JMP\n"); -- goto RET
    end

    function CW:WriteInit()
        self:write( "// write init\n"..
                    "@256\n"..
                    "D=A\n"..
                    "@SP\n"..
                    "M=D\n");
        self:WriteCall('Sys.init', 0);
    end

    function CW:WriteCall(segment, index)
        self:write("// call "..segment.." "..index.."\n"..
                    "@"..segment.."$ret."..self.line.."\n"..
                    "D=A\n"..
                    "@SP\n"..
                    "A=M\n"..
                    "M=D\n"..
                    "@SP\n"..
                    "M=M+1\n"..
                    -- push LCL
                    "@LCL\n"..
                    "D=M\n"..
                    "@SP\n"..
                    "A=M\n"..
                    "M=D\n"..
                    "@SP\n"..
                    "M=M+1\n"..
                    -- push ARG
                    "@ARG\n"..
                    "D=M\n"..
                    "@SP\n"..
                    "A=M\n"..
                    "M=D\n"..
                    "@SP\n"..
                    "M=M+1\n"..
                    -- push THIS
                    "@THIS\n"..
                    "D=M\n"..
                    "@SP\n"..
                    "A=M\n"..
                    "M=D\n"..
                    "@SP\n"..
                    "M=M+1\n"..
                    -- push THAT
                    "@THAT\n"..
                    "D=M\n"..
                    "@SP\n"..
                    "A=M\n"..
                    "M=D\n"..
                    "@SP\n"..
                    "M=M+1\n"..
                    -- ARG = SP-n-5
                    "@SP\n"..
                    "D=M\n"..
                    "@"..index.."\n"..
                    "D=D-A\n"..
                    "@5\n"..
                    "D=D-A\n"..
                    "@ARG\n"..
                    "M=D\n"..
                    -- LCL = SP
                    "@SP\n"..
                    "D=M\n"..
                    "@LCL\n"..
                    "M=D\n"..
                    -- goto f
                    "@"..segment.."\n"..
                    "0;JMP\n"..
                    --"(return-address)"..
                    "("..segment.."$ret."..self.line..")\n");    
    end
    
    function CW:WriteLabel(segment)
        self:write("// label "..segment.."\n"..
                    "("..segment..")\n");
    end

    function CW:WriteGoto(segment)
        self:write("// goto "..segment.."\n"..
                    "@"..segment.."\n"..
                    "0;JMP\n");
    end

    function CW:WriteIf(segment)
        self:write("// if-goto "..segment.."\n"..
               "@SP\n"..
               "M=M-1\n"..
               "A=M\n"..
               "D=M\n"..
               "@"..segment.."\n"..
               "D;JNE\n");
    end
    return CW:Init();
end

