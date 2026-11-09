local rapidjson = require("rapidjson")

local motionOffset = MOTION_MIN
local motionDirection = 1
local tickCount = 0
local measurementTicks = 0
local measurementStartedAt = 0
local activeScene = nil

-- Reuse this table; only IconData changes per rendered frame.
ProbeLegend = {
  DrawChrome = false,
  IconData = ""
}

-- Q-SYS timer objects must remain globally scoped so Lua GC cannot collect them.
ProbeTimer = Timer.New()

local function SelectedRate()
  if RATE_INTERVALS[Controls.Rate.String] == nil then
    Controls.Rate.String = "30 Hz"
  end
  return Controls.Rate.String
end

local function SelectedRenderMode()
  if Controls.RenderMode.String ~= "INLINE" and Controls.RenderMode.String ~= "DEFS+USE" then
    Controls.RenderMode.String = "INLINE"
  end
  return Controls.RenderMode.String
end

local function SelectedInstanceCount()
  if INSTANCE_COUNT_VALUES[Controls.InstanceCount.String] == nil then
    Controls.InstanceCount.String = "16"
  end
  return INSTANCE_COUNT_VALUES[Controls.InstanceCount.String]
end

local function SelectedImageSyntax()
  if Controls.ImageSyntax.String ~= "href" and Controls.ImageSyntax.String ~= "xlink:href" then
    Controls.ImageSyntax.String = "href"
  end
  return Controls.ImageSyntax.String
end

local function SelectedUseSyntax()
  if Controls.UseSyntax.String ~= "href" and Controls.UseSyntax.String ~= "xlink:href" then
    Controls.UseSyntax.String = "href"
  end
  return Controls.UseSyntax.String
end

local function UpdateRequestedHz()
  local rate = SelectedRate()
  Controls.RequestedHz.String = tostring(RATE_VALUES[rate]) .. " Hz"
end

local function RunningStatus()
  return "RUNNING " .. string.upper(SelectedRate()) .. " / " ..
    SelectedRenderMode() .. " / " .. tostring(SelectedInstanceCount())
end

local function RefreshSceneCache()
  local renderMode = SelectedRenderMode()
  local instanceCount = SelectedInstanceCount()
  local imageSyntax = SelectedImageSyntax()
  local useSyntax = SelectedUseSyntax()

  activeScene = PrepareCompatScene(renderMode, instanceCount, imageSyntax, useSyntax)

  local savings, inlineBytes, reuseBytes = CalculatePayloadSavings(
    instanceCount,
    imageSyntax,
    useSyntax
  )
  Controls.PayloadSavings.String = string.format("%.1f %%", savings)

  local pngOccurrences = 1
  if renderMode == "INLINE" then
    pngOccurrences = instanceCount
  end

  print(string.format(
    "[f5Rocket Compat] %s / %d: INLINE %d bytes, DEFS+USE %d bytes, savings %.1f%%, PNG payloads %d",
    renderMode,
    instanceCount,
    inlineBytes,
    reuseBytes,
    savings,
    pngOccurrences
  ))
end

local function RenderFrameUnsafe()
  local svg = BuildCompatSvg(activeScene, motionOffset)
  local encodedSvg = Crypto.Base64Encode(svg)

  ProbeLegend.IconData = encodedSvg
  Controls.Viewport.Legend = rapidjson.encode(ProbeLegend)

  return #svg, #encodedSvg
end

local function RenderFrame()
  -- os.clock() is CPU/process time, not wall-clock latency. It is diagnostic only.
  local startedAt = os.clock()
  local success, rawBytes, encodedBytes = pcall(RenderFrameUnsafe)
  local renderMs = (os.clock() - startedAt) * 1000

  Controls.LastRenderMs.String = string.format("%.3f ms CPU", renderMs)

  if not success then
    ProbeTimer:Stop()
    Controls.Run.Boolean = false
    Controls.Status.String = "ERROR: " .. tostring(rawBytes)
    print("[f5Rocket Compat] Render error: " .. tostring(rawBytes))
    return false
  end

  Controls.SvgBytes.String = tostring(rawBytes)
  Controls.SvgBase64Bytes.String = tostring(encodedBytes)
  return true
