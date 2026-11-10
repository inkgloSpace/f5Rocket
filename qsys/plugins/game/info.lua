PluginInfo = {
  Name = "f5Rocket",
  Version = "0.4.2",
  BuildVersion = "0.4.2.0",
  Id = "fdb75e48-50b5-5b21-8104-5da52ab51f13",
  Author = "inkgloSpace",
  Description = "Semi-8-bit vertical arcade shooter for Q-SYS"
}

function GetColor(props)
  return { 7, 16, 31 }
end

function GetPrettyName(props)
  return "f5Rocket v" .. PluginInfo.Version
end
