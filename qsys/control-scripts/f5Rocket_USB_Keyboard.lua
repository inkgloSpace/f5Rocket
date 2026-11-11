-- ============================================================
-- f5Rocket USB Keyboard Controller
-- Q-SYS Control Script v2
--
-- IMPORTANT:
-- 1. REMOVE the "USB Input" component from the design.
-- 2. f5Rocket Code Name = f5Rocket
-- 3. f5Rocket Script Access = All
--
-- Keyboard:
--   W / Arrow Up       = UP
--   S / Arrow Down     = DOWN
--   A / Arrow Left     = LEFT
--   D / Arrow Right    = RIGHT
--   SPACE              = FIRE
--   ENTER              = RUN
--   ESC                = STOP
--   P                  = PAUSE toggle
--
-- Supports simultaneous keys:
--   W + D + SPACE
-- ============================================================


---------------------------------------------------------------
-- CONFIG
---------------------------------------------------------------

local GAME_COMPONENT = "f5Rocket"


---------------------------------------------------------------
-- RAW LINUX / Q-SYS KEY CODES
--
-- Using numeric codes intentionally.
-- This avoids differences in Usb.Key enum naming.
---------------------------------------------------------------

local KEY = {
  ESC       = 1,

  W         = 17,
  P         = 25,
  ENTER     = 28,

  A         = 30,
  S         = 31,
  D         = 32,

  SPACE     = 57,

  KP_ENTER  = 96,

  UP        = 103,
  LEFT      = 105,
  RIGHT     = 106,
  DOWN      = 108
}


---------------------------------------------------------------
-- f5ROCKET COMPONENT
---------------------------------------------------------------

local game = Component.New(GAME_COMPONENT)

-- Map:
--
-- lower-case control name -> actual Q-SYS control object
--
local gameControls = {}


print("")
print("========================================")
print("f5Rocket COMPONENT CONTROLS")
print("========================================")

for name, control in pairs(game) do

  local normalized =
    string.lower(tostring(name))

  gameControls[normalized] = control

  print(
    "CONTROL:",
    tostring(name)
  )

end

print("========================================")
print("")


---------------------------------------------------------------
-- GAME CONTROL HELPERS
---------------------------------------------------------------

local function GetGameControl(name)

  if name == nil then
    return nil
  end

  return gameControls[
    string.lower(tostring(name))
  ]

end


local function SetGameControl(name, value)

  local control = GetGameControl(name)

  if control == nil then

    print(
      "[f5Rocket] CONTROL NOT FOUND:",
      tostring(name)
    )

    return false
  end

  control.Boolean = value

  return true

end


local function GetGameBoolean(name)

  local control = GetGameControl(name)

  if control == nil then
    return false
  end

  return control.Boolean

end


local function ToggleGameControl(name)

  local control = GetGameControl(name)

  if control == nil then

    print(
      "[f5Rocket] CONTROL NOT FOUND:",
      tostring(name)
    )

    return false
  end

  control.Boolean =
    not control.Boolean

  return true

end


---------------------------------------------------------------
-- CHECK REQUIRED CONTROLS
---------------------------------------------------------------

local requiredControls = {
  "Run",
  "Pause",
  "Up",
  "Down",
  "Left",
  "Right",
  "Fire"
}


print("f5Rocket CONTROL CHECK")

for _, name in ipairs(requiredControls) do

  if GetGameControl(name) then

    print(
      "OK:",
      name
    )

  else

    print(
      "MISSING:",
      name
    )

  end

end

print("----------------------------------------")


---------------------------------------------------------------
-- USB OBJECTS
--
-- Global references are intentional.
---------------------------------------------------------------

usbMonitor = UsbMonitor.New("input")

usbDevices = {}

-- Individual state for each USB event node.
deviceKeyStates = {}

-- Number of attached keyboard endpoints currently reporting
-- a given key as down.
globalKeyCounts = {}


---------------------------------------------------------------
-- KEY STATE HELPERS
---------------------------------------------------------------

local function IsKeyDown(code)

  return
    (globalKeyCounts[code] or 0) > 0

