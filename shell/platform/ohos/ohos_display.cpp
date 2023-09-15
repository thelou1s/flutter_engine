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

#include "flutter/shell/platform/ohos/ohos_display.h"

namespace flutter {

const double defaultFPS = 60;

OHOSDisplay::OHOSDisplay(std::shared_ptr<PlatformViewOHOSNapi> napi_facade)
    : Display(60), napi_facade_(std::move(napi_facade)) {}

double OHOSDisplay::GetRefreshRate() const {
  return defaultFPS;
}

}  // namespace flutter