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

#include "flutter/shell/platform/ohos/napi/platform_view_ohos_napi.h"
#include "flutter/shell/platform/ohos/ohos_main.h"
#include "napi/native_api.h"
#include "napi_common.h"
#include "ohos_xcomponent_adapter.h"

// namespace flutter {

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
  FML_DLOG(INFO) << "Init NAPI Start.";
  napi_property_descriptor desc[] = {
      DECLARE_NAPI_FUNCTION("nativeInit", flutter::OhosMain::NativeInit),
      DECLARE_NAPI_FUNCTION(
          "nativeImageDecodeCallback",
          flutter::OHOSImageGenerator::NativeImageDecodeCallback),
      DECLARE_NAPI_FUNCTION(
          "nativeUpdateRefreshRate",
          flutter::PlatformViewOHOSNapi::nativeUpdateRefreshRate),
      DECLARE_NAPI_FUNCTION(
          "nativeRunBundleAndSnapshotFromLibrary",
          flutter::PlatformViewOHOSNapi::nativeRunBundleAndSnapshotFromLibrary),
      DECLARE_NAPI_FUNCTION(
          "nativePrefetchDefaultFontManager",
          flutter::PlatformViewOHOSNapi::nativePrefetchDefaultFontManager),
      DECLARE_NAPI_FUNCTION(
          "nativeGetIsSoftwareRenderingEnabled",
          flutter::PlatformViewOHOSNapi::nativeGetIsSoftwareRenderingEnabled),
      DECLARE_NAPI_FUNCTION("nativeAttach",
                            flutter::PlatformViewOHOSNapi::nativeAttach),
      DECLARE_NAPI_FUNCTION("nativeSpawn",
                            flutter::PlatformViewOHOSNapi::nativeSpawn),
      DECLARE_NAPI_FUNCTION("nativeDestroy",
                            flutter::PlatformViewOHOSNapi::nativeDestroy),
      DECLARE_NAPI_FUNCTION(
          "nativeSetViewportMetrics",
          flutter::PlatformViewOHOSNapi::nativeSetViewportMetrics),
      DECLARE_NAPI_FUNCTION(
          "nativeSetAccessibilityFeatures",
          flutter::PlatformViewOHOSNapi::nativeSetAccessibilityFeatures),
      DECLARE_NAPI_FUNCTION(
          "nativeCleanupMessageData",
          flutter::PlatformViewOHOSNapi::nativeCleanupMessageData),
      DECLARE_NAPI_FUNCTION(
          "nativeDispatchEmptyPlatformMessage",
          flutter::PlatformViewOHOSNapi::nativeDispatchEmptyPlatformMessage),
      DECLARE_NAPI_FUNCTION(
          "nativeDispatchPlatformMessage",
          flutter::PlatformViewOHOSNapi::nativeDispatchPlatformMessage),
      DECLARE_NAPI_FUNCTION(
          "nativeInvokePlatformMessageEmptyResponseCallback",
          flutter::PlatformViewOHOSNapi::
              nativeInvokePlatformMessageEmptyResponseCallback),
      DECLARE_NAPI_FUNCTION("nativeInvokePlatformMessageResponseCallback",
                            flutter::PlatformViewOHOSNapi::
                                nativeInvokePlatformMessageResponseCallback),
      DECLARE_NAPI_FUNCTION(
          "nativeLoadDartDeferredLibrary",
          flutter::PlatformViewOHOSNapi::nativeLoadDartDeferredLibrary),
      DECLARE_NAPI_FUNCTION(
          "nativeUpdateOhosAssetManager",
          flutter::PlatformViewOHOSNapi::nativeUpdateOhosAssetManager),
      DECLARE_NAPI_FUNCTION(
          "nativeDeferredComponentInstallFailure",
          flutter::PlatformViewOHOSNapi::nativeDeferredComponentInstallFailure),
      DECLARE_NAPI_FUNCTION("nativeGetPixelMap",
                            flutter::PlatformViewOHOSNapi::nativeGetPixelMap),
      DECLARE_NAPI_FUNCTION(
          "nativeNotifyLowMemoryWarning",
          flutter::PlatformViewOHOSNapi::nativeNotifyLowMemoryWarning),
      DECLARE_NAPI_FUNCTION(
          "nativeFlutterTextUtilsIsEmoji",
          flutter::PlatformViewOHOSNapi::nativeFlutterTextUtilsIsEmoji),
      DECLARE_NAPI_FUNCTION(
          "nativeFlutterTextUtilsIsEmojiModifier",
          flutter::PlatformViewOHOSNapi::nativeFlutterTextUtilsIsEmojiModifier),
      DECLARE_NAPI_FUNCTION("nativeFlutterTextUtilsIsEmojiModifierBase",
                            flutter::PlatformViewOHOSNapi::
                                nativeFlutterTextUtilsIsEmojiModifierBase),
      DECLARE_NAPI_FUNCTION("nativeFlutterTextUtilsIsVariationSelector",
                            flutter::PlatformViewOHOSNapi::
                                nativeFlutterTextUtilsIsVariationSelector),
      DECLARE_NAPI_FUNCTION("nativeFlutterTextUtilsIsRegionalIndicator",
                            flutter::PlatformViewOHOSNapi::
                                nativeFlutterTextUtilsIsRegionalIndicator),
      DECLARE_NAPI_FUNCTION(
          "nativeGetSystemLanguages",
          flutter::PlatformViewOHOSNapi::nativeGetSystemLanguages),

  };
  napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
  bool ret = flutter::XComponentAdapter::GetInstance()->Export(env, exports);
  if (!ret) {
    LOGE("Init NAPI Failed.");
  } else {
    FML_DLOG(INFO) << "Init NAPI Succeed.";
  }
  return exports;
}
EXTERN_C_END

static napi_module flutterModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "flutter",
    .nm_priv = ((void*)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) {
  napi_module_register(&flutterModule);
}

//}
