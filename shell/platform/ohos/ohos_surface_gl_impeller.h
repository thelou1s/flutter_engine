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

#ifndef OHOS_SURFACE_GL_IMPELLER_H
#define OHOS_SURFACE_GL_IMPELLER_H

#include "flutter/fml/macros.h"
#include "flutter/impeller/renderer/context.h"
#include "flutter/impeller/toolkit/egl/display.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#include "surface/ohos_native_window.h"
#include "surface/ohos_surface.h"

namespace flutter {

class OHOSSurfaceGLImpeller final : public GPUSurfaceGLDelegate,
                                    public OHOSSurface {
 public:
  OHOSSurfaceGLImpeller(const std::shared_ptr<OHOSContext>& ohos_context);

  ~OHOSSurfaceGLImpeller() override;

  // OHOSSurface
  bool IsValid() const override;

  // OHOSSurface
  std::unique_ptr<Surface> CreateGPUSurface(
      GrDirectContext* gr_context) override;

  // OHOSSurface
  void TeardownOnScreenContext() override;

  // OHOSSurface
  bool OnScreenSurfaceResize(const SkISize& size) override;

  // OHOSSurface
  bool ResourceContextMakeCurrent() override;

  // OHOSSurface
  bool ResourceContextClearCurrent() override;

  // OHOSSurface
  bool SetNativeWindow(fml::RefPtr<OHOSNativeWindow> window) override;

  // OHOSSurface
  std::unique_ptr<Surface> CreateSnapshotSurface() override;

  // OHOSSurface
  std::shared_ptr<impeller::Context> GetImpellerContext() override;

  // |GPUSurfaceGLDelegate|
  std::unique_ptr<GLContextResult> GLContextMakeCurrent() override;

  // |GPUSurfaceGLDelegate|
  bool GLContextClearCurrent() override;

  // |GPUSurfaceGLDelegate|
  SurfaceFrame::FramebufferInfo GLContextFramebufferInfo() const override;

  // |GPUSurfaceGLDelegate|
  void GLContextSetDamageRegion(const std::optional<SkIRect>& region) override;

  // |GPUSurfaceGLDelegate|
  bool GLContextPresent(const GLPresentInfo& present_info) override;

  // |GPUSurfaceGLDelegate|
  GLFBOInfo GLContextFBO(GLFrameInfo frame_info) const override;

  // |GPUSurfaceGLDelegate|
  sk_sp<const GrGLInterface> GetGLInterface() const override;

 private:
  class ReactorWorker;
  std::shared_ptr<ReactorWorker> reactor_worker_;
  std::unique_ptr<impeller::egl::Display> display_;
  std::unique_ptr<impeller::egl::Config> onscreen_config_;
  std::unique_ptr<impeller::egl::Config> offscreen_config_;
  std::unique_ptr<impeller::egl::Surface> onscreen_surface_;
  std::unique_ptr<impeller::egl::Surface> offscreen_surface_;
  std::unique_ptr<impeller::egl::Context> onscreen_context_;
  std::unique_ptr<impeller::egl::Context> offscreen_context_;
  std::shared_ptr<impeller::Context> impeller_context_;
  fml::RefPtr<OHOSNativeWindow> native_window_;

  bool is_valid_ = false;

  bool OnGLContextMakeCurrent();

  bool RecreateOnscreenSurfaceAndMakeOnscreenContextCurrent();

  FML_DISALLOW_COPY_AND_ASSIGN(OHOSSurfaceGLImpeller);
};

}  // namespace flutter
#endif