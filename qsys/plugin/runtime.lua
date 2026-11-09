local rapidjson = require("rapidjson")

local spriteX = 0
local spriteDirection = 1
local tickCount = 0
local measurementTicks = 0
local measurementStartedAt = 0

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

local function SelectedSyntax()
  if Controls.ImageSyntax.String ~= "href" and Controls.ImageSyntax.String ~= "xlink:href" then
    Controls.ImageSyntax.String = "href"
  end
  return Controls.ImageSyntax.String
end

local function UpdateRequestedHz()
  local rate = SelectedRate()
  Controls.RequestedHz.String = tostring(RATE_VALUES[rate]) .. " Hz"
end

local function RunningStatus()
  return "RUNNING " .. string.upper(SelectedRate()) .. " / " .. SelectedSyntax()
end

local function RenderFrameUnsafe()
  local svg = BuildCompatSvg(spriteX, SelectedSyntax())
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
  spriteX = 0
  spriteDirection = 1
  tickCount = 0
  measurementTicks = 0
  measurementStartedAt = Timer.Now()

  UpdateRequestedHz()
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

local function ApplySyntaxChange()
  if RenderFrame() and Controls.Run.Boolean then
    Controls.Status.String = RunningStatus()
  end
end

local function UpdateSpritePosition()
  spriteX = spriteX + spriteDirection * SPRITE_STEP

  if spriteX >= MAX_SPRITE_X then
    spriteX = MAX_SPRITE_X
    spriteDirection = -1
  elseif spriteX <= 0 then
    spriteX = 0
    spriteDirection = 1
  end
end

ProbeTimer.EventHandler = function()
  UpdateSpritePosition()

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

Controls.ImageSyntax.EventHandler = function()
  SelectedSyntax()
  ApplySyntaxChange()
end

Controls.Reset.EventHandler = function(control)
  if control.Boolean then
    ResetProbe()
  end
end

Controls.Rate.Choices = RATE_CHOICES
Controls.ImageSyntax.Choices = SYNTAX_CHOICES
SelectedRate()
SelectedSyntax()
ResetProbe()
