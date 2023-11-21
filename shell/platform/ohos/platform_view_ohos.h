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

#ifndef OHOS_PLATFORM_VIEW_H
#define OHOS_PLATFORM_VIEW_H

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/ohos/context/ohos_context.h"
#include "flutter/shell/platform/ohos/napi/platform_view_ohos_napi.h"
#include "flutter/shell/platform/ohos/platform_message_handler_ohos.h"
#include "flutter/shell/platform/ohos/surface/ohos_native_window.h"
#include "flutter/shell/platform/ohos/surface/ohos_snapshot_surface_producer.h"
#include "flutter/shell/platform/ohos/surface/ohos_surface.h"
#include "flutter/shell/platform/ohos/vsync_waiter_ohos.h"

namespace flutter {

class OhosSurfaceFactoryImpl : public OhosSurfaceFactory {
 public:
  OhosSurfaceFactoryImpl(const std::shared_ptr<OHOSContext>& context,
                         bool enable_impeller);

  ~OhosSurfaceFactoryImpl() override;

  std::unique_ptr<OHOSSurface> CreateSurface() override;

 private:
  const std::shared_ptr<OHOSContext>& ohos_context_;
  const bool enable_impeller_;
};

class PlatformViewOHOS final : public PlatformView {
 public:
  PlatformViewOHOS(PlatformView::Delegate& delegate,
                   const flutter::TaskRunners& task_runners,
                   const std::shared_ptr<PlatformViewOHOSNapi>& napi_facade,
                   bool use_software_rendering,
                   uint8_t msaa_samples);

  PlatformViewOHOS(PlatformView::Delegate& delegate,
                   const flutter::TaskRunners& task_runners,
                   const std::shared_ptr<PlatformViewOHOSNapi>& napi_facade,
                   const std::shared_ptr<flutter::OHOSContext>& OHOS_context);

  ~PlatformViewOHOS() override;

  void NotifyCreate(fml::RefPtr<OHOSNativeWindow> native_window);

  void NotifySurfaceWindowChanged(fml::RefPtr<OHOSNativeWindow> native_window);

  void NotifyChanged(const SkISize& size);

  // |PlatformView|
  void NotifyDestroyed() override;

  // todo
  void DispatchPlatformMessage(std::string name,
                               void* message,
                               int messageLenth,
                               int reponseId);

  void DispatchEmptyPlatformMessage(std::string name, int reponseId);

  void DispatchSemanticsAction(int id,
                               int action,
                               void* actionData,
                               int actionDataLenth);

  // |PlatformView|
  void LoadDartDeferredLibrary(
      intptr_t loading_unit_id,
      std::unique_ptr<const fml::Mapping> snapshot_data,
      std::unique_ptr<const fml::Mapping> snapshot_instructions) override;

  void LoadDartDeferredLibraryError(intptr_t loading_unit_id,
                                    const std::string error_message,
                                    bool transient) override;

  // |PlatformView|
  void UpdateAssetResolverByType(
      std::unique_ptr<AssetResolver> updated_asset_resolver,
      AssetResolver::AssetResolverType type) override;

  const std::shared_ptr<OHOSContext>& GetOHOSContext() {
    return ohos_context_;
  }

  std::shared_ptr<PlatformMessageHandler> GetPlatformMessageHandler()
      const override {
    return platform_message_handler_;
  }

 private:
  const std::shared_ptr<PlatformViewOHOSNapi> napi_facade_;
  std::shared_ptr<OHOSContext> ohos_context_;

  std::shared_ptr<OHOSSurface> ohos_surface_;
  std::shared_ptr<PlatformMessageHandlerOHOS> platform_message_handler_;

  std::shared_ptr<OhosSurfaceFactoryImpl> surface_factory_;

  // |PlatformView|
  void UpdateSemantics(
      flutter::SemanticsNodeUpdates update,
      flutter::CustomAccessibilityActionUpdates actions) override;

  // |PlatformView|
  void HandlePlatformMessage(
      std::unique_ptr<flutter::PlatformMessage> message) override;

  // |PlatformView|
  void OnPreEngineRestart() const override;

  // |PlatformView|
  std::unique_ptr<VsyncWaiter> CreateVSyncWaiter() override;

  // |PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override;

  // |PlatformView|
  std::shared_ptr<ExternalViewEmbedder> CreateExternalViewEmbedder() override;

  // |PlatformView|
  std::unique_ptr<SnapshotSurfaceProducer> CreateSnapshotSurfaceProducer()
      override;

  // |PlatformView|
  sk_sp<GrDirectContext> CreateResourceContext() const override;

  // |PlatformView|
  void ReleaseResourceContext() const override;

  // |PlatformView|
  std::shared_ptr<impeller::Context> GetImpellerContext() const override;

  // |PlatformView|
  std::unique_ptr<std::vector<std::string>> ComputePlatformResolvedLocales(
      const std::vector<std::string>& supported_locale_data) override;

  // |PlatformView|
  void RequestDartDeferredLibrary(intptr_t loading_unit_id) override;

  void InstallFirstFrameCallback();

  void FireFirstFrameCallback();

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewOHOS);
};
}  // namespace flutter
#endif
