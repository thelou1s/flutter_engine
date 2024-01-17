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

#ifndef OHOS_SHELL_HOLDER_H
#define OHOS_SHELL_HOLDER_H
#define FML_USED_ON_EMBEDDER
#include "flutter/assets/asset_manager.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/unique_fd.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/runtime/platform_data.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/thread_host.h"

#include "flutter/assets/asset_resolver.h"
#include "flutter/common/settings.h"
#include "flutter/shell/platform/ohos/napi/platform_view_ohos_napi.h"
#include "flutter/shell/platform/ohos/platform_view_ohos.h"

#include "napi_common.h"
#include "ohos_asset_provider.h"
#include "ohos_image_generator.h"

namespace flutter {

class OHOSShellHolder {
 public:
  OHOSShellHolder(const flutter::Settings& settings,
                  std::shared_ptr<PlatformViewOHOSNapi> napi_facade,
                  void* plateform_loop);

  ~OHOSShellHolder();
  bool IsValid() const;

  const flutter::Settings& GetSettings() const;

  fml::WeakPtr<PlatformViewOHOS> GetPlatformView();

  void NotifyLowMemoryWarning();

  void Launch(std::unique_ptr<OHOSAssetProvider> apk_asset_provider,
              const std::string& entrypoint,
              const std::string& libraryUrl,
              const std::vector<std::string>& entrypoint_args);

  std::unique_ptr<OHOSShellHolder> Spawn(
      std::shared_ptr<PlatformViewOHOSNapi> napi_facade,
      const std::string& entrypoint,
      const std::string& libraryUrl,
      const std::string& initial_route,
      const std::vector<std::string>& entrypoint_args) const;

  const std::shared_ptr<PlatformMessageHandler>& GetPlatformMessageHandler()
      const {
    LOGI("GetPlatformMessageHandler LOGI");
    return shell_->GetPlatformMessageHandler();
  }

 private:
  std::optional<RunConfiguration> BuildRunConfiguration(
      const std::string& entrypoint,
      const std::string& libraryUrl,
      const std::vector<std::string>& entrypoint_args) const;

  const flutter::Settings settings_;
  fml::WeakPtr<PlatformViewOHOS> platform_view_;
  std::shared_ptr<ThreadHost> thread_host_;
  std::unique_ptr<Shell> shell_;
  bool is_valid_ = false;
  uint64_t next_pointer_flow_id_ = 0;

  std::unique_ptr<OHOSAssetProvider> assetProvider_;

  std::shared_ptr<PlatformViewOHOSNapi> napi_facade_;

  OHOSShellHolder(const flutter::Settings& settings,
                  const std::shared_ptr<PlatformViewOHOSNapi>& napi_facade,
                  const std::shared_ptr<ThreadHost>& thread_host,
                  std::unique_ptr<Shell> shell,
                  std::unique_ptr<OHOSAssetProvider> apk_asset_provider,
                  const fml::WeakPtr<PlatformViewOHOS>& platform_view);

  static void ThreadDestructCallback(void* value);

  FML_DISALLOW_COPY_AND_ASSIGN(OHOSShellHolder);
};
}  // namespace flutter

#endif
