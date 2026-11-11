#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>

#include <atomic>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#pragma comment(lib, "Ws2_32.lib")
#pragma comment(lib, "User32.lib")

namespace {

constexpr const char* kHost = "127.0.0.1";
constexpr unsigned short kPort = 1710;
constexpr const char* kComponentName = "f5Rocket";
constexpr DWORD kPollMs = 8;
constexpr DWORD kReconnectMs = 1000;

std::atomic<bool> gRunning{true};
SOCKET gSocket = INVALID_SOCKET;
unsigned long gRequestId = 1;

struct ControlValue {
  const char* name;
  bool value;
};

bool KeyDown(int virtualKey) {
  return (GetAsyncKeyState(virtualKey) & 0x8000) != 0;
}

void CloseSocket() {
  if (gSocket != INVALID_SOCKET) {
    shutdown(gSocket, SD_BOTH);
    closesocket(gSocket);
    gSocket = INVALID_SOCKET;
  }
}

std::string JsonBool(bool value) {
  return value ? "true" : "false";
}

bool SendRaw(const std::string& payload) {
  if (gSocket == INVALID_SOCKET) {
    return false;
  }

  const std::string framed = payload + '\0';
  const char* data = framed.data();
  int remaining = static_cast<int>(framed.size());

  while (remaining > 0) {
    const int sent = send(gSocket, data, remaining, 0);
    if (sent == SOCKET_ERROR || sent == 0) {
      CloseSocket();
      return false;
    }
    data += sent;
    remaining -= sent;
  }

  return true;
}

bool SendControls(const std::vector<ControlValue>& controls) {
  if (controls.empty()) {
    return true;
  }

  std::ostringstream json;
  json << "{\"jsonrpc\":\"2.0\",\"id\":" << gRequestId++
       << ",\"method\":\"Component.Set\",\"params\":{\"Name\":\""
       << kComponentName << "\",\"Controls\":[";

  for (size_t i = 0; i < controls.size(); ++i) {
    if (i != 0) {
      json << ',';
    }
    json << "{\"Name\":\"" << controls[i].name
         << "\",\"Value\":" << JsonBool(controls[i].value) << '}';
  }

  json << "]}}";
  return SendRaw(json.str());
}

void ReleaseGameplayControls() {
  if (gSocket == INVALID_SOCKET) {
    return;
  }

  SendControls({
      {"Up", false},
      {"Down", false},
      {"Left", false},
      {"Right", false},
      {"Fire", false},
  });
}

BOOL WINAPI ConsoleHandler(DWORD eventType) {
  switch (eventType) {
    case CTRL_C_EVENT:
    case CTRL_BREAK_EVENT:
    case CTRL_CLOSE_EVENT:
    case CTRL_LOGOFF_EVENT:
    case CTRL_SHUTDOWN_EVENT:
      gRunning = false;
      ReleaseGameplayControls();
      CloseSocket();
      return TRUE;
    default:
      return FALSE;
  }
}

bool ConnectQrc() {
  CloseSocket();

  SOCKET socketHandle = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (socketHandle == INVALID_SOCKET) {
    return false;
  }

  sockaddr_in address{};
  address.sin_family = AF_INET;
  address.sin_port = htons(kPort);

  if (inet_pton(AF_INET, kHost, &address.sin_addr) != 1) {
    closesocket(socketHandle);
    return false;
  }

  if (connect(socketHandle, reinterpret_cast<sockaddr*>(&address),
              sizeof(address)) == SOCKET_ERROR) {
    closesocket(socketHandle);
    return false;
  }

  gSocket = socketHandle;

  // Start from a neutral gameplay state. Pause is intentionally not changed.
  if (!SendControls({
          {"Up", false},
          {"Down", false},
          {"Left", false},
          {"Right", false},
          {"Fire", false},
      })) {
    return false;
  }

  return true;
}

void PrintHeader() {
  SetConsoleTitleA("f5Rocket Keyboard Bridge");
  std::cout
      << "f5Rocket Keyboard Bridge - Windows x64\n"
      << "QRC target : " << kHost << ':' << kPort << "\n"
      << "Component  : " << kComponentName << "\n\n"
      << "Controls\n"
      << "  W / Up Arrow       Up\n"
      << "  S / Down Arrow     Down\n"
      << "  A / Left Arrow     Left\n"
      << "  D / Right Arrow    Right\n"
      << "  Space              Fire\n"
      << "  Enter              Run / Restart\n"
      << "  P                  Pause toggle\n"
      << "  F12                Exit\n\n"
      << "In Q-SYS Designer, set the f5Rocket plugin Code Name to \""
      << kComponentName << "\" and start Emulate mode.\n\n";
}

}  // namespace

