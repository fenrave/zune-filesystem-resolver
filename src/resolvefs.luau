--!strict
------------------
local fs = zune.fs
local platform = zune.platform
local process = zune.process
local Case = require("./case")
local path = fs.path
------------------
local SystemPlatform: string = platform.os
local envQuery = process.env
local envPlatform: DirTypes?
------------------

local INTERMEDIATE: string = "ZuneProcess"
local PID: number? = process.pid()

type DirTypes = {
    Home: string,
    Temp: string,
    Config: string,
    Logs: string,
    Data: string,
    Cache: string
}

local function DirChecker(MainPath: string?, AltPath: string): string
    return if not MainPath then AltPath else MainPath
end

local DirCase: {[any]: DirTypes} = { --Should only ever need to be ran once
    ["linux" or "freebsd"] = {
        Home = envQuery["HOME"],

        Temp = DirChecker(envQuery["XDG_RUNTIME_DIR"], "/var/tmp"),

        Config = DirChecker(envQuery["XDG_CONFIG_HOME"], path.join(envQuery["HOME"], ".config")),

        Logs = DirChecker(envQuery["XDG_STATE_HOME"], path.join(envQuery["HOME"], ".local", "state")),

        Data = DirChecker(envQuery["XDG_DATA_HOME"], path.join(envQuery["HOME"], ".local", "share")),

        Cache = DirChecker(envQuery["XDG_CACHE_HOME"], path.join(envQuery["HOME"], ".cache"))
    },
    ["windows"] = {
        Home = envQuery["HOMEPATH"],

        Temp = DirChecker(envQuery["TEMP"],envQuery["TMP"]),

        Data = envQuery["APPDATA"],

        Logs = DirChecker(envQuery["CSIDL_LOCAL_APPDATA"], envQuery["APPDATA"]),

        Cache = envQuery["APPDATA"],

        Config = envQuery["APPDATA"]
    },
    ["macos"] = {
        Home = envQuery["HOME"],

        Temp = DirChecker(envQuery["TMPDIR"], "/var/tmp"),

        Config = path.join(envQuery["HOME"], ".config"),

        Logs = path.join(envQuery["HOME"], "Library", "Logs"),

        Data = path.join(envQuery["HOME"], "Library"),

        Cache = path.join(envQuery["HOME"], "Library", "Caches")
    }
}

-----------------------------------------------------------------
local SysDirectoryCase = Case("tempdir_Case", DirCase)

envPlatform = SysDirectoryCase(SystemPlatform)

if not envPlatform then
    error(`Unknown system, {SystemPlatform}, please assign directories manually.`)
end

-----------------------------------------------------------------
type resolver_lib = {
    MakeTempDirectory: (self: resolver_lib, Path: string) -> string,
    GetSystemDirectories: (self: resolver_lib) -> DirTypes,
    SetNewDirectory: (self: resolver_lib, DirChoice: string, Path: string) -> string,
    SetPID: (self: resolver_lib, NewID: number) -> (),
    SetProcessName: (self: resolver_lib, NewName: string) -> ()
}

local resolvefs = {} :: resolver_lib


function resolvefs:MakeTempDirectory(Path: string): string
    local newDir: string = path.join(envPlatform.Temp, Path) do
        fs.makeDir(newDir, true)
    end

    return newDir
end

function resolvefs:GetSystemDirectories(): DirTypes
    return envPlatform
end

function resolvefs:SetPID(NewID: number?)
    PID = NewID
end

function resolvefs:SetProcessName(NewName: string)
    INTERMEDIATE = NewName
end

function resolvefs:SetNewDirectory(SystemDirectory: string, NewPath: string): string
    local NewDir: string

    if not PID then
        NewDir = path.join(envPlatform[SystemDirectory], INTERMEDIATE, NewPath)
    else
        NewDir = path.join(envPlatform[SystemDirectory], INTERMEDIATE, tostring(PID), NewPath)
    end

    fs.makeDir(NewDir, true)

    return NewDir
end

return resolvefs
