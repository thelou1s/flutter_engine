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

#ifndef OHOS_SURFACE_SOFTWARE_H
#define OHOS_SURFACE_SOFTWARE_H

#include "flutter/fml/macros.h"
#include "flutter/shell/gpu/gpu_surface_software.h"
#include "flutter/shell/platform/ohos/surface/ohos_surface.h"

#include "flutter/shell/platform/ohos/surface/ohos_native_window.h"

namespace flutter {

class OHOSSurfaceSoftware final : public OHOSSurface,
                                  public GPUSurfaceSoftwareDelegate {
 public:
  OHOSSurfaceSoftware(const std::shared_ptr<OHOSContext>& ohos_context);
  ~OHOSSurfaceSoftware() override;

  bool IsValid() const override;

  // |OHOSSurface|
  bool ResourceContextMakeCurrent() override;

  // |OHOSSurface|
  bool ResourceContextClearCurrent() override;

  // |OHOSSurface|
  std::unique_ptr<Surface> CreateGPUSurface(
      GrDirectContext* gr_context) override;

  // |OHOSSurface|
  void TeardownOnScreenContext() override;

  // |OHOSSurface|
  bool OnScreenSurfaceResize(const SkISize& size) override;

  // |OHOSSurface|
  bool SetNativeWindow(fml::RefPtr<OHOSNativeWindow> window) override;

  // |GPUSurfaceSoftwareDelegate|
  sk_sp<SkSurface> AcquireBackingStore(const SkISize& size) override;

  // |GPUSurfaceSoftwareDelegate|
  bool PresentBackingStore(sk_sp<SkSurface> backing_store) override;

 private:
  sk_sp<SkSurface> sk_surface_;
  fml::RefPtr<OHOSNativeWindow> native_window_;
  SkColorType target_color_type_;
  SkAlphaType target_alpha_type_;

  FML_DISALLOW_COPY_AND_ASSIGN(OHOSSurfaceSoftware);
};
}  // namespace flutter
#endif