end


local function IncrementKey(code)

  globalKeyCounts[code] =
    (globalKeyCounts[code] or 0) + 1

end


local function DecrementKey(code)

  local count =
    (globalKeyCounts[code] or 0) - 1

  if count < 0 then
    count = 0
  end

  globalKeyCounts[code] = count

end


---------------------------------------------------------------
-- CONTINUOUS GAME INPUT
--
-- This is what allows true simultaneous keyboard control.
---------------------------------------------------------------

local function RefreshContinuousControls()

  local up =
    IsKeyDown(KEY.W) or
    IsKeyDown(KEY.UP)

  local down =
    IsKeyDown(KEY.S) or
    IsKeyDown(KEY.DOWN)

  local left =
    IsKeyDown(KEY.A) or
    IsKeyDown(KEY.LEFT)

  local right =
    IsKeyDown(KEY.D) or
    IsKeyDown(KEY.RIGHT)

  local fire =
    IsKeyDown(KEY.SPACE)


  SetGameControl(
    "Up",
    up
  )

  SetGameControl(
    "Down",
    down
  )

  SetGameControl(
    "Left",
    left
  )

  SetGameControl(
    "Right",
    right
  )

  SetGameControl(
    "Fire",
    fire
  )

end


---------------------------------------------------------------
-- COMMAND KEYS
---------------------------------------------------------------

local function HandleCommandKey(
  code,
  globalFirstPress
)

  if not globalFirstPress then
    return
  end


  -------------------------------------------------------------
  -- ENTER = RUN
  -------------------------------------------------------------

  if code == KEY.ENTER or
     code == KEY.KP_ENTER then

    if SetGameControl(
      "Run",
      true
    ) then

      print(
        "[f5Rocket] RUN"
      )

    end

    return
  end


  -------------------------------------------------------------
  -- ESC = STOP
  -------------------------------------------------------------

  if code == KEY.ESC then

    if SetGameControl(
      "Run",
      false
    ) then

      print(
        "[f5Rocket] STOP"
      )

    end

    return
  end


  -------------------------------------------------------------
  -- P = PAUSE TOGGLE
  -------------------------------------------------------------

  if code == KEY.P then

    if ToggleGameControl(
      "Pause"
    ) then

      print(
        "[f5Rocket] PAUSE =",
        tostring(
          GetGameBoolean("Pause")
        )
      )

    end

    return
  end

end


---------------------------------------------------------------
-- USB KEY EVENT
---------------------------------------------------------------

local function HandleKeyboardEvent(
  devnode,
  data
)

  if data == nil then
    return
  end


  -------------------------------------------------------------
  -- Q-SYS / Linux event:
  --
  -- Type 1 = KEY
  -------------------------------------------------------------

  if data.Type ~= 1 then
    return
  end


  local code =
    tonumber(data.Code)

  local value =
    tonumber(data.Value)


  if code == nil or
     value == nil then

    return
  end


  -------------------------------------------------------------
  -- Values:
  --
  -- 0 = released
  -- 1 = pressed
  -- 2 = repeat / held
  -------------------------------------------------------------

  if value ~= 0 and
     value ~= 1 and
     value ~= 2 then

    return
  end


  print(
    "KEY",
    code,
    "VALUE",
    value,
    "SOURCE",
    devnode
  )


  -------------------------------------------------------------
  -- Repeat event.
  --
  -- State is already down, so nothing needs changing.
  -------------------------------------------------------------

  if value == 2 then
    return
  end


  local states =
    deviceKeyStates[devnode]

  if states == nil then

    states = {}

    deviceKeyStates[devnode] =
      states

  end


  local wasDown =
    states[code] == true

  local isDown =
    value == 1


  -------------------------------------------------------------
  -- Ignore duplicate state from the same endpoint.
  -------------------------------------------------------------

  if wasDown == isDown then
    return
  end


  local globalWasDown =
    IsKeyDown(code)


  -------------------------------------------------------------
  -- PRESS
  -------------------------------------------------------------

  if isDown then

    states[code] = true

    IncrementKey(code)


  -------------------------------------------------------------
  -- RELEASE
  -------------------------------------------------------------

  else

    states[code] = false

    DecrementKey(code)

  end


  local globalIsDown =
    IsKeyDown(code)


  -------------------------------------------------------------
  -- Update movement/fire states.
  -------------------------------------------------------------

  RefreshContinuousControls()


  -------------------------------------------------------------
  -- Command keys are triggered only on the transition:
  --
  -- globally UP -> globally DOWN
  --
  -- Therefore if event5 and event9 both send ENTER/P,
  -- the command still runs only once.
  -------------------------------------------------------------

  local globalFirstPress =
    (not globalWasDown) and
    globalIsDown

  HandleCommandKey(
    code,
    globalFirstPress
  )