int main() {
  PrintHeader();

  WSADATA wsaData{};
  if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
    std::cerr << "[ERROR] Winsock initialization failed.\n";
    return 1;
  }

  SetConsoleCtrlHandler(ConsoleHandler, TRUE);

  bool lastUp = false;
  bool lastDown = false;
  bool lastLeft = false;
  bool lastRight = false;
  bool lastFire = false;
  bool lastEnter = false;
  bool lastPauseKey = false;
  bool lastF12 = false;
  bool pauseState = false;

  ULONGLONG nextReconnectAt = 0;
  bool wasConnected = false;

  while (gRunning) {
    if (gSocket == INVALID_SOCKET) {
      const ULONGLONG now = GetTickCount64();
      if (now >= nextReconnectAt) {
        if (ConnectQrc()) {
          std::cout << "[CONNECTED] Q-SYS Designer Emulate at "
                    << kHost << ':' << kPort << "\n";
          wasConnected = true;

          // Force the next poll to publish the actual current key state.
          lastUp = false;
          lastDown = false;
          lastLeft = false;
          lastRight = false;
          lastFire = false;
        } else {
          if (wasConnected) {
            std::cout << "[DISCONNECTED] Reconnecting...\n";
          } else {
            std::cout << "[WAITING] Start Q-SYS Designer Emulate (F6)...\n";
          }
          wasConnected = false;
          nextReconnectAt = now + kReconnectMs;
        }
      }

      Sleep(kPollMs);
      continue;
    }

    const bool up = KeyDown('W') || KeyDown(VK_UP);
    const bool down = KeyDown('S') || KeyDown(VK_DOWN);
    const bool left = KeyDown('A') || KeyDown(VK_LEFT);
    const bool right = KeyDown('D') || KeyDown(VK_RIGHT);
    const bool fire = KeyDown(VK_SPACE);
    const bool enter = KeyDown(VK_RETURN);
    const bool pauseKey = KeyDown('P');
    const bool f12 = KeyDown(VK_F12);

    std::vector<ControlValue> changed;
    if (up != lastUp) changed.push_back({"Up", up});
    if (down != lastDown) changed.push_back({"Down", down});
    if (left != lastLeft) changed.push_back({"Left", left});
    if (right != lastRight) changed.push_back({"Right", right});
    if (fire != lastFire) changed.push_back({"Fire", fire});

    bool sendOk = true;
    if (!changed.empty()) {
      sendOk = SendControls(changed);
    }

    if (sendOk && enter && !lastEnter) {
      // Run is momentary in the plugin; true is enough because runtime resets it.
      sendOk = SendControls({{"Run", true}});
    }

    if (sendOk && pauseKey && !lastPauseKey) {
      pauseState = !pauseState;
      sendOk = SendControls({{"Pause", pauseState}});
    }

    if (!sendOk) {
      std::cout << "[DISCONNECTED] QRC connection lost. Reconnecting...\n";
      CloseSocket();
      wasConnected = false;
      nextReconnectAt = GetTickCount64() + kReconnectMs;
    }

    lastUp = up;
    lastDown = down;
    lastLeft = left;
    lastRight = right;
    lastFire = fire;
    lastEnter = enter;
    lastPauseKey = pauseKey;

    if (f12 && !lastF12) {
      gRunning = false;
    }
    lastF12 = f12;

    Sleep(kPollMs);
  }

  ReleaseGameplayControls();
  CloseSocket();
  WSACleanup();

  std::cout << "[EXIT] Gameplay controls released.\n";
  return 0;
}
