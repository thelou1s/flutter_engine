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

#ifndef __OHOS__MAIN__H
#define __OHOS__MAIN__H
#define FML_USED_ON_EMBEDDER
#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "napi/native_api.h"
#include "napi_common.h"
#include "ohos_image_generator.h"

namespace flutter {
class OhosMain {
 public:
  ~OhosMain();
  static OhosMain& Get();
  const flutter::Settings& GetSettings() const;
  static napi_value NativeInit(napi_env env, napi_callback_info info);

 private:
  const flutter::Settings settings_;
  DartServiceIsolate::CallbackHandle observatory_uri_callback_;

  explicit OhosMain(const flutter::Settings& settings);

  static void Init(napi_env env, napi_callback_info info);

  void SetupObservatoryUriCallback(napi_env env, napi_callback_info info);
  FML_DISALLOW_COPY_AND_ASSIGN(OhosMain);
};
}  // namespace flutter
#endif
