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

#include "flutter/shell/platform/ohos/ohos_shell_holder.h"
#include "flutter/fml/native_library.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/ohos/ohos_display.h"

#include "flutter/fml/logging.h"

#include <sys/resource.h>
#include <sys/time.h>

namespace flutter {

static void OHOSPlatformThreadConfigSetter(
    const fml::Thread::ThreadConfig& config) {
  fml::Thread::SetCurrentThreadName(config);
  // set thread priority
  switch (config.priority) {
    case fml::Thread::ThreadPriority::BACKGROUND: {
      if (::setpriority(PRIO_PROCESS, 0, 10) != 0) {
        FML_DLOG(ERROR) << "Failed to set IO task runner priority";
      }
      break;
    }
    case fml::Thread::ThreadPriority::DISPLAY: {
      if (::setpriority(PRIO_PROCESS, 0, -1) != 0) {
        FML_DLOG(ERROR) << "Failed to set UI task runner priority";
      }
      break;
    }
    case fml::Thread::ThreadPriority::RASTER: {
      // Android describes -8 as "most important display threads, for
      // compositing the screen and retrieving input events". Conservatively
      // set the raster thread to slightly lower priority than it.
      if (::setpriority(PRIO_PROCESS, 0, -5) != 0) {
        // Defensive fallback. Depending on the OEM, it may not be possible
        // to set priority to -5.
        if (::setpriority(PRIO_PROCESS, 0, -2) != 0) {
          FML_DLOG(ERROR) << "Failed to set raster task runner priority";
        }
      }
      break;
    }
    default:
      if (::setpriority(PRIO_PROCESS, 0, 0) != 0) {
        FML_DLOG(ERROR) << "Failed to set priority";
      }
  }
}

static PlatformData GetDefaultPlatformData() {
  FML_DLOG(INFO) << "GetDefaultPlatformData";
  PlatformData platform_data;
  platform_data.lifecycle_state = "AppLifecycleState.detached";
  return platform_data;
}

OHOSShellHolder::OHOSShellHolder(
    const flutter::Settings& settings,
    std::shared_ptr<PlatformViewOHOSNapi> napi_facade,
    void* platform_loop)
    : settings_(settings), napi_facade_(napi_facade) {
  FML_DLOG(INFO) << " ohos shell holder constructor";
  static size_t thread_host_count = 1;
  auto thread_label = std::to_string(thread_host_count++);

  auto mask =
      ThreadHost::Type::UI | ThreadHost::Type::RASTER | ThreadHost::Type::IO;

  flutter::ThreadHost::ThreadHostConfig host_config(
      thread_label, mask, OHOSPlatformThreadConfigSetter);
  host_config.ui_config = fml::Thread::ThreadConfig(
      flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
          flutter::ThreadHost::Type::UI, thread_label),
      fml::Thread::ThreadPriority::DISPLAY);
  host_config.raster_config = fml::Thread::ThreadConfig(
      flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
          flutter::ThreadHost::Type::RASTER, thread_label),
      fml::Thread::ThreadPriority::RASTER);
  host_config.io_config = fml::Thread::ThreadConfig(
      flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
          flutter::ThreadHost::Type::IO, thread_label),
      fml::Thread::ThreadPriority::NORMAL);

  thread_host_ = std::make_shared<ThreadHost>(host_config);
  FML_DLOG(INFO) << "thred host config finish";
  fml::WeakPtr<PlatformViewOHOS> weak_platform_view;

  Shell::CreateCallback<PlatformView> on_create_platform_view =
      [&napi_facade, &weak_platform_view](Shell& shell) {
        FML_DLOG(INFO) << "on_create_platform_view";
        std::unique_ptr<PlatformViewOHOS> platform_view_OHOS;
        platform_view_OHOS = std::make_unique<PlatformViewOHOS>(
            shell,                   // delegate
            shell.GetTaskRunners(),  // task runners
            napi_facade,             // napi interop
            shell.GetSettings()
                .enable_software_rendering,   // use software rendering
            shell.GetSettings().msaa_samples  // msaa sample count
        );
        LOGI("on_create_platform_view LOGI");
        FML_LOG(INFO) << "on_create_platform_view end";
        weak_platform_view = platform_view_OHOS->GetWeakPtr();
        LOGI("on_create_platform_view LOGI2");
        FML_LOG(INFO) << "on_create_platform_view end1";
        std::vector<std::unique_ptr<Display>> displays;
        displays.push_back(std::make_unique<OHOSDisplay>(napi_facade));
        FML_DLOG(INFO) << "on_create_platform_view LOGI3";
        FML_LOG(INFO) << "on_create_platform_view end3";
        shell.OnDisplayUpdates(DisplayUpdateType::kStartup,
                               std::move(displays));
        LOGI("on_create_platform_view LOGI4");
        FML_LOG(INFO) << "on_create_platform_view end3";
        return platform_view_OHOS;
      };

  Shell::CreateCallback<Rasterizer> on_create_rasterizer = [](Shell& shell) {
    FML_DLOG(INFO) << "Create Rasterizer Callback";
    return std::make_unique<Rasterizer>(shell);
  };

  // The current thread will be used as the platform thread. Ensure that the
  // message loop is initialized.
  fml::MessageLoop::EnsureInitializedForCurrentThread(platform_loop);
  fml::RefPtr<fml::TaskRunner> raster_runner;
  fml::RefPtr<fml::TaskRunner> ui_runner;
  fml::RefPtr<fml::TaskRunner> io_runner;
  fml::RefPtr<fml::TaskRunner> platform_runner =
      fml::MessageLoop::GetCurrent().GetTaskRunner();
  raster_runner = thread_host_->raster_thread->GetTaskRunner();
  ui_runner = thread_host_->ui_thread->GetTaskRunner();
  io_runner = thread_host_->io_thread->GetTaskRunner();

  flutter::TaskRunners task_runners(thread_label,     // label
                                    platform_runner,  // platform
                                    raster_runner,    // raster
                                    ui_runner,        // ui
                                    io_runner         // io
  );

  napi_facade_->SetPlatformTaskRunner(platform_runner);
  FML_DLOG(INFO) << "before shell create";
  shell_ =
      Shell::Create(GetDefaultPlatformData(),  // window data
                    task_runners,              // task runners
                    settings_,                 // settings
                    on_create_platform_view,   // platform view create callback
                    on_create_rasterizer       // rasterizer create callback
      );
  FML_DLOG(INFO) << "shell create end";
  if (shell_) {
    shell_->GetDartVM()->GetConcurrentMessageLoop()->PostTaskToAllWorkers([]() {
      if (::setpriority(PRIO_PROCESS, gettid(), 1) != 0) {
        FML_DLOG(ERROR) << "Failed to set Workers task runner priority";
      }
    });

    LOGI("shell_ end");
    shell_->RegisterImageDecoder(
        [runner = task_runners.GetIOTaskRunner(),
         napi_facade = napi_facade_](sk_sp<SkData> buffer) {
          return OHOSImageGenerator::MakeFromData(std::move(buffer), runner,
                                                  napi_facade);
        },
        -1);

    FML_DLOG(INFO) << "Registered Android SDK image decoder (API level 28+)";
  }

  platform_view_ = weak_platform_view;
  FML_DCHECK(platform_view_);
  is_valid_ = shell_ != nullptr;
}

