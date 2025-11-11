#include "halo_feedback_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <string>
#include <vector>

namespace halo_feedback {

// static
void HaloFeedbackPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "halo_feedback",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<HaloFeedbackPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

HaloFeedbackPlugin::HaloFeedbackPlugin() {}

HaloFeedbackPlugin::~HaloFeedbackPlugin() {}

// Helper function to read registry value
std::wstring ReadRegistryString(HKEY hKey, const std::wstring& subKey, const std::wstring& valueName) {
  HKEY hOpenKey;
  LONG result = RegOpenKeyExW(hKey, subKey.c_str(), 0, KEY_READ, &hOpenKey);
  if (result != ERROR_SUCCESS) {
    return L"";
  }

  DWORD dataSize = 0;
  result = RegQueryValueExW(hOpenKey, valueName.c_str(), nullptr, nullptr, nullptr, &dataSize);
  if (result != ERROR_SUCCESS || dataSize == 0) {
    RegCloseKey(hOpenKey);
    return L"";
  }

  std::vector<wchar_t> buffer(dataSize / sizeof(wchar_t) + 1);
  result = RegQueryValueExW(hOpenKey, valueName.c_str(), nullptr, nullptr, reinterpret_cast<LPBYTE>(buffer.data()), &dataSize);
  RegCloseKey(hOpenKey);

  if (result != ERROR_SUCCESS) {
    return L"";
  }

  return std::wstring(buffer.data());
}

void HaloFeedbackPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else if (method_call.method_name().compare("getWindowsDeviceId") == 0) {
    // Try HKEY_USERS\.DEFAULT\Software\HaloAgent first
    std::wstring deviceId = ReadRegistryString(
        HKEY_USERS,
        L".DEFAULT\\Software\\HaloAgent",
        L"DEVICE_ID");

    // If not found, try HKEY_LOCAL_MACHINE\SOFTWARE\HaloAgent
    if (deviceId.empty()) {
      deviceId = ReadRegistryString(
          HKEY_LOCAL_MACHINE,
          L"SOFTWARE\\HaloAgent",
          L"DEVICE_ID");
    }

    // Convert wide string to UTF-8 string
    if (!deviceId.empty()) {
      int size_needed = WideCharToMultiByte(CP_UTF8, 0, deviceId.c_str(), -1, nullptr, 0, nullptr, nullptr);
      std::vector<char> utf8_string(size_needed);
      WideCharToMultiByte(CP_UTF8, 0, deviceId.c_str(), -1, utf8_string.data(), size_needed, nullptr, nullptr);
      result->Success(flutter::EncodableValue(std::string(utf8_string.data())));
    } else {
      result->Error("DEVICE_ID_NOT_FOUND", "Device ID not found in Windows Registry", nullptr);
    }
  } else {
    result->NotImplemented();
  }
}

}  // namespace halo_feedback
