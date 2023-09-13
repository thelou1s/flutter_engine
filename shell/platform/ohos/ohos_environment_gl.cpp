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

#include "flutter/shell/platform/ohos/ohos_environment_gl.h"

namespace flutter {

OhosEnvironmentGL::OhosEnvironmentGL()
    : display_(EGL_NO_DISPLAY), valid_(false) {
  // Get the display.
  display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);

  if (display_ == EGL_NO_DISPLAY) {
    return;
  }

  // Initialize the display connection.
  if (eglInitialize(display_, nullptr, nullptr) != EGL_TRUE) {
    return;
  }

  valid_ = true;
}

OhosEnvironmentGL::~OhosEnvironmentGL() {
  // Disconnect the display if valid.
  if (display_ != EGL_NO_DISPLAY) {
    eglTerminate(display_);
  }
}

bool OhosEnvironmentGL::IsValid() const {
  return valid_;
}

EGLDisplay OhosEnvironmentGL::Display() const {
  return display_;
}

}  // namespace flutter
