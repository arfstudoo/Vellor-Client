#include "flutter_window.h"

#include <optional>
#include <dwmapi.h>
#include <uxtheme.h>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif
#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif
#ifndef DWMWA_BORDER_COLOR
#define DWMWA_BORDER_COLOR 34
#endif
#ifndef DWMWA_CAPTION_COLOR
#define DWMWA_CAPTION_COLOR 35
#endif
#ifndef DWMWA_TEXT_COLOR
#define DWMWA_TEXT_COLOR 36
#endif
#ifndef DWMWA_SYSTEMBACKDROP_TYPE
#define DWMWA_SYSTEMBACKDROP_TYPE 38
#endif

#define WM_TRAY_CALLBACK (WM_APP + 101)

typedef BOOL(WINAPI* fnSetPreferredAppMode)(int);

static void EnableMenuDarkMode() {
  HMODULE hUxtheme = LoadLibraryExW(L"uxtheme.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
  if (hUxtheme) {
    auto setAppMode = reinterpret_cast<fnSetPreferredAppMode>(GetProcAddress(hUxtheme, MAKEINTRESOURCEA(135)));
    if (setAppMode) {
      setAppMode(2);
    }
    FreeLibrary(hUxtheme);
  }
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::SetupTray() {
  HWND hwnd = GetHandle();
  if (!hwnd) return;

  EnableMenuDarkMode();

  memset(&nid_, 0, sizeof(nid_));
  nid_.cbSize = sizeof(NOTIFYICONDATAW);
  nid_.hWnd = hwnd;
  nid_.uID = 1;
  nid_.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  nid_.uCallbackMessage = WM_TRAY_CALLBACK;
  nid_.hIcon = LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON));
  if (!nid_.hIcon) {
    nid_.hIcon = LoadIcon(nullptr, IDI_APPLICATION);
  }
  wcscpy_s(nid_.szTip, L"Vellor Client");

  Shell_NotifyIconW(NIM_ADD, &nid_);
}

void FlutterWindow::RemoveTray() {
  if (nid_.hWnd) {
    Shell_NotifyIconW(NIM_DELETE, &nid_);
    memset(&nid_, 0, sizeof(nid_));
  }
}

