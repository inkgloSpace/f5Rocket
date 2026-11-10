PluginInfo = {
  Name = "f5Rocket Runtime Probe",
  Version = "0.1.0",
  BuildVersion = "0.1.0.0",
  Id = "c84db0f2-6a9e-4f45-9cd7-15b0d5c4c09e",
  Author = "inkgloSpace",
  Description = "Isolated timer, SVG, and IconData runtime lifecycle probe for f5Rocket"
}

function GetColor(props)
  return { 7, 16, 31 }
end

function GetPrettyName(props)
  return "f5Rocket Runtime Probe v" .. PluginInfo.Version
end
