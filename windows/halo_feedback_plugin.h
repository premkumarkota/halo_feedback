#ifndef FLUTTER_PLUGIN_HALO_FEEDBACK_PLUGIN_H_
#define FLUTTER_PLUGIN_HALO_FEEDBACK_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace halo_feedback {

class HaloFeedbackPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  HaloFeedbackPlugin();

  virtual ~HaloFeedbackPlugin();

  // Disallow copy and assign.
  HaloFeedbackPlugin(const HaloFeedbackPlugin&) = delete;
  HaloFeedbackPlugin& operator=(const HaloFeedbackPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace halo_feedback

#endif  // FLUTTER_PLUGIN_HALO_FEEDBACK_PLUGIN_H_
