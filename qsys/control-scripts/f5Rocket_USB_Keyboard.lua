-- f5Rocket USB HID Keyboard Controller
-- Q-SYS Control Script for a physical USB keyboard connected to a Core USB-A port.
--
-- Requirements:
--   1. The f5Rocket plugin component Code Name must be: f5Rocket
--   2. Script Access must be enabled for the f5Rocket component.
--   3. Paste this file into a Q-SYS Control Script component.
--   4. Run the design on a Core with a USB-A host port.
--
-- Key mapping:
--   W / Up Arrow       -> Up
--   S / Down Arrow     -> Down
--   A / Left Arrow     -> Left
--   D / Right Arrow    -> Right
--   Space              -> Fire
--   Enter / KP Enter   -> Run / Restart
--   P                  -> Pause toggle
--
-- Notes:
--   - Key value 0 = release, 1 = press, 2 = held/repeat.
--   - Movement and Fire preserve true simultaneous key state.
--   - Run and Pause react only to the initial press, not repeat events.
--   - UsbMonitor / Usb objects are intentionally global to avoid garbage collection.

GAME_COMPONENT_NAME = "f5Rocket"

Game = Component.New(GAME_COMPONENT_NAME)

UsbKeyboardMonitor = UsbMonitor.New("input")
UsbKeyboardDevices = {}

-- Per-action token sets. A token is devnode:keycode, so multiple physical
-- keys (for example W + Up Arrow) and multiple keyboards can safely share
-- one f5Rocket control without premature release.
UsbKeyboardHeld = {
  Up = {},
  Down = {},
  Left = {},
  Right = {},
  Fire = {}
}

UsbKeyboardDeviceTokens = {}
UsbKeyboardKeyMap = {}

local function AddMappedKey(keyName, action)
  local code = Usb.Key[keyName]
  if code ~= nil then
    UsbKeyboardKeyMap[code] = action
  else
    print("[f5Rocket USB] Usb.Key." .. keyName .. " is unavailable on this Q-SYS version")
  end
end

AddMappedKey("KEY_W", "Up")
AddMappedKey("KEY_UP", "Up")
AddMappedKey("KEY_S", "Down")
AddMappedKey("KEY_DOWN", "Down")
AddMappedKey("KEY_A", "Left")
AddMappedKey("KEY_LEFT", "Left")
AddMappedKey("KEY_D", "Right")
AddMappedKey("KEY_RIGHT", "Right")
AddMappedKey("KEY_SPACE", "Fire")

local RUN_KEYS = {}
if Usb.Key.KEY_ENTER ~= nil then
  RUN_KEYS[Usb.Key.KEY_ENTER] = true
end
if Usb.Key.KEY_KPENTER ~= nil then
  RUN_KEYS[Usb.Key.KEY_KPENTER] = true
end

local PAUSE_KEYS = {}
if Usb.Key.KEY_P ~= nil then
  PAUSE_KEYS[Usb.Key.KEY_P] = true
end

local function SetGameBoolean(controlName, value)
  local control = Game[controlName]
  if control ~= nil and control.Boolean ~= value then
    control.Boolean = value
  end
end

local function RefreshAction(action)
  SetGameBoolean(action, next(UsbKeyboardHeld[action]) ~= nil)
end

local function SetHeld(devnode, code, action, isHeld)
  local token = devnode .. ":" .. tostring(code)

  if UsbKeyboardDeviceTokens[devnode] == nil then
    UsbKeyboardDeviceTokens[devnode] = {}
  end

  if isHeld then
    UsbKeyboardHeld[action][token] = true
    UsbKeyboardDeviceTokens[devnode][token] = action
  else
    UsbKeyboardHeld[action][token] = nil
    UsbKeyboardDeviceTokens[devnode][token] = nil
  end

  RefreshAction(action)
end

local function ReleaseDevice(devnode)
  local tokens = UsbKeyboardDeviceTokens[devnode]
  if tokens == nil then
    return
  end

  local changed = {}
  for token, action in pairs(tokens) do
    UsbKeyboardHeld[action][token] = nil
    changed[action] = true
  end

  UsbKeyboardDeviceTokens[devnode] = nil

  for action, _ in pairs(changed) do
    RefreshAction(action)
  end
end

local function ReleaseAllGameplayKeys()
  for action, tokens in pairs(UsbKeyboardHeld) do
    for token, _ in pairs(tokens) do
      tokens[token] = nil
    end
    SetGameBoolean(action, false)
  end

  UsbKeyboardDeviceTokens = {}
end

local function HandleKeyboardData(devnode, data)
  if data == nil or data.Type ~= Usb.Type.KEY then
    return
  end

  local action = UsbKeyboardKeyMap[data.Code]
  if action ~= nil then
    if data.Value == 0 then
      SetHeld(devnode, data.Code, action, false)
    elseif data.Value == 1 or data.Value == 2 then
      SetHeld(devnode, data.Code, action, true)
    end
    return
  end

  -- Momentary Run / Restart: only the first press event.
  if RUN_KEYS[data.Code] and data.Value == 1 then
    if Game["Run"] ~= nil then
      Game["Run"].Boolean = true
    end
    return
  end

  -- Toggle Pause: ignore held/repeat events so one physical key press toggles once.
  if PAUSE_KEYS[data.Code] and data.Value == 1 then
    if Game["Pause"] ~= nil then
      Game["Pause"].Boolean = not Game["Pause"].Boolean
    end
  end
end

local function IsUsbKeyboard(device)
  if device == nil or device.devnode == nil then
    return false
  end

  if string.sub(device.devnode, 1, 16) ~= "/dev/input/event" then
    return false
  end

  local properties = device.properties or {}

  return properties.ID_BUS == "usb" and
    (properties.ID_INPUT_KEYBOARD == "1" or properties.ID_INPUT_KEY == "1")
end

local function AttachUsbKeyboard(device)
  local devnode = device.devnode

  if UsbKeyboardDevices[devnode] ~= nil then
    return
  end

  local usbDevice = Usb.New(devnode)
  UsbKeyboardDevices[devnode] = usbDevice
  UsbKeyboardDeviceTokens[devnode] = UsbKeyboardDeviceTokens[devnode] or {}

  usbDevice.EventHandler = function(data)
    HandleKeyboardData(devnode, data)
  end

  local properties = device.properties or {}
  print(
    "[f5Rocket USB] Keyboard attached:",
    devnode,
    properties.ID_VENDOR or "?",
    properties.ID_MODEL or "?"
  )
end

local function DetachUsbKeyboard(device)
  local devnode = device.devnode
  if devnode == nil then
    return
  end

  ReleaseDevice(devnode)

  local usbDevice = UsbKeyboardDevices[devnode]
  if usbDevice ~= nil then
    usbDevice.EventHandler = function() end
    UsbKeyboardDevices[devnode] = nil
  end

  print("[f5Rocket USB] Keyboard detached:", devnode)
end

UsbKeyboardMonitor.EventHandler = function(device)
  if not IsUsbKeyboard(device) then
    return
  end

  if device.Added then
    AttachUsbKeyboard(device)
  else
    DetachUsbKeyboard(device)
  end
end

-- Start from a neutral gameplay input state.
ReleaseAllGameplayKeys()

print("[f5Rocket USB] Ready")
print("[f5Rocket USB] Waiting for USB HID keyboard on a Core USB-A port")
print("[f5Rocket USB] Target component Code Name:", GAME_COMPONENT_NAME)