end

local function ResetMeasurementWindow()
  measurementTicks = 0
  measurementStartedAt = Timer.Now()
  Controls.MeasuredHz.String = "MEASURING"
end

local function StartProbe()
  ProbeTimer:Stop()
  UpdateRequestedHz()
  ResetMeasurementWindow()

  if RenderFrame() then
    Controls.Status.String = RunningStatus()
    ProbeTimer:Start(RATE_INTERVALS[SelectedRate()])
  end
end

local function StopProbe()
  ProbeTimer:Stop()
  Controls.Status.String = "STOPPED"
end

local function ResetProbe()
  ProbeTimer:Stop()
  Controls.Run.Boolean = false
  motionOffset = MOTION_MIN
  motionDirection = 1
  tickCount = 0
  measurementTicks = 0
  measurementStartedAt = Timer.Now()

  UpdateRequestedHz()
  RefreshSceneCache()
  Controls.MeasuredHz.String = "0.0 Hz"
  Controls.TickCount.String = "0"

  if RenderFrame() then
    Controls.Status.String = "IDLE"
  end
end

local function ApplyRateChange()
  UpdateRequestedHz()

  if Controls.Run.Boolean then
    ProbeTimer:Stop()
    ResetMeasurementWindow()
    if RenderFrame() then
      Controls.Status.String = RunningStatus()
      ProbeTimer:Start(RATE_INTERVALS[SelectedRate()])
    end
  else
    RenderFrame()
  end
end

local function ApplyRenderConfigurationChange()
  RefreshSceneCache()
  if RenderFrame() and Controls.Run.Boolean then
    Controls.Status.String = RunningStatus()
  end
end

local function UpdateMotionOffset()
  motionOffset = motionOffset + motionDirection * MOTION_STEP

  if motionOffset >= MOTION_MAX then
    motionOffset = MOTION_MAX
    motionDirection = -1
  elseif motionOffset <= MOTION_MIN then
    motionOffset = MOTION_MIN
    motionDirection = 1
  end
end

ProbeTimer.EventHandler = function()
  UpdateMotionOffset()

  if not RenderFrame() then
    return
  end

  tickCount = tickCount + 1
  measurementTicks = measurementTicks + 1
  Controls.TickCount.String = tostring(tickCount)

  local now = Timer.Now()
  local elapsed = now - measurementStartedAt
  if elapsed >= 1 then
    Controls.MeasuredHz.String = string.format("%.1f Hz", measurementTicks / elapsed)
    measurementTicks = 0
    measurementStartedAt = now
  end
end

Controls.Run.EventHandler = function(control)
  if control.Boolean then
    StartProbe()
  else
    StopProbe()
  end
end

Controls.Rate.EventHandler = function()
  SelectedRate()
  ApplyRateChange()
end

Controls.RenderMode.EventHandler = function()
  SelectedRenderMode()
  ApplyRenderConfigurationChange()
end

Controls.InstanceCount.EventHandler = function()
  SelectedInstanceCount()
  ApplyRenderConfigurationChange()
end

Controls.ImageSyntax.EventHandler = function()
  SelectedImageSyntax()
  ApplyRenderConfigurationChange()
end

Controls.UseSyntax.EventHandler = function()
  SelectedUseSyntax()
  ApplyRenderConfigurationChange()
end

Controls.Reset.EventHandler = function(control)
  if control.Boolean then
    ResetProbe()
  end
end

Controls.Rate.Choices = RATE_CHOICES
Controls.RenderMode.Choices = RENDER_MODE_CHOICES
Controls.InstanceCount.Choices = INSTANCE_COUNT_CHOICES
Controls.ImageSyntax.Choices = IMAGE_SYNTAX_CHOICES
Controls.UseSyntax.Choices = USE_SYNTAX_CHOICES
SelectedRate()
SelectedRenderMode()
SelectedInstanceCount()
SelectedImageSyntax()
SelectedUseSyntax()
ResetProbe()
