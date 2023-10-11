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

#include "flutter/shell/platform/ohos/ohos_main.h"

#include "flutter/fml/command_line.h"
#include "flutter/fml/file.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/platform/ohos/napi_util.h"
#include "flutter/fml/platform/ohos/paths_ohos.h"
#include "flutter/fml/size.h"
#include "flutter/lib/ui/plugins/callback_cache.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"
#include "third_party/skia/include/core/SkFontMgr.h"

namespace flutter {

std::vector<std::string> StringArrayToVector(napi_env env,
                                             napi_value arrayValue) {
  napi_status status;
  uint32_t arrayLength = 0;
  status = napi_get_array_length(env, arrayValue, &arrayLength);
  LOGE("StringArrayToVector get array length  %{pubilc}d", arrayLength);
  if (status != napi_ok) {
    LOGE("StringArrayToVector napi_get_array_length error ");
  }
  std::vector<std::string> stringArray;
  for (uint32_t i = 0; i < arrayLength; i++) {
    napi_value elementValue;
    status = napi_get_element(env, arrayValue, i, &elementValue);
    if (status != napi_ok) {
      LOGE("StringArrayToVector napi_get_element error");
    }
    size_t stringLength;
    status = napi_get_value_string_utf8(env, elementValue, nullptr, 0,
                                        &stringLength);
    if (status != napi_ok) {
      LOGE("StringArrayToVector napi_get_value_string_utf8 error");
    }

    std::string stringValue(stringLength, '\0');
    status = napi_get_value_string_utf8(env, elementValue, &stringValue[0],
                                        stringLength + 1, nullptr);
    if (status != napi_ok) {
      LOGE("StringArrayToVector napi_get_value_string_utf8 error");
    }
    stringArray.push_back(stringValue);
  }
  return stringArray;
}

OhosMain::OhosMain(const flutter::Settings& settings)
    : settings_(settings), observatory_uri_callback_() {}

OhosMain::~OhosMain() = default;

static std::unique_ptr<OhosMain> g_flutter_main;

OhosMain& OhosMain::Get() {
  FML_CHECK(g_flutter_main) << "ensureInitializationComplete must have already "
                               "been called.";
  return *g_flutter_main;
}

const flutter::Settings& OhosMain::GetSettings() const {
  return settings_;
}

/**
 * @brief
 * @note
 * @param  context: common.Context, args: Array<string>, bundlePath: string,
 * appStoragePath: string, engineCachesPath: string, initTimeMillis: number
 * @return void
 */
void OhosMain::Init(napi_env env, napi_callback_info info) {
  size_t argc = 6;
  napi_value param[6];
  std::string kernelPath, appStoragePath, engineCachesPath;
  int64_t initTimeMillis;
  napi_get_cb_info(env, info, &argc, param, nullptr, nullptr);
  napi_get_value_int64(env, param[5], &initTimeMillis);
  fml::napi::GetString(env, param[2], kernelPath);
  fml::napi::GetString(env, param[3], appStoragePath);
  fml::napi::GetString(env, param[4], engineCachesPath);
  FML_DLOG(INFO) << "INIT kernelPath:" << kernelPath;
  FML_DLOG(INFO) << "appStoragePath:" << appStoragePath;
  FML_DLOG(INFO) << "engineCachesPath:" << engineCachesPath;
  FML_DLOG(INFO) << "initTimeMillis:" << initTimeMillis;
  std::vector<std::string> args;
  args.push_back("flutter");
  fml::napi::GetArrayString(env, param[1], args);
  for (std::vector<std::string>::iterator it = args.begin(); it != args.end();
       ++it) {
    FML_DLOG(INFO) << *it;
  }
  auto command_line = fml::CommandLineFromIterators(args.begin(), args.end());
  auto settings = SettingsFromCommandLine(command_line);
  flutter::DartCallbackCache::SetCachePath(appStoragePath);
  fml::paths::InitializeOhosCachesPath(std::string(engineCachesPath));
  flutter::DartCallbackCache::LoadCacheFromDisk();

  if (!flutter::DartVM::IsRunningPrecompiledCode() && kernelPath[0]) {
    auto application_kernel_path = kernelPath;
    if (fml::IsFile(application_kernel_path)) {
      FML_DLOG(INFO) << "application_kernel_path exist";
      settings.application_kernel_asset = application_kernel_path;
    }
  }

  settings.task_observer_add = [](intptr_t key, const fml::closure& callback) {
    FML_DLOG(INFO) << "task_observer_add:" << (int64_t)key;
    fml::MessageLoop::GetCurrent().AddTaskObserver(key, callback);
  };
  settings.task_observer_remove = [](intptr_t key) {
    FML_DLOG(INFO) << "task_observer_remove:" << (int64_t)key;
    fml::MessageLoop::GetCurrent().RemoveTaskObserver(key);
  };
  settings.log_message_callback = [](const std::string& tag,
                                     const std::string& message) {
    FML_DLOG(INFO) << tag << " " << message;
  };

  g_flutter_main.reset(new OhosMain(settings));
  // TODO : g_flutter_main->SetupObservatoryUriCallback(env);
}

napi_value OhosMain::NativeInit(napi_env env, napi_callback_info info) {
  OhosMain::Init(env, info);
  OHOSImageGenerator::ImageNativeInit(env, info);
  return nullptr;
}

}  // namespace flutter
