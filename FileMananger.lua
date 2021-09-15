
FileMananger = {};

function FileMananger:New(path)
    FM = {};
    FM.path = path:gsub("[/|\\]",package.config:sub(1,1));
    FM.isdir = nil;
    FM.ListFile = {};
    --print(("\\"):byte());
    function FM:Init()
        if self:exists() then
            if(self:isDir()) then
                self.isdir = true;
                self:GetFileDir();
                self.lastdir = self:GetLastDir();
            else
                self.lastdir = "";

                for str in string.gmatch(self.path,"([^"..package.config:sub(1,1).."]+)") do
                    local fileName =  str:match("(.-.vm)");
                    if not fileName  then
                        self.lastdir = str;
                    end
                end
                table.insert(self.ListFile, FM.path); --sendo um arquivo retorna uma table com um arquivo só
            end
        end
        return self;
    end

    function FM:GetLastDir()
        local lDir = "";
        for str in string.gmatch(self.path,"([^"..package.config:sub(1,1).."]+)") do
            if str ~= "" then
                lDir = str;
            end
        end
        return lDir;
    end

    function FM:GetOs()
        local b = package.cpath:match("%p[\\|/]?%p(%a+)")
        if b == "dll" then 
            return "windows"
        elseif b == "dylib" then
            -- macos
            return "mac"
        elseif b == "so" then
            -- Linux
            return "linux"
        end 
    end 
    
    function FM:exists()
        if type(self.path)~="string" then return false end
        return os.rename(self.path,self.path) and true or false
    end
    
    function FM:isFile()
        if type(self.path)~="string" then return false end
        if not self:exists(self.path) then return false end
        local f = io.open(self.path)
        if f then
            f:close()
            return true
        end
        return false
    end
    
    function FM:isDir()
        if self:GetOs() == "windows" then
            return (self:exists(self.path) and not self:isFile(self.path))
        elseif self:GetOs() == "linux" then
            local f = io.open(path, "r")

            if (f) then
                local ok, err, code = f:read(1)
                f:close()
                return code == 21
            end
            return false;
        end
    end
    
    function FM:GetFileDir()

        local f = nil;
        local os = self:GetOs();

        if os == "linux" then f = io.popen("ls -a "..self.path.."/*.vm","r");
        elseif os == "windows" then f = io.popen("dir /b "..self.path.."\\*.vm","r");
        end
        
        self.ListFile = {};
        for line in f:lines() do
            table.insert(self.ListFile, ((os == 'windows') and self.path.."\\" or "")..line);
        end
    end

    return FM:Init();
end