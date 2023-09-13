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

#ifndef FLUTTER_IMAGE_GENERATOR_H
#define FLUTTER_IMAGE_GENERATOR_H

#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/painting/image_generator.h"

#include "napi/native_api.h"
#include "napi/platform_view_ohos_napi.h"
#include "napi_common.h"

namespace flutter {

class OHOSImageGenerator : public ImageGenerator {
 private:
  explicit OHOSImageGenerator(
      sk_sp<SkData> buffer,
      std::shared_ptr<PlatformViewOHOSNapi> napi_facade);

  static napi_env g_env;

 public:
  static napi_value ImageNativeInit(napi_env env, napi_callback_info info);

  static napi_value NativeImageDecodeCallback(napi_env env,
                                              napi_callback_info info);

  ~OHOSImageGenerator();

  // |ImageGenerator|
  const SkImageInfo& GetInfo() override;

  // |ImageGenerator|
  unsigned int GetFrameCount() const override;

  // |ImageGenerator|
  unsigned int GetPlayCount() const override;

  // |ImageGenerator|
  const ImageGenerator::FrameInfo GetFrameInfo(
      unsigned int frame_index) const override;

  // |ImageGenerator|
  SkISize GetScaledDimensions(float desired_scale) override;

  // |ImageGenerator|
  bool GetPixels(const SkImageInfo& info,
                 void* pixels,
                 size_t row_bytes,
                 unsigned int frame_index,
                 std::optional<unsigned int> prior_frame) override;

  void DecodeImage();

  static std::shared_ptr<ImageGenerator> MakeFromData(
      sk_sp<SkData> data,
      const fml::RefPtr<fml::TaskRunner>& task_runner,
      std::shared_ptr<PlatformViewOHOSNapi> napi_facade);

 private:
  sk_sp<SkData> data_;
  sk_sp<SkData> software_decoded_data_;

  SkImageInfo image_info_;

  std::shared_ptr<PlatformViewOHOSNapi> napi_facade_;

  /// Blocks until the header of the image has been decoded and the image
  /// dimensions have been determined.
  fml::ManualResetWaitableEvent header_decoded_latch_;

  /// Blocks until the image has been fully decoded.
  fml::ManualResetWaitableEvent fully_decoded_latch_;

  // block this unconstruct until nativeCallback called
  fml::ManualResetWaitableEvent native_callback_latch_;

  void DoDecodeImage();

  bool IsValidImageData();

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(OHOSImageGenerator);
};
}  // namespace flutter
#endif