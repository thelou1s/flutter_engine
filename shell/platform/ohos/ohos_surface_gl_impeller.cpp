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

#include "ohos_surface_gl_impeller.h"

#include "flutter/fml/logging.h"
#include "flutter/impeller/entity/gles/entity_shaders_gles.h"
#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#include "flutter/impeller/renderer/backend/gles/proc_table_gles.h"
#include "flutter/impeller/toolkit/egl/context.h"
#include "flutter/impeller/toolkit/egl/surface.h"
#include "flutter/shell/gpu/gpu_surface_gl_impeller.h"

namespace flutter {

class OHOSSurfaceGLImpeller::ReactorWorker final
    : public impeller::ReactorGLES::Worker {
 public:
  ReactorWorker() = default;

  // |impeller::ReactorGLES::Worker|
  ~ReactorWorker() override = default;

  // |impeller::ReactorGLES::Worker|
  bool CanReactorReactOnCurrentThreadNow(
      const impeller::ReactorGLES& reactor) const override {
    impeller::ReaderLock lock(mutex_);
    auto found = reactions_allowed_.find(std::this_thread::get_id());
    if (found == reactions_allowed_.end()) {
      return false;
    }
    return found->second;
  }

  void SetReactionsAllowedOnCurrentThread(bool allowed) {
    impeller::WriterLock lock(mutex_);
    reactions_allowed_[std::this_thread::get_id()] = allowed;
  }

 private:
  mutable impeller::RWMutex mutex_;
  std::map<std::thread::id, bool> reactions_allowed_ IPLR_GUARDED_BY(mutex_);

  FML_DISALLOW_COPY_AND_ASSIGN(ReactorWorker);
};

// for init use
static std::shared_ptr<impeller::Context> CreateImpellerContext(
    const std::shared_ptr<impeller::ReactorGLES::Worker>& worker) {
  auto proc_table = std::make_unique<impeller::ProcTableGLES>(
      impeller::egl::CreateProcAddressResolver());

  if (!proc_table->IsValid()) {
    FML_LOG(ERROR) << "Could not create OpenGL proc table.";
    return nullptr;
  }

  std::vector<std::shared_ptr<fml::Mapping>> shader_mappings = {
      std::make_shared<fml::NonOwnedMapping>(
          impeller_entity_shaders_gles_data,
          impeller_entity_shaders_gles_length),
  };

  auto context =
      impeller::ContextGLES::Create(std::move(proc_table), shader_mappings);
  if (!context) {
    FML_LOG(ERROR) << "Could not create OpenGLES Impeller Context.";
    return nullptr;
  }

  if (!context->AddReactorWorker(worker).has_value()) {
    FML_LOG(ERROR) << "Could not add reactor worker.";
    return nullptr;
  }
  FML_LOG(ERROR) << "Using the Impeller rendering backend.";

  return context;
}

OHOSSurfaceGLImpeller::OHOSSurfaceGLImpeller(
    const std::shared_ptr<OHOSContext>& ohos_context)
    : OHOSSurface(ohos_context),
      reactor_worker_(std::make_shared<ReactorWorker>()) {
  auto display = std::make_unique<impeller::egl::Display>();
  if (!display->IsValid()) {
    FML_DLOG(ERROR) << "Could not create EGL display.";
    return;
  }

  impeller::egl::ConfigDescriptor desc;
  desc.api = impeller::egl::API::kOpenGLES2;
  desc.color_format = impeller::egl::ColorFormat::kRGBA8888;
  desc.depth_bits = impeller::egl::DepthBits::kZero;
  desc.stencil_bits = impeller::egl::StencilBits::kEight;
  desc.samples = impeller::egl::Samples::kFour;

  desc.surface_type = impeller::egl::SurfaceType::kWindow;
  auto onscreen_config = display->ChooseConfig(desc);
  if (!onscreen_config) {
    FML_DLOG(ERROR) << "Could not choose onscreen config.";
    return;
  }

  desc.surface_type = impeller::egl::SurfaceType::kPBuffer;
  auto offscreen_config = display->ChooseConfig(desc);
  if (!offscreen_config) {
    FML_DLOG(ERROR) << "Could not choose offscreen config.";
    return;
  }

  auto onscreen_context = display->CreateContext(*onscreen_config, nullptr);
  if (!onscreen_context) {
    FML_DLOG(ERROR) << "Could not create onscreen context.";
    return;
  }

  auto offscreen_context =
      display->CreateContext(*offscreen_config, onscreen_context.get());
  if (!offscreen_context) {
    FML_DLOG(ERROR) << "Could not create offscreen context.";
    return;
  }

  auto offscreen_surface =
      display->CreatePixelBufferSurface(*offscreen_config, 1u, 1u);
  if (!offscreen_surface) {
    FML_DLOG(ERROR) << "Could not create offscreen surface.";
    return;
  }

  if (!offscreen_context->MakeCurrent(*offscreen_surface)) {
    FML_DLOG(ERROR) << "Could not make offscreen context current.";
    return;
  }

  auto impeller_context = CreateImpellerContext(reactor_worker_);

  if (!impeller_context) {
    FML_DLOG(ERROR) << "Could not create Impeller context.";
    return;
  }

  if (!offscreen_context->ClearCurrent()) {
    FML_DLOG(ERROR) << "Could not clear offscreen context.";
    return;
  }

  // Setup context listeners.
  impeller::egl::Context::LifecycleListener listener =
      [worker =
           reactor_worker_](impeller::egl ::Context::LifecycleEvent event) {
        switch (event) {
          case impeller::egl::Context::LifecycleEvent::kDidMakeCurrent:
            worker->SetReactionsAllowedOnCurrentThread(true);
            break;
          case impeller::egl::Context::LifecycleEvent::kWillClearCurrent:
            worker->SetReactionsAllowedOnCurrentThread(false);
            break;
        }
      };
  if (!onscreen_context->AddLifecycleListener(listener).has_value() ||
      !offscreen_context->AddLifecycleListener(listener).has_value()) {
    FML_DLOG(ERROR) << "Could not add lifecycle listeners";
  }

  display_ = std::move(display);
  onscreen_config_ = std::move(onscreen_config);
  offscreen_config_ = std::move(offscreen_config);
  offscreen_surface_ = std::move(offscreen_surface);
  onscreen_context_ = std::move(onscreen_context);
  offscreen_context_ = std::move(offscreen_context);
  impeller_context_ = std::move(impeller_context);

  // The onscreen surface will be acquired once the native window is set.

  is_valid_ = true;
}

OHOSSurfaceGLImpeller::~OHOSSurfaceGLImpeller() = default;

// OHOSSurface
bool OHOSSurfaceGLImpeller::IsValid() const {
  return is_valid_;
}

// OHOSSurface
std::unique_ptr<Surface> OHOSSurfaceGLImpeller::CreateGPUSurface(
    GrDirectContext* gr_context) {
  auto surface =
      std::make_unique<GPUSurfaceGLImpeller>(this,              // delegate
                                             impeller_context_  // context
      );
  if (!surface->IsValid()) {
    return nullptr;
  }
  return surface;
}

// OHOSSurface
void OHOSSurfaceGLImpeller::TeardownOnScreenContext() {
  GLContextClearCurrent();
  onscreen_surface_.reset();
}

// OHOSSurface
bool OHOSSurfaceGLImpeller::OnScreenSurfaceResize(const SkISize& size) {
  // unused function
  return RecreateOnscreenSurfaceAndMakeOnscreenContextCurrent();
}

// OHOSSurface
bool OHOSSurfaceGLImpeller::ResourceContextMakeCurrent() {
  if (!offscreen_context_ || !offscreen_surface_) {
    return false;
  }

  return offscreen_context_->MakeCurrent(*offscreen_surface_);
}

// OHOSSurface
bool OHOSSurfaceGLImpeller::ResourceContextClearCurrent() {
  if (!offscreen_context_ || !offscreen_surface_) {
    return false;
  }

  return offscreen_context_->ClearCurrent();
}

// OHOSSurface
bool OHOSSurfaceGLImpeller::SetNativeWindow(
    fml::RefPtr<OHOSNativeWindow> window) {
  native_window_ = std::move(window);
  return RecreateOnscreenSurfaceAndMakeOnscreenContextCurrent();
}

// OHOSSurface
std::unique_ptr<Surface> OHOSSurfaceGLImpeller::CreateSnapshotSurface() {
  // unreachable func
  FML_UNREACHABLE();

  return nullptr;
}

// OHOSSurface
std::shared_ptr<impeller::Context> OHOSSurfaceGLImpeller::GetImpellerContext() {
  return impeller_context_;
}

// |GPUSurfaceGLDelegate|
std::unique_ptr<GLContextResult> OHOSSurfaceGLImpeller::GLContextMakeCurrent() {
  return std::make_unique<GLContextDefaultResult>(OnGLContextMakeCurrent());
}

// |GPUSurfaceGLDelegate|
bool OHOSSurfaceGLImpeller::GLContextClearCurrent() {
  if (!onscreen_surface_ || !onscreen_context_) {
    return false;
  }

  return onscreen_context_->ClearCurrent();
}

// |GPUSurfaceGLDelegate|
SurfaceFrame::FramebufferInfo OHOSSurfaceGLImpeller::GLContextFramebufferInfo()
    const {
  auto info = SurfaceFrame::FramebufferInfo{};
  info.supports_readback = true;
  info.supports_partial_repaint = false;
  return info;
}

// |GPUSurfaceGLDelegate|
void OHOSSurfaceGLImpeller::GLContextSetDamageRegion(
    const std::optional<SkIRect>& region) {
  // 不支持
}

// |GPUSurfaceGLDelegate|
bool OHOSSurfaceGLImpeller::GLContextPresent(
    const GLPresentInfo& present_info) {
  if (!onscreen_surface_) {
    return false;
  }

  return onscreen_surface_->Present();
}

// |GPUSurfaceGLDelegate|
GLFBOInfo OHOSSurfaceGLImpeller::GLContextFBO(GLFrameInfo frame_info) const {
  // FBO0 is the default window bound framebuffer in EGL environments.
  return GLFBOInfo{
      .fbo_id = 0,
  };
}

// |GPUSurfaceGLDelegate|
sk_sp<const GrGLInterface> OHOSSurfaceGLImpeller::GetGLInterface() const {
  return nullptr;
}

bool OHOSSurfaceGLImpeller::OnGLContextMakeCurrent() {
  if (!onscreen_surface_ || !onscreen_context_) {
    return false;
  }

  return onscreen_context_->MakeCurrent(*onscreen_surface_);
}

bool OHOSSurfaceGLImpeller::
    RecreateOnscreenSurfaceAndMakeOnscreenContextCurrent() {
  GLContextClearCurrent();
  if (!native_window_) {
    return false;
  }
  onscreen_surface_.reset();
  auto onscreen_surface = display_->CreateWindowSurface(
      *onscreen_config_, (EGLNativeWindowType)native_window_->Gethandle());
  if (!onscreen_surface) {
    FML_DLOG(ERROR) << "Could not create onscreen surface.";
    return false;
  }
  onscreen_surface_ = std::move(onscreen_surface);
  return OnGLContextMakeCurrent();
}

}  // namespace flutter

// todo //flutter/impeller/toolkit/egl/display.cc
// 中的该方法一直链接不上，其他方法都可以，无奈之举
namespace impeller {
namespace egl {
std::unique_ptr<Surface> Display::CreateWindowSurface(
    const Config& config,
    EGLNativeWindowType window) {
  const EGLint attribs[] = {EGL_NONE};
  auto surface = ::eglCreateWindowSurface(display_,            // display
                                          config.GetHandle(),  // config
                                          window,              // window
                                          attribs              // attrib_list
  );
  if (surface == EGL_NO_SURFACE) {
    IMPELLER_LOG_EGL_ERROR;
    return nullptr;
  }
  return std::make_unique<Surface>(display_, surface);
}

}  // namespace egl
}  // namespace impeller
