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

#include "ohos_external_texture_gl.h"
#include <GLES/glext.h>

#include <utility>

#include "third_party/skia/include/core/SkAlphaType.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {

OHOSExternalTextureGL::OHOSExternalTextureGL(int id)
    : Texture(id), transform(SkMatrix::I()) {}

OHOSExternalTextureGL::~OHOSExternalTextureGL() {
  if (state_ == AttachmentState::attached) {
    // glDeleteTextures(1, &texture_name_);
  }
}

void OHOSExternalTextureGL::Paint(PaintContext& context,
                                  const SkRect& bounds,
                                  bool freeze,
                                  const SkSamplingOptions& sampling) {
  if (state_ == AttachmentState::detached) {
    return;
  }
  if (state_ == AttachmentState::uninitialized) {
    // glGenTextures(1, &texture_name_);
    Attach(static_cast<int>(texture_name_));
    state_ = AttachmentState::attached;
  }
  if (!freeze && new_frame_ready_) {
    Update();
    new_frame_ready_ = false;
  }
  GrGLTextureInfo textureInfo = {0, texture_name_, GL_RGBA8_OES};
  GrBackendTexture backendTexture(1, 1, GrMipMapped::kNo, textureInfo);
  sk_sp<SkImage> image = SkImage::MakeFromTexture(
      context.gr_context, backendTexture, kTopLeft_GrSurfaceOrigin,
      kRGBA_8888_SkColorType, kPremul_SkAlphaType, nullptr);
  if (image) {
    SkAutoCanvasRestore autoRestore(context.canvas, true);

    // The incoming texture is vertically flipped, so we flip it
    // back. OpenGL's coordinate system has Positive Y equivalent to up, while
    // Skia's coordinate system has Negative Y equvalent to up.
    context.canvas->translate(bounds.x(), bounds.y() + bounds.height());
    context.canvas->scale(bounds.width(), -bounds.height());

    if (!transform.isIdentity()) {
      sk_sp<SkShader> shader = image->makeShader(
          SkTileMode::kRepeat, SkTileMode::kRepeat, sampling, transform);

      SkPaint paintWithShader;
      if (context.sk_paint) {
        paintWithShader = *context.sk_paint;
      }
      paintWithShader.setShader(shader);
      context.canvas->drawRect(SkRect::MakeWH(1, 1), paintWithShader);
    } else {
      context.canvas->drawImage(image, 0, 0, sampling, context.sk_paint);
    }
  }
}

void OHOSExternalTextureGL::OnGrContextCreated() {
  state_ = AttachmentState::uninitialized;
}

void OHOSExternalTextureGL::OnGrContextDestroyed() {
  if (state_ == AttachmentState::attached) {
    Detach();
    // glDeleteTextures(1, &texture_name_);
  }
  state_ = AttachmentState::detached;
}

void OHOSExternalTextureGL::MarkNewFrameAvailable() {
  new_frame_ready_ = true;
}

void OHOSExternalTextureGL::OnTextureUnregistered() {
  // do nothing
}

void OHOSExternalTextureGL::Attach(int textureName) {
  // do nothing
}

void OHOSExternalTextureGL::Update() {
  UpdateTransform();
}

void OHOSExternalTextureGL::Detach() {
  // do nothing
}

void OHOSExternalTextureGL::UpdateTransform() {
  SkMatrix inverted;
  if (!transform.invert(&inverted)) {
    FML_LOG(FATAL) << "Invalid SurfaceTexture transformation matrix";
  }
  transform = inverted;
}
}  // namespace flutter