void FlutterWindow::UpdateTray(bool connected, const std::wstring& tooltip) {
  is_connected_ = connected;
  if (!nid_.hWnd) return;

  if (!tooltip.empty()) {
    wcsncpy_s(nid_.szTip, tooltip.c_str(), _countof(nid_.szTip) - 1);
  } else {
    wcscpy_s(nid_.szTip, connected ? L"Vellor Client - \u041F\u043E\u0434\u043A\u043B\u044E\u0447\u0435\u043D\u043E"
                                   : L"Vellor Client - \u041E\u0442\u043A\u043B\u044E\u0447\u0435\u043D\u043E");
  }

  nid_.uFlags = NIF_TIP;
  Shell_NotifyIconW(NIM_MODIFY, &nid_);
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  HWND hwnd = GetHandle();
  if (hwnd) {
    BOOL darkMode = TRUE;
    ::DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &darkMode, sizeof(darkMode));

    COLORREF captionColor = RGB(11, 11, 14);
    ::DwmSetWindowAttribute(hwnd, DWMWA_CAPTION_COLOR, &captionColor, sizeof(captionColor));

    COLORREF textColor = RGB(225, 225, 230);
    ::DwmSetWindowAttribute(hwnd, DWMWA_TEXT_COLOR, &textColor, sizeof(textColor));

    COLORREF borderColor = RGB(28, 28, 34);
    ::DwmSetWindowAttribute(hwnd, DWMWA_BORDER_COLOR, &borderColor, sizeof(borderColor));

    DWORD corner = 2;
    ::DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &corner, sizeof(corner));

    DWORD backdrop = 2;
    ::DwmSetWindowAttribute(hwnd, DWMWA_SYSTEMBACKDROP_TYPE, &backdrop, sizeof(backdrop));
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  tray_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "dev.vellor/tray",
      &flutter::StandardMethodCodec::GetInstance());

  tray_channel_->SetMethodCallHandler(
      [this, hwnd](const flutter::MethodCall<flutter::EncodableValue>& call,
                   std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "updateStatus") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args) {
            auto conn_it = args->find(flutter::EncodableValue("connected"));
            auto text_it = args->find(flutter::EncodableValue("text"));
            bool conn = (conn_it != args->end() && std::holds_alternative<bool>(conn_it->second))
                            ? std::get<bool>(conn_it->second)
                            : false;
            std::string text = (text_it != args->end() && std::holds_alternative<std::string>(text_it->second))
                                   ? std::get<std::string>(text_it->second)
                                   : "";
            int wlen = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
            std::wstring wtext(wlen > 0 ? wlen : 1, 0);
            if (wlen > 0) {
              MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, &wtext[0], wlen);
            }
            this->UpdateTray(conn, wtext);
          }
          result->Success();
        } else if (call.method_name() == "showWindow") {
          ShowWindow(hwnd, SW_SHOW);
          ShowWindow(hwnd, SW_RESTORE);
          SetForegroundWindow(hwnd);
          result->Success();
        } else if (call.method_name() == "hideToTray") {
          ShowWindow(hwnd, SW_HIDE);
          result->Success();
        } else if (call.method_name() == "exitApp") {
          this->is_exiting_ = true;
          this->RemoveTray();
          DestroyWindow(hwnd);
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  SetupTray();

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  RemoveTray();

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_CLOSE: {
      if (is_exiting_) {
        break;
      }
      ShowWindow(hwnd, SW_HIDE);
      return 0;
    }

    case WM_TRAY_CALLBACK: {
      if (lparam == WM_LBUTTONUP || lparam == WM_LBUTTONDBLCLK) {
        ShowWindow(hwnd, SW_SHOW);
        ShowWindow(hwnd, SW_RESTORE);
        SetForegroundWindow(hwnd);
        return 0;
      } else if (lparam == WM_RBUTTONUP) {
        POINT pt;
        GetCursorPos(&pt);

        HMENU hMenu = CreatePopupMenu();
        AppendMenuW(hMenu, MF_STRING, 1001, L"\u041E\u0442\u043A\u0440\u044B\u0442\u044C");
        AppendMenuW(hMenu, MF_SEPARATOR, 0, nullptr);
        AppendMenuW(hMenu, MF_STRING, 1002, is_connected_ ? L"\u041E\u0442\u043A\u043B\u044E\u0447\u0438\u0442\u044C VPN"
                                                          : L"\u041F\u043E\u0434\u043A\u043B\u044E\u0447\u0438\u0442\u044C VPN");
        AppendMenuW(hMenu, MF_SEPARATOR, 0, nullptr);
        AppendMenuW(hMenu, MF_STRING, 1003, L"\u0412\u044B\u0445\u043E\u0434");

        SetForegroundWindow(hwnd);
        int cmd = TrackPopupMenu(hMenu, TPM_RETURNCMD | TPM_NONOTIFY | TPM_RIGHTBUTTON,
                                pt.x, pt.y, 0, hwnd, nullptr);
        DestroyMenu(hMenu);

        if (cmd == 1001) {
          ShowWindow(hwnd, SW_SHOW);
          ShowWindow(hwnd, SW_RESTORE);
          SetForegroundWindow(hwnd);
        } else if (cmd == 1002) {
          if (tray_channel_) {
            tray_channel_->InvokeMethod("toggleConnect", nullptr);
          }
        } else if (cmd == 1003) {
          if (tray_channel_) {
            tray_channel_->InvokeMethod("requestExit", nullptr);
          } else {
            is_exiting_ = true;
            RemoveTray();
            DestroyWindow(hwnd);
          }
        }
        return 0;
      }
      break;
    }

    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