OHOSShellHolder::OHOSShellHolder(
    const Settings& settings,
    const std::shared_ptr<PlatformViewOHOSNapi>& napi_facade,
    const std::shared_ptr<ThreadHost>& thread_host,
    std::unique_ptr<Shell> shell,
    std::unique_ptr<OHOSAssetProvider> apk_asset_provider,
    const fml::WeakPtr<PlatformViewOHOS>& platform_view)
    : settings_(settings),
      platform_view_(platform_view),
      thread_host_(thread_host),
      shell_(std::move(shell)),
      assetProvider_(std::move(apk_asset_provider)),
      napi_facade_(napi_facade) {
  FML_DCHECK(napi_facade);
  FML_DCHECK(shell_);
  FML_DCHECK(shell_->IsSetup());
  FML_DCHECK(platform_view_);
  FML_DCHECK(thread_host_);
  is_valid_ = shell_ != nullptr;
}

bool OHOSShellHolder::IsValid() const {
  return is_valid_;
}

const flutter::Settings& OHOSShellHolder::GetSettings() const {
  return settings_;
}

std::unique_ptr<OHOSShellHolder> OHOSShellHolder::Spawn(
    std::shared_ptr<PlatformViewOHOSNapi> napi_facade,
    const std::string& entrypoint,
    const std::string& libraryUrl,
    const std::string& initial_route,
    const std::vector<std::string>& entrypoint_args) const {
  FML_DCHECK(shell_ && shell_->IsSetup())
      << "A new Shell can only be spawned "
         "if the current Shell is properly constructed";

  fml::WeakPtr<PlatformViewOHOS> weak_platform_view;
  PlatformViewOHOS* ohos_platform_view = platform_view_.get();
  FML_DCHECK(ohos_platform_view);
  std::shared_ptr<flutter::OHOSContext> ohos_context =
      ohos_platform_view->GetOHOSContext();
  FML_DCHECK(ohos_context);

  Shell::CreateCallback<PlatformView> on_create_platform_view =
      [&napi_facade, ohos_context, &weak_platform_view](Shell& shell) {
        std::unique_ptr<PlatformViewOHOS> platform_view_ohos;
        platform_view_ohos = std::make_unique<PlatformViewOHOS>(
            shell,                   // delegate
            shell.GetTaskRunners(),  // task runners
            napi_facade,              // JNI interop
            ohos_context          // Ohos context
        );
        weak_platform_view = platform_view_ohos->GetWeakPtr();
        return platform_view_ohos;
      };

  Shell::CreateCallback<Rasterizer> on_create_rasterizer = [](Shell& shell) {
    return std::make_unique<Rasterizer>(shell);
  };

  auto config = BuildRunConfiguration(entrypoint, libraryUrl, entrypoint_args);
  if (!config) {
    // If the RunConfiguration was null, the kernel blob wasn't readable.
    // Fail the whole thing.
    return nullptr;
  }

  std::unique_ptr<flutter::Shell> shell =
      shell_->Spawn(std::move(config.value()), initial_route,
                    on_create_platform_view, on_create_rasterizer);

  return std::unique_ptr<OHOSShellHolder>(new OHOSShellHolder(
      GetSettings(), napi_facade, thread_host_, std::move(shell),
      assetProvider_->Clone(), weak_platform_view));
}

