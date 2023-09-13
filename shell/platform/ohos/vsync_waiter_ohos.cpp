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

#include "flutter/shell/platform/ohos/vsync_waiter_ohos.h"
#include "flutter/fml/logging.h"
#include "napi_common.h"

namespace flutter {

static std::atomic_uint g_refresh_rate_ = 60;

const char* flutterSyncName = "flutter_connect";

VsyncWaiterOHOS::VsyncWaiterOHOS(const flutter::TaskRunners& task_runners)
    : VsyncWaiter(task_runners) {
  vsyncHandle =
      OH_NativeVSync_Create("flutterSyncName", strlen(flutterSyncName));
}

VsyncWaiterOHOS::~VsyncWaiterOHOS() {
  OH_NativeVSync_Destroy(vsyncHandle);
}

void VsyncWaiterOHOS::AwaitVSync() {
  if (vsyncHandle == nullptr) {
    LOGE("AwaitVSync vsyncHandle is nullptr");
    return;
  }
  auto* weak_this = new std::weak_ptr<VsyncWaiter>(shared_from_this());
  OH_NativeVSync* handle = vsyncHandle;

  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetUITaskRunner(), [weak_this, handle]() {
        int32_t ret = 0;
        if (0 != (ret = OH_NativeVSync_RequestFrame(handle, &OnVsyncFromOHOS,
                                                    weak_this))) {
          FML_DLOG(ERROR) << "AwaitVSync...failed:" << ret;
        }
      });
}

void VsyncWaiterOHOS::OnVsyncFromOHOS(long long timestamp, void* data) {
  int64_t frame_nanos = static_cast<int64_t>(timestamp);
  auto frame_time = fml::TimePoint::FromEpochDelta(
      fml::TimeDelta::FromNanoseconds(frame_nanos));
  auto now = fml::TimePoint::Now();
  if (frame_time > now) {
    frame_time = now;
  }
  auto target_time = frame_time + fml::TimeDelta::FromNanoseconds(
                                      1000000000.0 / g_refresh_rate_);
  auto* weak_this = reinterpret_cast<std::weak_ptr<VsyncWaiter>*>(data);
  ConsumePendingCallback(weak_this, frame_time, target_time);
}

void VsyncWaiterOHOS::ConsumePendingCallback(
    std::weak_ptr<VsyncWaiter>* weak_this,
    fml::TimePoint frame_start_time,
    fml::TimePoint frame_target_time) {
  std::shared_ptr<VsyncWaiter> shared_this = weak_this->lock();
  delete weak_this;

  if (shared_this) {
    shared_this->FireCallback(frame_start_time, frame_target_time);
  }
}

void VsyncWaiterOHOS::OnUpdateRefreshRate(long long refresh_rate) {
  FML_DCHECK(refresh_rate > 0);
  g_refresh_rate_ = static_cast<int>(refresh_rate);
}

}  // namespace flutter
