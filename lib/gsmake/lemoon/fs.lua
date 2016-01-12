local class     = require "lemoon.class"
local logger    = class.new("lemoon.log","lemoon")

local module = require "lemoonc.fs"

local has_force_flag = function(flags)
    return string.match(flags or "","f") ~= nil
end

local has_merge_flag = function(flags)
    return string.match(flags or "","m") ~= nil
end

function module.copy_file(source,target,flags)

    if module.exists(target) then
        if has_force_flag(flags) then
            module.rm(target,true)
        else
            error(string.format("target file already exists :%s",target),2)
        end

    end

    local srcFile = io.open(source, "rb")
    local targetFile = io.open(target, "wb")

    while true do
        local srcData = srcFile:read(512)
        if srcData == nil then break end
        targetFile:write(srcData)
    end



    srcFile:close()
    targetFile:close()
end

-- copy the directory to target path
function module.copy_dir(from,to,flags)
    if module.exists(to) and not has_merge_flag(flags) then
        error("copy directory error: already exists\n\tfrom: %s\n\tto: %s",from,to)
    end

    if not module.exists(to) then
        module.mkdir(to,true)
    end

    module.list(from,function(entry)
        if entry == "." or entry == ".." then return end

        local src = from .. "/".. entry
        local obj = to .. "/".. entry

        if module.isdir(src) then
            module.copy_dir(src,obj,flags)
        else
            module.copy_file(src,obj,flags)
        end
    end)
end


function module.match(path,pattern,skipdirs,fn)
    module.list(path,function(entry)
        if entry == "." or entry == ".." then return end

        for _,v in pairs(skipdirs or {}) do
            if v == entry then return end
        end

        local childpath = path .. "/".. entry

        if module.isdir(childpath) then
            module.match(childpath,pattern,skipdirs,fn)
        else
            if entry:match(pattern) == entry then
                fn(path .. "/" .. entry)
            end
        end
    end)
end

return module