fml::WeakPtr<PlatformViewOHOS> OHOSShellHolder::GetPlatformView() {
  FML_DCHECK(platform_view_);
  return platform_view_;
}

void OHOSShellHolder::NotifyLowMemoryWarning() {
  FML_DCHECK(shell_);
  shell_->NotifyLowMemoryWarning();
}

void OHOSShellHolder::Launch(
    std::unique_ptr<OHOSAssetProvider> apk_asset_provider,
    const std::string& entrypoint,
    const std::string& libraryUrl,
    const std::vector<std::string>& entrypoint_args) {
  FML_DLOG(INFO) << "Launch ...entrypoint<<" << entrypoint
                 << ",libraryUrl:" << libraryUrl;
  if (!IsValid()) {
    FML_DLOG(ERROR) << "Is Not Valid";
    return;
  }

  assetProvider_ = std::move(apk_asset_provider);
  auto config = BuildRunConfiguration(entrypoint, libraryUrl, entrypoint_args);
  if (!config) {
    return;
  }
  FML_LOG(INFO) << "start RunEngine";
  shell_->RunEngine(std::move(config.value()));
  FML_LOG(INFO) << "end Launch";
}

std::optional<RunConfiguration> OHOSShellHolder::BuildRunConfiguration(
    const std::string& entrypoint,
    const std::string& libraryUrl,
    const std::vector<std::string>& entrypoint_args) const {
  std::unique_ptr<IsolateConfiguration> isolate_configuration;
  FML_DLOG(INFO) << "entrypoint." << entrypoint.c_str();
  FML_DLOG(INFO) << "libraryUrl." << libraryUrl.c_str();
  if (flutter::DartVM::IsRunningPrecompiledCode()) {
    FML_LOG(INFO) << "isolate_configuration.";
    isolate_configuration = IsolateConfiguration::CreateForAppSnapshot();
  } else {
    std::unique_ptr<fml::Mapping> kernel_blob =
        fml::FileMapping::CreateReadOnly(
            GetSettings().application_kernel_asset);
    if (!kernel_blob) {
      FML_DLOG(ERROR) << "Unable to load the kernel blob asset.";
      return std::nullopt;
    }
    FML_LOG(INFO) << "CreateForKernel.";
    isolate_configuration =
        IsolateConfiguration::CreateForKernel(std::move(kernel_blob));
  }

  RunConfiguration config(std::move(isolate_configuration));
  config.AddAssetResolver(assetProvider_->Clone());

  {
    if (!entrypoint.empty() && !libraryUrl.empty()) {
      FML_LOG(INFO) << "SetEntrypointAndLibrary.";
      config.SetEntrypointAndLibrary(entrypoint, libraryUrl);
    } else if (!entrypoint.empty()) {
      FML_LOG(INFO) << "SetEntrypoint.";
      config.SetEntrypoint(entrypoint);
    }
    if (!entrypoint_args.empty()) {
      FML_LOG(INFO) << "SetEntrypointArgs.";
      config.SetEntrypointArgs(entrypoint_args);
    }
  }
  return config;
}

}  // namespace flutter
