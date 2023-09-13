/*
 * Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "ohos_surface_vulkan_impeller.h"

#include <memory>
#include <utility>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"
#include "flutter/shell/gpu/gpu_surface_vulkan_impeller.h"
#include "flutter/vulkan/vulkan_native_surface_android.h"
#include "impeller/entity/vk/entity_shaders_vk.h"
#include "impeller/entity/vk/modern_shaders_vk.h"

namespace flutter {

std::shared_ptr<impeller::Context> CreateImpellerContext(
    const fml::RefPtr<vulkan::VulkanProcTable>& proc_table,
    const std::shared_ptr<fml::ConcurrentMessageLoop>& concurrent_loop) {
  std::vector<std::shared_ptr<fml::Mapping>> shader_mappings = {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_vk_data,
                                             impeller_entity_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_modern_shaders_vk_data,
                                             impeller_modern_shaders_vk_length),
  };

  PFN_vkGetInstanceProcAddr instance_proc_addr =
      proc_table->NativeGetInstanceProcAddr();

  auto context =
      impeller::ContextVK::Create(instance_proc_addr,                //
                                  shader_mappings,                   //
                                  nullptr,                           //
                                  concurrent_loop->GetTaskRunner(),  //
                                  "Android Impeller Vulkan Lib"      //
      );

  return context;
}

OHOSSurfaceVulkanImpeller::OHOSSurfaceVulkanImpeller(
    const std::shared_ptr<OHOSContext>& ohos_context)
    : OHOSSurface(ohos_context),
      proc_table_(fml::MakeRefCounted<vulkan::VulkanProcTable>()),
      workers_(fml::ConcurrentMessageLoop::Create()) {
  impeller_context_ = CreateImpellerContext(proc_table_, workers_);
  is_valid_ =
      proc_table_->HasAcquiredMandatoryProcAddresses() && impeller_context_;
}

OHOSSurfaceVulkanImpeller::~OHOSSurfaceVulkanImpeller() {}

// |OHOSSurface|
bool OHOSSurfaceVulkanImpeller::IsValid() const {
  return is_valid_;
}

// |OHOSSurface|
std::unique_ptr<Surface> OHOSSurfaceVulkanImpeller::CreateGPUSurface(
    GrDirectContext* gr_context) {
  if (!IsValid()) {
    return nullptr;
  }

  if (!native_window_ || !native_window_->IsValid()) {
    return nullptr;
  }

  std::unique_ptr<GPUSurfaceVulkanImpeller> gpu_surface =
      std::make_unique<GPUSurfaceVulkanImpeller>(impeller_context_);

  if (!gpu_surface->IsValid()) {
    return nullptr;
  }

  return gpu_surface;
}

// |OHOSSurface|
void OHOSSurfaceVulkanImpeller::TeardownOnScreenContext() {
  // do nothing
}

// |OHOSSurface|
bool OHOSSurfaceVulkanImpeller::OnScreenSurfaceResize(const SkISize& size) {
  return true;
}

// |OHOSSurface|
bool OHOSSurfaceVulkanImpeller::ResourceContextMakeCurrent() {
  // not support
  return false;
}

// |OHOSSurface|
bool OHOSSurfaceVulkanImpeller::ResourceContextClearCurrent() {
  // not support
  return false;
}

// |OHOSSurface|
std::shared_ptr<impeller::Context>
OHOSSurfaceVulkanImpeller::GetImpellerContext() {
  return impeller_context_;
}

// |OHOSSurface|
bool OHOSSurfaceVulkanImpeller::SetNativeWindow(
    fml::RefPtr<OHOSNativeWindow> window) {
  bool success = native_window_ && native_window_->IsValid();

  if (success) {
    auto& context_vk = impeller::ContextVK::Cast(*impeller_context_);
    auto surface = context_vk.CreateAndroidSurface(native_window_->Gethandle());

    if (!surface) {
      FML_LOG(ERROR) << "Could not create a vulkan surface.";
      return false;
    }

    context_vk.SetupSwapchain(std::move(surface));
    return true;
  }

  native_window_ = nullptr;
  return false;
}

}  // namespace flutter