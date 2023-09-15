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

#ifndef OHOS_SURFACE_GL_SKIA_H
#define OHOS_SURFACE_GL_SKIA_H

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/gpu/gpu_surface_gl_skia.h"
#include "flutter/shell/platform/ohos/napi/platform_view_ohos_napi.h"
#include "flutter/shell/platform/ohos/ohos_context_gl_skia.h"
#include "flutter/shell/platform/ohos/ohos_environment_gl.h"
#include "flutter/shell/platform/ohos/surface/ohos_surface.h"

namespace flutter {

class OhosSurfaceGLSkia final : public GPUSurfaceGLDelegate,
                                public OHOSSurface {
 public:
  OhosSurfaceGLSkia(const std::shared_ptr<OHOSContext>& ohos_context);

  ~OhosSurfaceGLSkia() override;

  // |OhosSurface|
  bool IsValid() const override;

  // |OhosSurface|
  std::unique_ptr<Surface> CreateGPUSurface(
      GrDirectContext* gr_context) override;

  // |OhosSurface|
  void TeardownOnScreenContext() override;

  // |OhosSurface|
  bool OnScreenSurfaceResize(const SkISize& size) override;

  // |OhosSurface|
  bool ResourceContextMakeCurrent() override;

  // |OhosSurface|
  bool ResourceContextClearCurrent() override;

  // |OhosSurface|
  bool SetNativeWindow(fml::RefPtr<OHOSNativeWindow> window) override;

  // |OhosSurface|
  virtual std::unique_ptr<Surface> CreateSnapshotSurface() override;

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

  // Obtain a raw pointer to the on-screen OhosEGLSurface.
  //
  // This method is intended for use in tests. Callers must not
  // delete the returned pointer.
  OhosEGLSurface* GetOnscreenSurface() const { return onscreen_surface_.get(); }

 private:
  fml::RefPtr<OHOSNativeWindow> native_window_;
  std::unique_ptr<OhosEGLSurface> onscreen_surface_;
  std::unique_ptr<OhosEGLSurface> offscreen_surface_;

  //----------------------------------------------------------------------------
  /// @brief      Takes the super class OhosSurface's OhosContext and
  ///             return a raw pointer to an OhosContextGL.
  ///
  OhosContextGLSkia* GLContextPtr() const;

  FML_DISALLOW_COPY_AND_ASSIGN(OhosSurfaceGLSkia);
};

}  // namespace flutter

#endif
