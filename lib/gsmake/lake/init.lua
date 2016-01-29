local fs        = require "lemoon.fs"
local class     = require "lemoon.class"
local filepath  = require "lemoon.filepath"


local logger    = class.new("lemoon.log","gsmake")
local console   = class.new("lemoon.log","console")
local logsink    = require "lemoon.logsink"

local module = {}

local once_flag = false

function module.ctor(workspace)

    local obj = {
        Config  = class.clone(require "config");
        Remotes = class.clone(require "remotes");
        Root    = false;
    }


    -- query the gsmake home path
    obj.Config.GSMAKE_HOME             = os.getenv(obj.Config.GSMAKE_ENV)
    -- set the machine scope package cached directory
    obj.Config.GSMAKE_REPO             = filepath.join(obj.Config.GSMAKE_HOME,"repo")
    -- set the project workspace
    obj.Config.GSMAKE_WORKSPACE        = workspace

    if not fs.exists(filepath.join(obj.Config.GSMAKE_WORKSPACE ,obj.Config.GSMAKE_FILE)) then
        obj.Config.GSMAKE_WORKSPACE = obj.Config.GSMAKE_HOME
    end

    -- set the project depend packages install path
    obj.Config.GSMAKE_INSTALL_PATH     = filepath.join(obj.Config.GSMAKE_WORKSPACE,obj.Config.GSMAKE_TMP_DIR)

    -- init file sink

    if not once_flag then
        local name = "gsmake" .. os.date("-%Y-%m-%d-%H_%M_%S")
        logsink.file_sink(
            "gsmake",
            filepath.join(obj.Config.GSMAKE_INSTALL_PATH,"log"),
            name,
            ".log",
            false,
            1024*1024*10)

        once_flag = true
        obj.Root = true
    end

    if not fs.exists(obj.Config.GSMAKE_REPO) then
        fs.mkdir(obj.Config.GSMAKE_REPO,true) -- create repo directories
    end

    if not fs.exists(obj.Config.GSMAKE_INSTALL_PATH) then
        fs.mkdir(obj.Config.GSMAKE_INSTALL_PATH,true) -- create repo directories
    end

    logger:I("create new gsmake instance for package :%s",obj.Config.GSMAKE_WORKSPACE)
    logger:D("config variables :")

    for k,v in pairs(obj.Config) do
        local k = string.format("var %s = ",k)

        local len = 30

        if #k < len then
            k = string.format("%s%s",k,string.rep(" ",len - #k))
        end

        logger:D("%s = '%s'",k,v)
    end

    obj.DB     = class.new("lake.db",obj)
    obj.Sync   = class.new("lake.sync",obj)
    obj.Loader = class.new("lake.loader",obj)


    return obj

end

function module:loadSystemPlugin(dir)


    if fs.exists(filepath.join(dir,self.Config.GSMAKE_FILE)) then
        logger:I("load system plugin ...\n\tdir :%s",dir)
        local package = self.Loader:load(dir)
        self.DB:save_source(package.Name,package.Version,dir,dir,true)
        logger:I("load system plugin[%s:%s] -- success\n\tdir :%s",package.Name,package.Version,dir)
        return
    end

    fs.list(dir,function(entry)
        if entry == "." or entry == ".." then return end

        local path = filepath.join(dir,entry)

        if fs.isdir(path) then
            self:loadSystemPlugin(path)
        end
    end)

end


function module:loadCommands(root,dir)
    if fs.exists(filepath.join(dir,self.Config.GSMAKE_FILE)) then
        logger:I("load system plugin ...\n\tdir :%s",dir)
        local package = self.Loader:load(dir)
        self.DB:save_source(package.Name,package.Version,dir,dir,true)

        local plugin = class.new("lake.plugin",package.Name,root)
        root.Plugins[package.Name] = plugin

        logger:I("load command package [%s:%s] -- success\n\tdir :%s",package.Name,package.Version,dir)

        return
    end

    fs.list(dir,function(entry)
        if entry == "." or entry == ".." then return end

        local path = filepath.join(dir,entry)

        if fs.isdir(path) then
            self:loadCommands(root,path)
        end
    end)
end

function module:run(...)

    local args = ""

    for _,val in ipairs(table.pack(...)) do
        args = args .. val .. " "
    end

    logger:I("run gsmake in directory ...\n\tdir :%s\n\targs :%s",self.Config.GSMAKE_WORKSPACE,args)

    if self.Root then
        console:I("start gsmake  ...")
        console:I("workspace :%s",self.Config.GSMAKE_WORKSPACE)
    end


    -- load default plugins

    local pluginDir = filepath.join(self.Config.GSMAKE_HOME,"lib/gsmake/plugin")
    logger:I("load system plugins ...")
    self:loadSystemPlugin(pluginDir)
    logger:I("load system plugins -- success")

    -- load root package
    if self.Root then
        console:I("prepare ...")
    end

    local package = self.Loader:load(self.Config.GSMAKE_WORKSPACE)

    if self.Root then
      local cmdDir = filepath.join(self.Config.GSMAKE_HOME,"lib/gsmake/cmd")
      logger:I("load system commands ...")
      self:loadCommands(package,cmdDir)
      logger:I("load system commands -- success")
    end

    if not class.new("lake.runner",package):run(...) then
        logger:I("run gsmake in directory -- success\n\tdir :%s\n\targs :%s",self.Config.GSMAKE_WORKSPACE,args)
        if self.Root then
            console:I("gsmake -- success")
        end
    else
        if self.Root then
            console:E("gsmake -- failed !!!!!!!!!!!\n\t for more details, check the log files in directory %s",filepath.join(self.Config.GSMAKE_WORKSPACE,".gsmake","log"))
            return true
        end
    end
end

return module
