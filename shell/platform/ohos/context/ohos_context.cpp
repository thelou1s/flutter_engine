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

#include "flutter/shell/platform/ohos/context/ohos_context.h"

namespace flutter {

OHOSContext::OHOSContext(OHOSRenderingAPI rendering_api)
    : rendering_api_(rendering_api) {}

OHOSContext::~OHOSContext() {
  if (main_context_) {
    main_context_->releaseResourcesAndAbandonContext();
  }
}

OHOSRenderingAPI OHOSContext::RenderingApi() const {
  return rendering_api_;
}

bool OHOSContext::IsValid() const {
  return true;
}

void OHOSContext::SetMainSkiaContext(
    const sk_sp<GrDirectContext>& main_context) {
  main_context_ = main_context;
}

sk_sp<GrDirectContext> OHOSContext::GetMainSkiaContext() const {
  return main_context_;
}

}  // namespace flutter