end


---------------------------------------------------------------
-- REMOVE DEVICE KEY STATES
--
-- Prevent stuck movement if keyboard/dongle is unplugged while
-- a key is held.
---------------------------------------------------------------

local function ReleaseDeviceKeys(
  devnode
)

  local states =
    deviceKeyStates[devnode]

  if states == nil then
    return
  end


  for code, down in pairs(states) do

    if down then
      DecrementKey(code)
    end

  end


  deviceKeyStates[devnode] =
    nil


  RefreshContinuousControls()

end


---------------------------------------------------------------
-- USB DEVICE MONITOR
---------------------------------------------------------------

usbMonitor.EventHandler =
  function(device)

    if device == nil or
       device.devnode == nil then

      return

    end


    local props =
      device.properties or {}


    -----------------------------------------------------------
    -- Keyboard detector
    -----------------------------------------------------------

    local keyboardFlag =
      props.ID_INPUT_KEYBOARD

    local isKeyboard =
      keyboardFlag == "1" or
      keyboardFlag == 1 or
      keyboardFlag == true


    if not isKeyboard then
      return
    end


    local devnode =
      device.devnode


    -----------------------------------------------------------
    -- DEVICE ADDED
    -----------------------------------------------------------

    if device.Added then

      print("")

      print(
        "[USB] KEYBOARD FOUND:",
        devnode
      )

      print(
        "[USB] VENDOR:",
        tostring(
          props.ID_VENDOR
        )
      )

      print(
        "[USB] MODEL:",
        tostring(
          props.ID_MODEL
        )
      )

      print(
        "[USB] INTERFACE:",
        tostring(
          props.ID_USB_INTERFACE_NUM
        )
      )


      local usb =
        Usb.New(devnode)


      deviceKeyStates[devnode] =
        {}


      usb.EventHandler =
        function(data)

          HandleKeyboardEvent(
            devnode,
            data
          )

        end


      usbDevices[devnode] =
        usb


      print(
        "[USB] ATTACHED:",
        devnode
      )


    -----------------------------------------------------------
    -- DEVICE REMOVED
    -----------------------------------------------------------

    else

      print(
        "[USB] KEYBOARD REMOVED:",
        devnode
      )


      ReleaseDeviceKeys(
        devnode
      )


      if usbDevices[devnode] then

        usbDevices[devnode].EventHandler =
          function()
          end

        usbDevices[devnode] =
          nil

      end

    end

  end


---------------------------------------------------------------
-- INITIAL STATE
---------------------------------------------------------------

SetGameControl(
  "Up",
  false
)

SetGameControl(
  "Down",
  false
)

SetGameControl(
  "Left",
  false
)

SetGameControl(
  "Right",
  false
)

SetGameControl(
  "Fire",
  false
)


print("")
print("========================================")
print("f5Rocket USB KEYBOARD READY")
print("========================================")
print("W / UP ARROW       = UP")
print("S / DOWN ARROW     = DOWN")
print("A / LEFT ARROW     = LEFT")
print("D / RIGHT ARROW    = RIGHT")
print("SPACE              = FIRE")
print("ENTER              = RUN")
print("ESC                = STOP")
print("P                  = PAUSE")
print("----------------------------------------")
print("Supports W + D + SPACE simultaneously")
print("========================================")
print("")
