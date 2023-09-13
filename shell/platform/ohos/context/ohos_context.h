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

#ifndef OHOS_CONTEXT_H
#define OHOS_CONTEXT_H

#include "flutter/fml/macros.h"
#include "flutter/fml/task_runner.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {

enum class OHOSRenderingAPI {
  kSoftware,
  kOpenGLES,
};

class OHOSContext {
 public:
  explicit OHOSContext(OHOSRenderingAPI rendering_api);

  virtual ~OHOSContext();

  OHOSRenderingAPI RenderingApi() const;

  virtual bool IsValid() const;

  void SetMainSkiaContext(const sk_sp<GrDirectContext>& main_context);

  sk_sp<GrDirectContext> GetMainSkiaContext() const;

 private:
  const OHOSRenderingAPI rendering_api_;

  // This is the Skia context used for on-screen rendering.
  sk_sp<GrDirectContext> main_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(OHOSContext);
};

}  // namespace flutter
#endif