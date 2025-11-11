//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <halo_feedback/halo_feedback_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) halo_feedback_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "HaloFeedbackPlugin");
  halo_feedback_plugin_register_with_registrar(halo_feedback_registrar);
}
