
CodeWriter = {};

function CodeWriter:New(fileName)
    local CW = {};
    
    CW.path, CW.fileName = tostring(fileName):match('(.-)(%a+).vm');
    CW.line = 0;
    local symbol = {['local']='LCL', argument='ARG',this ='THIS' ,that='THAT',temp=5, pointer=3, statisc=tostring(CW.fileName)..'.'};
    print("path ("..CW.path.." file: ("..CW.fileName..")");

    if CW.path and CW.fileName then
        CW.asmfile = io.open(CW.path..CW.fileName..'.asm','w+');
        if not CW.asmfile then
            print("nao foi possviel criar o arquivo "..CW.fileName..".asm");
        end
    else
        print('nao pode criar o asmfile (path: '..tostring(CW.path)..')(file: '..CW.fileName..')')
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
        print("escrevendo "..segment.." "..index);
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
        print("escrevendo "..segment.." "..index);

        if symbol[segment] then
            self:write( '// pop '..segment.." "..index..'\n'..
                        '@'..tostring(symbol[segment])..'\n'..
                        'D='..((segment == 'temp' or segment == 'pointer') and 'A' or 'M')..'\n'.. --operador ternario em lua. operation ? true:false;
                        '@'..index..'\n'..
                        'D=D+A\n'..
                        '@addr_'..CW.line..'\n'..
                        'M=D\n'..
                        '@SP\n'..
                        'M=M-1\n'..
                        'A=M\n'..
                        'D=M\n'..
                        '@addr_'..CW.line..'\n'..
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

    return CW;
end

