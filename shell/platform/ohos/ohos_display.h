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

#ifndef OHOS_DISPLAY_H
#define OHOS_DISPLAY_H

#include <cstdint>

#include "flutter/fml/macros.h"
#include "flutter/shell/common/display.h"
#include "flutter/shell/platform/ohos/napi/platform_view_ohos_napi.h"
namespace flutter {

class OHOSDisplay : public Display {
 public:
  explicit OHOSDisplay(std::shared_ptr<PlatformViewOHOSNapi> napi_facade_);
  ~OHOSDisplay() = default;

  double GetRefreshRate() const override;

 private:
  std::shared_ptr<PlatformViewOHOSNapi> napi_facade_;
  FML_DISALLOW_COPY_AND_ASSIGN(OHOSDisplay);
};
}  // namespace flutter
#endif