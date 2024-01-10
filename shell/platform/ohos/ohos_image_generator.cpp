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

#include "ohos_image_generator.h"

#include <memory>
#include <utility>

#include <multimedia/image_framework/image_pixel_map_napi.h>
#include "third_party/skia/include/codec/SkCodecAnimation.h"

namespace flutter {

OHOSImageGenerator::OHOSImageGenerator(
    sk_sp<SkData> buffer,
    std::shared_ptr<PlatformViewOHOSNapi> napi_facade)
    : data_(std::move(buffer)), image_info_(SkImageInfo::MakeUnknown(-1, -1)) {
  napi_facade_ = napi_facade;
}

napi_env OHOSImageGenerator::g_env = nullptr;

napi_value OHOSImageGenerator::ImageNativeInit(napi_env env,
                                               napi_callback_info info) {
  g_env = env;

  return nullptr;
}

OHOSImageGenerator::~OHOSImageGenerator() = default;

// |ImageGenerator|
const SkImageInfo& OHOSImageGenerator::GetInfo() {
  header_decoded_latch_.Wait();
  return image_info_;
}

// |ImageGenerator|
unsigned int OHOSImageGenerator::GetFrameCount() const {
  return 1;
}

// |ImageGenerator|
unsigned int OHOSImageGenerator::GetPlayCount() const {
  return 1;
}

// |ImageGenerator|
const ImageGenerator::FrameInfo OHOSImageGenerator::GetFrameInfo(
    unsigned int frame_index) const {
  return {.required_frame = std::nullopt,
          .duration = 0,
          .disposal_method = SkCodecAnimation::DisposalMethod::kKeep};
}

// |ImageGenerator|
SkISize OHOSImageGenerator::GetScaledDimensions(float desired_scale) {
  return GetInfo().dimensions();
}

// |ImageGenerator|
bool OHOSImageGenerator::GetPixels(const SkImageInfo& info,
                                   void* pixels,
                                   size_t row_bytes,
                                   unsigned int frame_index,
                                   std::optional<unsigned int> prior_frame) {
  fully_decoded_latch_.Wait();
  if (!software_decoded_data_) {
    return false;
  }

  if (kRGBA_8888_SkColorType != info.colorType()) {
    return false;
  }

  switch (info.alphaType()) {
    case kOpaque_SkAlphaType:
      if (kOpaque_SkAlphaType != GetInfo().alphaType()) {
        return false;
      }
      break;
    case kPremul_SkAlphaType:
      break;
    default:
      return false;
  }

  // TODO(bdero): Override `GetImage()` to use `SkImage::FromAHardwareBuffer` on
  // API level 30+ once it's updated to do symbol lookups and not get
  // preprocessed out in Skia. This will allow for avoiding this copy in
  // cases where the result image doesn't need to be resized.
  memcpy(pixels, software_decoded_data_->data(),
         software_decoded_data_->size());
  return true;
}

void OHOSImageGenerator::DecodeImage() {
  DoDecodeImage();

  header_decoded_latch_.Signal();
  fully_decoded_latch_.Signal();
}

std::shared_ptr<ImageGenerator> OHOSImageGenerator::MakeFromData(
    sk_sp<SkData> data,
    const fml::RefPtr<fml::TaskRunner>& task_runner,
    std::shared_ptr<PlatformViewOHOSNapi> napi_facade) {
  // contructer is private,
  std::shared_ptr<OHOSImageGenerator> generator(
      new OHOSImageGenerator(std::move(data), napi_facade));

  fml::TaskRunner::RunNowOrPostTask(
      task_runner, [generator]() { generator->DecodeImage(); });

  if (generator->IsValidImageData()) {
    return generator;
  }
  return nullptr;
}

void OHOSImageGenerator::DoDecodeImage() {
  napi_facade_->DecodeImage((int64_t)this, (void*)data_->data(), data_->size());
  native_callback_latch_.Wait();
}

bool OHOSImageGenerator::IsValidImageData() {
  // The generator kicks off an IO task to decode everything, and calls to
  // "GetInfo()" block until either the header has been decoded or decoding has
  // failed, whichever is sooner. The decoder is initialized with a width and
  // height of -1 and will update the dimensions if the image is able to be
  // decoded.
  return GetInfo().height() != -1;
}

napi_value OHOSImageGenerator::NativeImageDecodeCallback(
    napi_env env,
    napi_callback_info info) {
  // to get this

  size_t argc = 4;

  napi_value args[4] = {nullptr};

  napi_status status =
      napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (status != napi_ok) {
    LOGE("NativeImageDecodeCallback napi_get_cb_info error");
    return nullptr;
  }

  if (argc != 4) {
    FML_LOG(ERROR) << "argc is error";
    return nullptr;
  }

  // unwarp object
  int64_t width = 0;
  int64_t height = 0;
  OHOSImageGenerator* generator = nullptr;

  status = napi_get_value_int64(env, args[0], &width);
  if (status != napi_ok) {
    FML_LOG(ERROR) << "napi_get_value_int32 width error";
  }

  status = napi_get_value_int64(env, args[1], &height);
  if (status != napi_ok) {
    FML_LOG(ERROR) << "napi_get_value_int32 height error";
  }

  status = napi_get_value_int64(env, args[2], (int64_t*)&generator);
  if (status != napi_ok) {
    FML_LOG(ERROR) << "napi_get_value_int64 this  error";
  }

  // call object native func to set image_info

  generator->image_info_ = SkImageInfo::Make(
      width, height, kRGBA_8888_SkColorType, kPremul_SkAlphaType);

  generator->header_decoded_latch_.Signal();

  void* pixel_lock;

  int ret = OHOS::Media::OH_AccessPixels(g_env, args[3], (void**)&pixel_lock);
  if (ret != 0) {
    FML_DLOG(ERROR) << "Failed to lock pixels, error=" << ret;
    generator->native_callback_latch_.Signal();
    return nullptr;
  }
  // pixel_lock, g_env_ =g_env , resultout

  struct ReleaseCtx {
    napi_env env_;
    napi_ref ref = nullptr;
    char* buf;
  };

  ReleaseCtx* ctx = new ReleaseCtx();
  ctx->env_ = env;
  ctx->buf = (char*)pixel_lock;
  napi_create_reference(env, args[3], 1, &(ctx->ref));

  SkData::ReleaseProc on_release = [](const void* ptr, void* context) -> void {
    ReleaseCtx* ctx = reinterpret_cast<ReleaseCtx*>(context);
    napi_value res = nullptr;
    napi_get_reference_value(ctx->env_, ctx->ref, &res);
    OHOS::Media::OH_UnAccessPixels(ctx->env_, res);
    napi_delete_reference(ctx->env_, ctx->ref);
    return;
  };

  // get software_decode_data by call back, bitmap buffer will unlock in
  // callback

  generator->software_decoded_data_ = SkData::MakeWithProc(
      pixel_lock, width * height * sizeof(uint32_t), on_release, ctx);

  // notify dodecode
  generator->native_callback_latch_.Signal();
  return nullptr;
}

}  // namespace flutter