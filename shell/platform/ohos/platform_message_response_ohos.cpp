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

#include "flutter/shell/platform/ohos/platform_message_response_ohos.h"
#include <utility>
#include "flutter/fml/make_copyable.h"
#include "flutter/shell/platform/ohos/napi/platform_view_ohos_napi.h"

namespace flutter {

PlatformMessageResponseOHOS::PlatformMessageResponseOHOS(
    int response_id,
    std::shared_ptr<PlatformViewOHOSNapi> napi_facade,
    fml::RefPtr<fml::TaskRunner> platform_task_runner)
    : response_id_(response_id),
      napi_facade_(std::move(napi_facade)),
      platform_task_runner_(std::move(platform_task_runner)) {}

PlatformMessageResponseOHOS::~PlatformMessageResponseOHOS() = default;

void PlatformMessageResponseOHOS::Complete(std::unique_ptr<fml::Mapping> data) {
  // async post

  platform_task_runner_->PostTask(
      fml::MakeCopyable([response_id = response_id_, data = std::move(data),
                         napi_facede = napi_facade_]() mutable {
        napi_facede->FlutterViewHandlePlatformMessageResponse(response_id,
                                                              std::move(data));
      }));
}

void PlatformMessageResponseOHOS::CompleteEmpty() {
  platform_task_runner_->PostTask(
      fml::MakeCopyable([response_id = response_id_,  //
                         napi_facede = napi_facade_   //
  ]() {
        // Make the response call into Java.
        napi_facede->FlutterViewHandlePlatformMessageResponse(response_id,
                                                              nullptr);
      }));
}

}  // namespace flutter