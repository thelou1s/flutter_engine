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

#include "flutter/shell/platform/ohos/ohos_surface_software.h"
#include <native_window/buffer_handle.h>
#include <sys/mman.h>
#include "flutter/fml/logging.h"
#include "napi_common.h"
#include "third_party/skia/include/core/SkImage.h"
#include "types.h"

namespace flutter {

bool GetSkColorType(int32_t buffer_format,
                    SkColorType* color_type,
                    SkAlphaType* alpha_type) {
  switch (buffer_format) {
    case PIXEL_FMT_RGBA_8888:  // PIXEL_FMT_RGBA_8888
      *color_type = kRGBA_8888_SkColorType;
      *alpha_type = kPremul_SkAlphaType;
      return true;
    default:
      return false;
  }
}

OHOSSurfaceSoftware::OHOSSurfaceSoftware(
    const std::shared_ptr<OHOSContext>& ohos_context)
    : OHOSSurface(ohos_context) {
  GetSkColorType(12, &target_color_type_, &target_alpha_type_);
}

OHOSSurfaceSoftware::~OHOSSurfaceSoftware() {}

bool OHOSSurfaceSoftware::IsValid() const {
  return true;
}

// |OHOSSurface|
bool OHOSSurfaceSoftware::ResourceContextMakeCurrent() {
  return false;
}

// |OHOSSurface|
bool OHOSSurfaceSoftware::ResourceContextClearCurrent() {
  return false;
}

// |OHOSSurface|
std::unique_ptr<Surface> OHOSSurfaceSoftware::CreateGPUSurface(
    GrDirectContext* gr_context) {
  LOGD("CreateGPUSurface start");
  if (!IsValid()) {
    return nullptr;
  }

  FML_DLOG(INFO) << "CreateGPUSurface";

  auto surface =
      std::make_unique<GPUSurfaceSoftware>(this, true /* render to surface */);

  if (!surface->IsValid()) {
    FML_DLOG(INFO) << "CreateGPUSurface failed.";
    return nullptr;
  }
  LOGD("CreateGPUSurface end");
  return surface;
}

// |OHOSSurface|
void OHOSSurfaceSoftware::TeardownOnScreenContext() {
  FML_DLOG(INFO) << "TeardownOnScreenContext";
}

// |OHOSSurface|
bool OHOSSurfaceSoftware::OnScreenSurfaceResize(const SkISize& size) {
  FML_DLOG(INFO) << "OnScreenSurfaceResize";
  return true;
}

// |OHOSSurface|
bool OHOSSurfaceSoftware::SetNativeWindow(
    fml::RefPtr<OHOSNativeWindow> window) {
  FML_DLOG(INFO) << "SetNativeWindow";
  native_window_ = std::move(window);
  if (!(native_window_ && native_window_->IsValid())) {
    FML_DLOG(INFO) << "SetNativeWindow failed.";
    return false;
  }

  LOGD("SetNativeWindow true");
  return true;
}

// |GPUSurfaceSoftwareDelegate|
sk_sp<SkSurface> OHOSSurfaceSoftware::AcquireBackingStore(const SkISize& size) {
  FML_DLOG(INFO) << "AcquireBackingStore...";
  if (!IsValid()) {
    LOGE("AcquireBackingStore the surface is Invalid");
    return nullptr;
  }

  if (sk_surface_ != nullptr &&
      SkISize::Make(sk_surface_->width(), sk_surface_->height()) == size) {
    // The old and new surface sizes are the same. Nothing to do here.
    return sk_surface_;
  }

  LOGE("SkImageInfofWidth=%{public}d, fHeight=%{public}d", size.fWidth,
       size.fHeight);
  SkImageInfo image_info =
      SkImageInfo::Make(size.fWidth, size.fHeight, target_color_type_,
                        target_alpha_type_, SkColorSpace::MakeSRGB());

  FML_DLOG(INFO) << "AcquireBackingStore...MakeRaster ";
  sk_surface_ = SkSurface::MakeRaster(image_info);

  LOGD("AcquireBackingStore end");
  return sk_surface_;
}

// |GPUSurfaceSoftwareDelegate|
/*将 backing_store 画布中的数据 绘制到 native_window 构筑的画布中 */
bool OHOSSurfaceSoftware::PresentBackingStore(sk_sp<SkSurface> backing_store) {
  FML_DLOG(INFO) << "PresentBackingStore...MakeRaster ";
  if (!IsValid() || backing_store == nullptr) {
    LOGE("PresentBackingStore  backing_store is inValid");
    return false;
  }

  SkPixmap pixmap;
  LOGE("PresentBackingStore peekPixels ....");

  if (!backing_store->peekPixels(&pixmap)) {
    LOGE("PresentBackingStore peekPixels failed");
    return false;
  }

  OHNativeWindowBuffer* buffer = nullptr;
  int fenceFd = -1;
  FML_DLOG(INFO) << "PresentBackingStore Requestbuffer  ..."
                 << (int64_t)native_window_.get()->Gethandle();
  if (native_window_.get() == nullptr || !native_window_.get()->IsValid()) {
    FML_DLOG(ERROR)
        << "PresentBackingStore Requestbuffer  ...native_window is invalid "
        << (int64_t)native_window_.get()->Gethandle();
    return false;
  }

  int32_t ret = OH_NativeWindow_NativeWindowRequestBuffer(
      native_window_.get()->Gethandle(), &buffer, &fenceFd);
  if (ret != 0) {
    LOGE(
        "PresentBackingStore  OH_NativeWindow_NativeWindowRequestBuffer failed "
        ":%{public}d",
        ret);
    return false;
  }

  BufferHandle* bufferHandle =
      OH_NativeWindow_GetBufferHandleFromNative(buffer);

  if (bufferHandle == nullptr) {
    FML_DLOG(ERROR) << "PresentBackingStore  "
                       "OH_NativeWindow_GetBufferHandleFromNative failed .";
    OH_NativeWindow_DestroyNativeWindowBuffer(buffer);
    return false;
  }
  LOGI(
      "BufferHandle.fd:%{public}d,w:%{public}d,h:%{public}d,stride:%{public}d,"
      "format:%{public}d,usage:%{public}ld,virAddr:%{public}p,phyAddr:%{public}"
      "ld,key:%{public}d",
      bufferHandle->fd, bufferHandle->width, bufferHandle->height,
      bufferHandle->stride, bufferHandle->format, bufferHandle->usage,
      bufferHandle->virAddr, bufferHandle->phyAddr, bufferHandle->key);
  void* virAddr = mmap(nullptr, bufferHandle->size, PROT_READ | PROT_WRITE,
                       MAP_SHARED, bufferHandle->fd, 0);
  if (virAddr == MAP_FAILED) {
    FML_DLOG(ERROR) << "mmap BufferHandle.virAddr  failed ";
    OH_NativeWindow_DestroyNativeWindowBuffer(buffer);
    return false;
  }

  {
    SkColorType color_type;
    SkAlphaType alpha_type;
    FML_DLOG(INFO) << "GetSkColorType...";
    if (GetSkColorType(bufferHandle->format, &color_type, &alpha_type)) {
      SkImageInfo native_image_info = SkImageInfo::Make(
          bufferHandle->width, bufferHandle->height, color_type, alpha_type);
      FML_DLOG(INFO) << "native_image_info.w:" << native_image_info.width()
                     << ",h:" << native_image_info.height();
      int bytesPerPixel = 1;  // SkColorTypeBytesPerPixel(color_type);
      FML_DLOG(INFO) << "MakeRasterDirect,bytesPerPixel:" << bytesPerPixel;

      std::unique_ptr<SkCanvas> canvas = SkCanvas::MakeRasterDirect(
          native_image_info, virAddr, bufferHandle->stride * bytesPerPixel);
      FML_DLOG(INFO) << "MakeRasterDirect,created canvas:"
                     << (int64_t)canvas.get();

      if (canvas) {
        SkBitmap bitmap;
        if (bitmap.installPixels(pixmap)) {
          FML_DLOG(INFO) << "MakeRasterDirect,canvasdrawImageRect.width:"
                         << bufferHandle->width << ",height"
                         << bufferHandle->height;
          canvas->drawImageRect(
              bitmap.asImage(),
              SkRect::MakeIWH(bufferHandle->width, bufferHandle->height),
              SkSamplingOptions());

        } else {
          FML_DLOG(INFO) << "bitmap.installPixels  failed .";
        }

      } else {
        FML_DLOG(INFO) << "MakeRasterDirect  Failed.";
      }
    } else {
      FML_DLOG(INFO) << "GetSkColorType Failed.";
    }
  }

  Region region{nullptr, 0};
  if (virAddr != nullptr) {
    munmap(virAddr, bufferHandle->size);
  }
  LOGI("OH_NativeWindow_NativeWindowFlushBuffer  ....");
  ret = OH_NativeWindow_NativeWindowFlushBuffer(
      native_window_.get()->Gethandle(), buffer, fenceFd, region);
  LOGI("PresentBackingStore flush Buffer :%{public}d", ret);
  OH_NativeWindow_DestroyNativeWindowBuffer(buffer);
  return ret == 0;
}

}  // namespace flutter
