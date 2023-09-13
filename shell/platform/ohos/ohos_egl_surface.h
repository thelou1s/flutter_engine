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

#ifndef FLUTTER_SHELL_PLATFORM_OHOS_EGL_SURFACE_H_
#define FLUTTER_SHELL_PLATFORM_OHOS_EGL_SURFACE_H_

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <KHR/khrplatform.h>
#include <optional>

#include "flutter/fml/macros.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/shell/platform/ohos/ohos_environment_gl.h"
#include "third_party/skia/include/core/SkRect.h"

namespace flutter {

//------------------------------------------------------------------------------
/// Holds an `EGLSurface` reference.
///
///
/// This can be used in conjunction to unique_ptr to provide better guarantees
/// about the lifespan of the `EGLSurface` object.
///
class OhosEGLSurfaceDamage;

/// Result of calling MakeCurrent on OhosEGLSurface.
enum class OhosEGLSurfaceMakeCurrentStatus {
  /// Success, the egl context for the surface was already current.
  kSuccessAlreadyCurrent,
  /// Success, the egl context for the surface made current.
  kSuccessMadeCurrent,
  /// Failed to make the egl context for the surface current.
  kFailure,
};

void LogLastEGLError();

class OhosEGLSurface {
 public:
  OhosEGLSurface(EGLSurface surface, EGLDisplay display, EGLContext context);

  ~OhosEGLSurface();

  //----------------------------------------------------------------------------
  /// @return     Whether the current `EGLSurface` reference is valid. That is,
  /// if
  ///             the surface doesn't point to `EGL_NO_SURFACE`.
  ///
  bool IsValid() const;

  //----------------------------------------------------------------------------
  /// @brief      Binds the EGLContext context to the current rendering thread
  ///             and to the draw and read surface.
  ///
  /// @return     Whether the surface was made current.
  ///
  OhosEGLSurfaceMakeCurrentStatus MakeCurrent() const;

  //----------------------------------------------------------------------------
  ///
  /// @return     Whether target surface supports partial repaint.
  ///
  bool SupportsPartialRepaint() const;

  //----------------------------------------------------------------------------
  /// @brief      This is the minimal area that needs to be repainted to get
  ///             correct result.
  ///
  /// With double or triple buffering this buffer content may lag behind
  /// current front buffer and the rect accounts for accumulated damage.
  ///
  /// @return     The area of current surface where it is behind front buffer.
  ///
  std::optional<SkIRect> InitialDamage();

  //----------------------------------------------------------------------------
  /// @brief      Sets the damage region for current surface. Corresponds to
  //              eglSetDamageRegionKHR
  void SetDamageRegion(const std::optional<SkIRect>& buffer_damage);

  //----------------------------------------------------------------------------
  /// @brief      Sets the presentation time for the current surface. This
  //              corresponds to calling eglPresentationTimeOhos when
  //              available.
  bool SetPresentationTime(const fml::TimePoint& presentation_time);

  //----------------------------------------------------------------------------
  /// @brief      This only applies to on-screen surfaces such as those created
  ///             by `OhosContextGL::CreateOnscreenSurface`.
  ///
  /// @return     Whether the EGL surface color buffer was swapped.
  ///
  bool SwapBuffers(const std::optional<SkIRect>& surface_damage);

  //----------------------------------------------------------------------------
  /// @return     The size of an `EGLSurface`.
  ///
  SkISize GetSize() const;

 private:
  /// Returns true if the EGLContext held is current for the display and surface
  bool IsContextCurrent() const;

  const EGLSurface surface_;
  const EGLDisplay display_;
  const EGLContext context_;
  std::unique_ptr<OhosEGLSurfaceDamage> damage_;
  PFNEGLPRESENTATIONTIMEANDROIDPROC presentation_time_proc_;
};

}  // namespace flutter

#endif
