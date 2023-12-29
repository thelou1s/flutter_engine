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

#ifndef PLATFORM_VIEW_OHOS_NAPI_H
#define PLATFORM_VIEW_OHOS_NAPI_H
#include <memory>
#include "../napi_common.h"
#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/common/settings.h"
#include "flutter/fml/file.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/size.h"
#include "flutter/lib/ui/plugins/callback_cache.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "flutter/shell/common/run_configuration.h"
#include "napi/native_api.h"
// class for all c++ to call js function
namespace flutter {

struct locale {
  std::string language;
  std::string script;
  std::string region;
};

class PlatformViewOHOSNapi {
 public:
  static napi_value nativeDispatchEmptyPlatformMessage(
      napi_env env,
      napi_callback_info info);  // 发送一个空的PlatformMessage
  static napi_value nativeDispatchPlatformMessage(
      napi_env env,
      napi_callback_info info);  // 发送一个PlatformMessage
  static napi_value nativeInvokePlatformMessageEmptyResponseCallback(
      napi_env env,
      napi_callback_info info);  // 空的PlatformMessage响应回调
  static napi_value nativeInvokePlatformMessageResponseCallback(
      napi_env env,
      napi_callback_info info);

  explicit PlatformViewOHOSNapi(napi_env env);
  void SetPlatformTaskRunner(fml::RefPtr<fml::TaskRunner> platform_task_runner);
  void FlutterViewHandlePlatformMessageResponse(
      int reponse_id,
      std::unique_ptr<fml::Mapping> data);
  void FlutterViewHandlePlatformMessage(
      int reponse_id,
      std::unique_ptr<flutter::PlatformMessage> message);

  void FlutterViewOnFirstFrame();
  void FlutterViewOnPreEngineRestart();
  flutter::locale resolveNativeLocale(
      std::vector<flutter::locale> supportedLocales);
  std::unique_ptr<std::vector<std::string>>
  FlutterViewComputePlatformResolvedLocales(
      const std::vector<std::string>& support_locale_data);
  void DecodeImage(int64_t imageGeneratorAddress,
                   void* inputData,
                   size_t dataSize);

  static napi_value nativeUpdateRefreshRate(
      napi_env env,
      napi_callback_info info);  // 设置刷新率
  static napi_value nativeRunBundleAndSnapshotFromLibrary(
      napi_env env,
      napi_callback_info info);  // 加载dart工程构建产物
  static napi_value nativePrefetchDefaultFontManager(
      napi_env env,
      napi_callback_info
          info);  // 初始化SkFontMgr::RefDefault()，skia引擎文字管理初始化
  static napi_value nativeGetIsSoftwareRenderingEnabled(
      napi_env env,
      napi_callback_info info);  // 返回是否支持软件绘制

  static napi_value nativeAttach(
      napi_env env,
      napi_callback_info
          info);  // attach flutterNapi实例给到 native
                  // engine，这个支持rkts到flutter平台的无关引擎之间的通信
                  // attach只需要执行一次
  static napi_value nativeSpawn(
      napi_env env,
      napi_callback_info info);  // 从当前的flutterNapi复制一个新的实例
  static napi_value nativeDestroy(
      napi_env env,
      napi_callback_info info);  // Detaches flutterNapi和engine之间的关联
  static napi_value nativeSetViewportMetrics(
      napi_env env,
      napi_callback_info info);  // 把物理屏幕参数通知到native
  static napi_value nativeSetAccessibilityFeatures(
      napi_env env,
      napi_callback_info info);  // 设置能力参数

  static napi_value nativeCleanupMessageData(
      napi_env env,
      napi_callback_info info);  // 清除某个messageData
  static napi_value nativeLoadDartDeferredLibrary(
      napi_env env,
      napi_callback_info info);  // load一个合法的.so文件到dart vm
  static napi_value nativeUpdateOhosAssetManager(
      napi_env env,
      napi_callback_info info);  // 设置ResourceManager和assetBundlePath到engine
  static napi_value nativeDeferredComponentInstallFailure(
      napi_env env,
      napi_callback_info info);  // 加载动态库，或者dart库失败时的通知
  static napi_value nativeGetPixelMap(
      napi_env env,
      napi_callback_info info);  // 从engine获取当前绘制pixelMap
  static napi_value nativeNotifyLowMemoryWarning(
      napi_env env,
      napi_callback_info info);  // 应用低内存警告

  // 下面的方法，从键盘输入中判断当前字符是否是emoji，实现优先级低
  static napi_value nativeFlutterTextUtilsIsEmoji(napi_env env,
                                                  napi_callback_info info);
  static napi_value nativeFlutterTextUtilsIsEmojiModifier(
      napi_env env,
      napi_callback_info info);
  static napi_value nativeFlutterTextUtilsIsEmojiModifierBase(
      napi_env env,
      napi_callback_info info);
  static napi_value nativeFlutterTextUtilsIsVariationSelector(
      napi_env env,
      napi_callback_info info);
  static napi_value nativeFlutterTextUtilsIsRegionalIndicator(
      napi_env env,
      napi_callback_info info);
  static napi_value nativeGetSystemLanguages(
      napi_env env,
      napi_callback_info info);  // 应用下发系统语言设置

  // Surface相关，XComponent调用
  static void SurfaceCreated(int64_t shell_holder, void* window);
  static void SurfaceChanged(int64_t shell_holder,
                             int32_t width,
                             int32_t height);
  static void SurfaceDestroyed(int64_t shell_holder);
  static int64_t GetShellHolder();

 private:
  static napi_env env_;
  napi_ref ref_napi_obj_;
  static std::vector<std::string> system_languages;
  fml::RefPtr<fml::TaskRunner> platform_task_runner_;
};

}  // namespace flutter
#endif
