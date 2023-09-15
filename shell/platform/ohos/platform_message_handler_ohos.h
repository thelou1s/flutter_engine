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

#ifndef PLATFORM_MESSAGE_HANDLER_OHOS_H
#define PLATFORM_MESSAGE_HANDLER_OHOS_H
#include <memory>
#include <mutex>
#include <unordered_map>

#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/shell/common/platform_message_handler.h"
#include "flutter/shell/platform/ohos/napi/platform_view_ohos_napi.h"

namespace flutter {

class PlatformMessageHandlerOHOS : public PlatformMessageHandler {
 public:
  explicit PlatformMessageHandlerOHOS(
      const std::shared_ptr<PlatformViewOHOSNapi>& napi_facede,
      fml::RefPtr<fml::TaskRunner> platform_task_runner);
  void HandlePlatformMessage(std::unique_ptr<PlatformMessage> message) override;
  bool DoesHandlePlatformMessageOnPlatformThread() const override {
    return true;
  }
  void InvokePlatformMessageResponseCallback(
      int response_id,
      std::unique_ptr<fml::Mapping> mapping) override;

  void InvokePlatformMessageEmptyResponseCallback(int response_id) override;

 private:
  const std::shared_ptr<PlatformViewOHOSNapi> napi_facade_;
  const fml::RefPtr<fml::TaskRunner> platform_task_runner_;
  std::atomic<int> next_response_id_ = 1;
  std::unordered_map<int, fml::RefPtr<flutter::PlatformMessageResponse>>
      pending_responses_;
  std::mutex pending_responses_mutex_;
};

}  // namespace flutter
#endif