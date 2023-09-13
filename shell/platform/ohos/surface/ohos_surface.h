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

#ifndef OHOS_SURFACE_H
#define OHOS_SURFACE_H

#include <memory>
#include "flutter/flow/surface.h"
#include "flutter/shell/platform/ohos/context/ohos_context.h"
#include "flutter/shell/platform/ohos/surface/ohos_native_window.h"
#include "third_party/skia/include/core/SkSize.h"

namespace impeller {
class Context;
}  // namespace impeller

namespace flutter {

class OHOSSurface {
 public:
  virtual ~OHOSSurface();
  virtual bool IsValid() const = 0;
  virtual void TeardownOnScreenContext() = 0;

  virtual bool OnScreenSurfaceResize(const SkISize& size) = 0;

  virtual bool ResourceContextMakeCurrent() = 0;

  virtual bool ResourceContextClearCurrent() = 0;

  virtual bool SetNativeWindow(fml::RefPtr<OHOSNativeWindow> window) = 0;

  virtual std::unique_ptr<Surface> CreateSnapshotSurface();

  virtual std::unique_ptr<Surface> CreateGPUSurface(
      GrDirectContext* gr_context = nullptr) = 0;

  virtual std::shared_ptr<impeller::Context> GetImpellerContext();

 protected:
  explicit OHOSSurface(const std::shared_ptr<OHOSContext>& ohos_context);
  std::shared_ptr<OHOSContext> ohos_context_;
};

class OhosSurfaceFactory {
 public:
  OhosSurfaceFactory() = default;

  virtual ~OhosSurfaceFactory() = default;

  virtual std::unique_ptr<OHOSSurface> CreateSurface() = 0;
};
}  // namespace flutter

#endif