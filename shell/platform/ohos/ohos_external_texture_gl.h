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

#ifndef OHOS_EXTERNAL_TEXTURE_GL_H
#define OHOS_EXTERNAL_TEXTURE_GL_H
#include <GLES/gl.h>

#include "flutter/common/graphics/texture.h"
#include "napi/platform_view_ohos_napi.h"

// maybe now unused
namespace flutter {

class OHOSExternalTextureGL : public flutter::Texture {
 public:
  explicit OHOSExternalTextureGL(int id);

  ~OHOSExternalTextureGL() override;

  void Paint(PaintContext& context,
             const SkRect& bounds,
             bool freeze,
             const SkSamplingOptions& sampling) override;

  void OnGrContextCreated() override;

  void OnGrContextDestroyed() override;

  void MarkNewFrameAvailable() override;

  void OnTextureUnregistered() override;

 private:
  void Attach(int textureName);

  void Update();

  void Detach();

  void UpdateTransform();

  enum class AttachmentState { uninitialized, attached, detached };

  AttachmentState state_ = AttachmentState::uninitialized;

  bool new_frame_ready_ = false;

  GLuint texture_name_ = 0;

  SkMatrix transform;

  FML_DISALLOW_COPY_AND_ASSIGN(OHOSExternalTextureGL);
};
}  // namespace flutter
#endif