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

#ifndef FLUTTER_SHELL_PLATFORM_OHOS_ENVIRONMENT_GL_H_
#define FLUTTER_SHELL_PLATFORM_OHOS_ENVIRONMENT_GL_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"

#include <EGL/egl.h>

namespace flutter {

class OhosEnvironmentGL : public fml::RefCountedThreadSafe<OhosEnvironmentGL> {
 private:
  // MakeRefCounted
  OhosEnvironmentGL();

  // MakeRefCounted
  ~OhosEnvironmentGL();

 public:
  bool IsValid() const;

  EGLDisplay Display() const;

 private:
  EGLDisplay display_;
  bool valid_;

  FML_FRIEND_MAKE_REF_COUNTED(OhosEnvironmentGL);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(OhosEnvironmentGL);
  FML_DISALLOW_COPY_AND_ASSIGN(OhosEnvironmentGL);
};

}  // namespace flutter

#endif
