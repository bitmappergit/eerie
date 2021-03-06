#!/usr/local/bin io

Importer addSearchPath("io/")

eeriePath := method(
    platform := System platform
    if(platform containsAnyCaseSeq("windows") or(platform containsAnyCaseSeq("mingw")),
        return System installPrefix .. "/eerie"
        ,
        return ("~/.eerie" stringByExpandingTilde)
    )
)
eerieDir  := Directory with(eeriePath)

System setEnvironmentVariable("EERIEDIR", eeriePath)

appendEnvVariables := method(
  bashScript := """|
    |# Eerie config
    |EERIEDIR=#{eeriePath}
    |PATH=$PATH:$EERIEDIR/base/bin:$EERIEDIR/activeEnv/bin
    |export EERIEDIR PATH
    |# End Eerie config""" fixMultiline interpolate
  bashFile := if(System args at(1) != "-dev", System args at(1))

  if(bashFile,
    bashFile = File with(bashFile)
    bashFile exists ifFalse(
      bashFile create
      Eerie log("Created #{bashFile path}"))
    
    bashFile contents containsSeq("EERIEDIR") ifFalse(
      bashFile appendToContents(bashScript)
      Eerie log("Added new environment variables to #{bashFile path}")
      Eerie log("Make sure to run \"source #{bashFile path}\""))
  ,
    "----" println
    "Make sure to update your shell's environment variables before using Eerie." println
    "Here's a sample code you could use:" println
    bashScript println))

createDirectories := method(
  eerieDir createIfAbsent
  eerieDir directoryNamed("env") create
  eerieDir directoryNamed("tmp") create

  eerieDir fileNamed("/config.json") create openForUpdating write("{\"envs\": {}}") close
)

createDefaultEnvs := method(
  baseEnv := Eerie Env with("_base") create activate use
  SystemCommand lnDirectory(baseEnv path, eeriePath .. "/base")

  Eerie Env with("_plugins") create
  Eerie Env with("default") create
  Eerie saveConfig)

installEeriePkg := method(
  packageUri := "https://github.com/IoLanguage/eerie.git"
  if(System args at(1) == "-dev",
    packageUri = Directory currentWorkingDirectory
  )
  Eerie Transaction clone install(Eerie Package fromUri(packageUri)) run
)

activateDefaultEnv := method(
  Eerie Env named("default") activate)

Sequence fixMultiline := method(
  self splitNoEmpties("\n") map(split("|") last) join("\n") strip)

# Run the process
if(eerieDir exists,
  Exception raise(eerieDir path .. " already exists.")
  ,
  createDirectories

  Eerie do(
      _log := getSlot("log")
      _allowedModes := list("info", "error", "transaction", "install")

      log = method(str, mode,
          (mode == nil or self _allowedModes contains(mode)) ifTrue(
              call delegateToMethod(self, "_log")
          )
      )
  )
  
  createDefaultEnvs
  installEeriePkg
  appendEnvVariables
  activateDefaultEnv
  " --- Done! --- " println
)
