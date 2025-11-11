#include "include/halo_feedback/halo_feedback_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "halo_feedback_plugin.h"

void HaloFeedbackPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  halo_feedback::HaloFeedbackPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
