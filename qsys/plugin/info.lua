PluginInfo = {
  Name = "f5Rocket~Compatibility Probe",
  Version = "0.2.0",
  BuildVersion = "0.2.0.0",
  Id = "3c2b6895-8b9b-5d60-9f5f-12f94d8c46f9",
  Author = "inkgloSpace",
  Description = "PNG-in-SVG dynamic IconData compatibility probe for f5Rocket"
}

function GetColor(props)
  return { 7, 16, 31 }
end

function GetPrettyName(props)
  return "f5Rocket Compatibility Probe v" .. PluginInfo.Version
end
