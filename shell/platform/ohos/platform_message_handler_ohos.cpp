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

#include "flutter/shell/platform/ohos/platform_message_handler_ohos.h"
#include "flutter/fml/make_copyable.h"

namespace flutter {

PlatformMessageHandlerOHOS::PlatformMessageHandlerOHOS(
    const std::shared_ptr<PlatformViewOHOSNapi>& napi_facede,
    fml::RefPtr<fml::TaskRunner> platform_task_runner)
    : napi_facade_(napi_facede),
      platform_task_runner_(std::move(platform_task_runner)) {}

void PlatformMessageHandlerOHOS::HandlePlatformMessage(
    std::unique_ptr<flutter::PlatformMessage> message) {
  int response_id = next_response_id_.fetch_add(1);
  if (auto response = message->response()) {
    std::lock_guard lock(pending_responses_mutex_);
    pending_responses_[response_id] = response;
  }

  platform_task_runner_->PostTask(
      fml::MakeCopyable([response_id = response_id, napi_facede = napi_facade_,
                         message = std::move(message)]() mutable {
        napi_facede->FlutterViewHandlePlatformMessage(response_id,
                                                      std::move(message));
      }));
}

void PlatformMessageHandlerOHOS::InvokePlatformMessageResponseCallback(
    int response_id,
    std::unique_ptr<fml::Mapping> mapping) {
  if (!response_id) {
    return;
  }
  // TODO(gaaclarke): Move the jump to the ui thread here from
  // PlatformMessageResponseDart so we won't need to use a mutex anymore.
  fml::RefPtr<flutter::PlatformMessageResponse> message_response;
  {
    std::lock_guard lock(pending_responses_mutex_);
    auto it = pending_responses_.find(response_id);
    if (it == pending_responses_.end()) {
      return;
    }
    message_response = std::move(it->second);
    pending_responses_.erase(it);
  }

  message_response->Complete(std::move(mapping));
}

void PlatformMessageHandlerOHOS::InvokePlatformMessageEmptyResponseCallback(
    int response_id) {
  if (!response_id) {
    return;
  }
  fml::RefPtr<flutter::PlatformMessageResponse> message_response;
  {
    std::lock_guard lock(pending_responses_mutex_);
    auto it = pending_responses_.find(response_id);
    if (it == pending_responses_.end()) {
      return;
    }
    message_response = std::move(it->second);
    pending_responses_.erase(it);
  }
  message_response->CompleteEmpty();
}

}  // namespace flutter