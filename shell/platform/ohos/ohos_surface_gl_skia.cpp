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

#include "flutter/shell/platform/ohos/ohos_surface_gl_skia.h"

#include <GLES2/gl2.h>

#include "flutter/fml/logging.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/shell/platform/ohos/ohos_egl_surface.h"
#include "flutter/shell/platform/ohos/ohos_shell_holder.h"

namespace flutter {

namespace {
// GL renderer string prefix used by the Ohos emulator GLES implementation.
constexpr char kEmulatorRendererPrefix[] = "Mali-G78";
}  // anonymous namespace

OhosSurfaceGLSkia::OhosSurfaceGLSkia(
    const std::shared_ptr<OHOSContext>& ohos_context)
    : OHOSSurface(ohos_context),
      native_window_(nullptr),
      onscreen_surface_(nullptr),
      offscreen_surface_(nullptr) {
  // Acquire the offscreen surface.
  FML_LOG(INFO) << "OhosSurfaceGLSkia constructor";
  offscreen_surface_ = GLContextPtr()->CreateOffscreenSurface();
  if (!offscreen_surface_->IsValid()) {
    FML_LOG(ERROR) << "OhosSurfaceGLSkia offscreen_surface_->IsValid() FAIL";
    offscreen_surface_ = nullptr;
  }
  FML_LOG(INFO) << "OhosSurfaceGLSkia constructor end";
}

OhosSurfaceGLSkia::~OhosSurfaceGLSkia() {
  eglMakeCurrent(eglGetCurrentDisplay(), EGL_NO_SURFACE, EGL_NO_SURFACE,
                 EGL_NO_CONTEXT);
}

void OhosSurfaceGLSkia::TeardownOnScreenContext() {
  // When the onscreen surface is destroyed, the context and the surface
  // instance should be deleted. Issue:
  // https://github.com/flutter/flutter/issues/64414
  GLContextPtr()->ClearCurrent();
  onscreen_surface_ = nullptr;
}

bool OhosSurfaceGLSkia::IsValid() const {
  return offscreen_surface_ && GLContextPtr()->IsValid();
}

std::unique_ptr<Surface> OhosSurfaceGLSkia::CreateGPUSurface(
    GrDirectContext* gr_context) {
  if (gr_context) {
    FML_LOG(INFO) << "gr_context NO null";
    return std::make_unique<GPUSurfaceGLSkia>(sk_ref_sp(gr_context), this,
                                              true);
  } else {
    sk_sp<GrDirectContext> main_skia_context =
        GLContextPtr()->GetMainSkiaContext();
    if (!main_skia_context) {
      main_skia_context = GPUSurfaceGLSkia::MakeGLContext(this);
      FML_LOG(ERROR) << "Could not make main_skia_context";
      GLContextPtr()->SetMainSkiaContext(main_skia_context);
    }
    return std::make_unique<GPUSurfaceGLSkia>(main_skia_context, this, true);
  }
}

bool OhosSurfaceGLSkia::OnScreenSurfaceResize(const SkISize& size) {
  FML_DCHECK(IsValid());
  FML_DCHECK(onscreen_surface_);
  FML_DCHECK(native_window_);

  if (size == onscreen_surface_->GetSize()) {
    return true;
  }

  GLContextPtr()->ClearCurrent();

  // Ensure the destructor is called since it destroys the `EGLSurface` before
  // creating a new onscreen surface.
  onscreen_surface_ = nullptr;
  onscreen_surface_ = GLContextPtr()->CreateOnscreenSurface(native_window_);
  if (!onscreen_surface_->IsValid()) {
    FML_LOG(ERROR) << "Unable to create EGL window surface on resize.";
    return false;
  }
  onscreen_surface_->MakeCurrent();
  return true;
}

bool OhosSurfaceGLSkia::ResourceContextMakeCurrent() {
  FML_DCHECK(IsValid());
  auto status = offscreen_surface_->MakeCurrent();
  return status != OhosEGLSurfaceMakeCurrentStatus::kFailure;
}

bool OhosSurfaceGLSkia::ResourceContextClearCurrent() {
  // FML_DCHECK(IsValid());
  // EGLBoolean result = eglMakeCurrent(eglGetCurrentDisplay(), EGL_NO_SURFACE,
  //                                    EGL_NO_SURFACE, EGL_NO_CONTEXT);
  // return result == EGL_TRUE;
  return true;
}

bool OhosSurfaceGLSkia::SetNativeWindow(fml::RefPtr<OHOSNativeWindow> window) {
  FML_DCHECK(IsValid());
  FML_DCHECK(window);
  native_window_ = window;
  // Ensure the destructor is called since it destroys the `EGLSurface` before
  // creating a new onscreen surface.
  onscreen_surface_ = nullptr;
  // Create the onscreen surface.
  onscreen_surface_ = GLContextPtr()->CreateOnscreenSurface(window);
  if (!onscreen_surface_->IsValid()) {
    return false;
  }
  return true;
}

std::unique_ptr<GLContextResult> OhosSurfaceGLSkia::GLContextMakeCurrent() {
  FML_DCHECK(IsValid());
  FML_DCHECK(onscreen_surface_);
  auto status = onscreen_surface_->MakeCurrent();
  auto default_context_result = std::make_unique<GLContextDefaultResult>(
      status != OhosEGLSurfaceMakeCurrentStatus::kFailure);
  return std::move(default_context_result);
}

bool OhosSurfaceGLSkia::GLContextClearCurrent() {
  FML_DCHECK(IsValid());
  return GLContextPtr()->ClearCurrent();
}

SurfaceFrame::FramebufferInfo OhosSurfaceGLSkia::GLContextFramebufferInfo()
    const {
  FML_DCHECK(IsValid());
  SurfaceFrame::FramebufferInfo res;
  res.supports_readback = true;
  res.supports_partial_repaint = onscreen_surface_->SupportsPartialRepaint();
  res.existing_damage = onscreen_surface_->InitialDamage();
  // Some devices (Pixel2 XL) needs EGL_KHR_partial_update rect aligned to 4,
  // otherwise there are glitches
  // (https://github.com/flutter/flutter/issues/97482#)
  // Larger alignment might also be beneficial for tile base renderers.
  res.horizontal_clip_alignment = 32;
  res.vertical_clip_alignment = 32;

  return res;
}

void OhosSurfaceGLSkia::GLContextSetDamageRegion(
    const std::optional<SkIRect>& region) {
  FML_DCHECK(IsValid());
  onscreen_surface_->SetDamageRegion(region);
}

bool OhosSurfaceGLSkia::GLContextPresent(const GLPresentInfo& present_info) {
  FML_DCHECK(IsValid());
  FML_DCHECK(onscreen_surface_);
  if (present_info.presentation_time) {
    onscreen_surface_->SetPresentationTime(*present_info.presentation_time);
  }
  return onscreen_surface_->SwapBuffers(present_info.frame_damage);
}

GLFBOInfo OhosSurfaceGLSkia::GLContextFBO(GLFrameInfo frame_info) const {
  FML_DCHECK(IsValid());
  // The default window bound framebuffer on Ohos.
  return GLFBOInfo{
      .fbo_id = 0,
      .partial_repaint_enabled = onscreen_surface_->SupportsPartialRepaint(),
      .existing_damage = onscreen_surface_->InitialDamage(),
  };
}

// |GPUSurfaceGLDelegate|
sk_sp<const GrGLInterface> OhosSurfaceGLSkia::GetGLInterface() const {
  // This is a workaround for a bug in the Ohos emulator EGL/GLES
  // implementation.  Some versions of the emulator will not update the
  // GL version string when the process switches to a new EGL context
  // unless the EGL context is being made current for the first time.
  // The inaccurate version string will be rejected by Skia when it
  // tries to build the GrGLInterface.  Flutter can work around this
  // by creating a new context, making it current to force an update
  // of the version, and then reverting to the previous context.
  const char* gl_renderer =
      reinterpret_cast<const char*>(glGetString(GL_RENDERER));

  FML_DLOG(INFO) << "OhosSurfaceGLSkia::GetGLInterface 1";
  if (gl_renderer && strncmp(gl_renderer, kEmulatorRendererPrefix,
                             strlen(kEmulatorRendererPrefix)) == 0) {
    FML_DLOG(INFO) << "OhosSurfaceGLSkia::GetGLInterface 2";
    EGLContext new_context = GLContextPtr()->CreateNewContext();
    if (new_context != EGL_NO_CONTEXT) {
      FML_DLOG(INFO) << "OhosSurfaceGLSkia::GetGLInterface 3";
      EGLContext old_context = eglGetCurrentContext();
      EGLDisplay display = eglGetCurrentDisplay();
      EGLSurface draw_surface = eglGetCurrentSurface(EGL_DRAW);
      EGLSurface read_surface = eglGetCurrentSurface(EGL_READ);
      [[maybe_unused]] EGLBoolean result =
          eglMakeCurrent(display, draw_surface, read_surface, new_context);
      FML_DCHECK(result == EGL_TRUE);
      result = eglMakeCurrent(display, draw_surface, read_surface, old_context);
      FML_DCHECK(result == EGL_TRUE);
      result = eglDestroyContext(display, new_context);
      FML_DCHECK(result == EGL_TRUE);
    }
  }

  FML_DLOG(INFO) << "OhosSurfaceGLSkia::GetGLInterface 4";
  return GPUSurfaceGLDelegate::GetGLInterface();
}

OhosContextGLSkia* OhosSurfaceGLSkia::GLContextPtr() const {
  return reinterpret_cast<OhosContextGLSkia*>(ohos_context_.get());
}

std::unique_ptr<Surface> OhosSurfaceGLSkia::CreateSnapshotSurface() {
  if (!onscreen_surface_ || !onscreen_surface_->IsValid()) {
    onscreen_surface_ = GLContextPtr()->CreatePbufferSurface();
  }
  sk_sp<GrDirectContext> main_skia_context =
      GLContextPtr()->GetMainSkiaContext();
  if (!main_skia_context) {
    main_skia_context = GPUSurfaceGLSkia::MakeGLContext(this);
    GLContextPtr()->SetMainSkiaContext(main_skia_context);
  }

  return std::make_unique<GPUSurfaceGLSkia>(main_skia_context, this, true);
}

}  // namespace flutter
