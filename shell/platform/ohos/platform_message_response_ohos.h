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

#ifndef PLATFORM_MESSAGE_REPONSE_OHOS_H
#define PLATFORM_MESSAGE_REPONSE_OHOS_H

#include "flutter/fml/macros.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/window/platform_message_response.h"
#include "flutter/shell/platform/ohos/napi/platform_view_ohos_napi.h"

#include "flutter/shell/platform/ohos/napi/platform_view_ohos_napi.h"

namespace flutter {

class PlatformMessageResponseOHOS : public flutter::PlatformMessageResponse {
 public:
  // |flutter::PlatformMessageResponse|
  void Complete(std::unique_ptr<fml::Mapping> data) override;

  // |flutter::PlatformMessageResponse|
  void CompleteEmpty() override;

 private:
  PlatformMessageResponseOHOS(
      int response_id,
      std::shared_ptr<PlatformViewOHOSNapi> napi_facade,
      fml::RefPtr<fml::TaskRunner> platform_task_runner);

  ~PlatformMessageResponseOHOS() override;

  const int response_id_;
  const std::shared_ptr<PlatformViewOHOSNapi> napi_facade_;
  const fml::RefPtr<fml::TaskRunner> platform_task_runner_;

  FML_FRIEND_MAKE_REF_COUNTED(PlatformMessageResponseOHOS);
  FML_DISALLOW_COPY_AND_ASSIGN(PlatformMessageResponseOHOS);
};

}  // namespace flutter
#endif