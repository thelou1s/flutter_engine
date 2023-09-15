// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_software.h"

#include <memory>
#include "flutter/fml/logging.h"

namespace flutter {

GPUSurfaceSoftware::GPUSurfaceSoftware(GPUSurfaceSoftwareDelegate* delegate,
                                       bool render_to_surface)
    : delegate_(delegate),
      render_to_surface_(render_to_surface),
      weak_factory_(this) {}

GPUSurfaceSoftware::~GPUSurfaceSoftware() = default;

// |Surface|
bool GPUSurfaceSoftware::IsValid() {
  return delegate_ != nullptr;
}

// |Surface|
std::unique_ptr<SurfaceFrame> GPUSurfaceSoftware::AcquireFrame(
    const SkISize& logical_size) {
  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;

  FML_DLOG(INFO) <<"AcquireFrame" ;
  // TODO(38466): Refactor GPU surface APIs take into account the fact that an
  // external view embedder may want to render to the root surface.
  if (!render_to_surface_) {
    return std::make_unique<SurfaceFrame>(
        nullptr, framebuffer_info,
        [](const SurfaceFrame& surface_frame, SkCanvas* canvas) {
          return true;
        },
        logical_size);
  }

  if (!IsValid()) {
    return nullptr;
  }

  const auto size = SkISize::Make(logical_size.width(), logical_size.height());

  sk_sp<SkSurface> backing_store = delegate_->AcquireBackingStore(size);

FML_DLOG(INFO) << "AcquireFrame";
  if (backing_store == nullptr) {
    FML_DLOG(INFO) <<"AcquireFrame ... backing_store is null" ;
    return nullptr;
  }

  if (size != SkISize::Make(backing_store->width(), backing_store->height())) {
    FML_DLOG(INFO) <<"AcquireFrame ... backing_store size not matched" ;
    return nullptr;
  }

  // If the surface has been scaled, we need to apply the inverse scaling to the
  // underlying canvas so that coordinates are mapped to the same spot
  // irrespective of surface scaling.
  SkCanvas* canvas = backing_store->getCanvas();
  canvas->resetMatrix();

FML_DLOG(INFO) << "resetMatrix end";
  SurfaceFrame::SubmitCallback on_submit =
      [self = weak_factory_.GetWeakPtr()](const SurfaceFrame& surface_frame,
                                          SkCanvas* canvas) -> bool {
                                            FML_DLOG(INFO) << "on_submit  start";
    // If the surface itself went away, there is nothing more to do.
    FML_DLOG(INFO) <<"AcquireFrame ... on_submit ..." ;
    if (!self || !self->IsValid() || canvas == nullptr) {
      FML_DLOG(INFO) << "on_submit  return false";
      return false;
    }
    FML_DLOG(INFO) <<"AcquireFrame ... on_submit canvas->flush " ;

    canvas->flush();

    FML_DLOG(INFO) <<"AcquireFrame ... delegate_-->PresentBackingStore" ;
    return self->delegate_->PresentBackingStore(surface_frame.SkiaSurface());
  };

FML_DLOG(INFO) << "return  SurfaceFrame";
  return std::make_unique<SurfaceFrame>(backing_store, framebuffer_info,
                                        on_submit, logical_size);
}

// |Surface|
SkMatrix GPUSurfaceSoftware::GetRootTransformation() const {
  // This backend does not currently support root surface transformations. Just
  // return identity.
  SkMatrix matrix;
  matrix.reset();
  return matrix;
}

// |Surface|
GrDirectContext* GPUSurfaceSoftware::GetContext() {
  // There is no GrContext associated with a software surface.
  return nullptr;
}

}  // namespace flutter
