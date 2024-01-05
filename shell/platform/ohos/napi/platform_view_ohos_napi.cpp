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

#include "platform_view_ohos_napi.h"
#include <dlfcn.h>
#include <js_native_api.h>
#include <rawfile/raw_file.h>
#include <rawfile/raw_file_manager.h>
#include <string>
#include "../types.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/platform/ohos/napi_util.h"
#include "flutter/shell/platform/ohos/ohos_main.h"
#include "flutter/shell/platform/ohos/ohos_shell_holder.h"
#include "flutter/shell/platform/ohos/surface/ohos_native_window.h"
#include "unicode/uchar.h"
#include "flutter/shell/platform/ohos/ohos_xcomponent_adapter.h"

#define OHOS_SHELL_HOLDER (reinterpret_cast<OHOSShellHolder*>(shell_holder))
namespace flutter {

napi_env PlatformViewOHOSNapi::env_;
std::vector<std::string> PlatformViewOHOSNapi::system_languages;

/**
 * @brief send  empty PlatformMessage
 * @note
 * @param nativeShellHolderId: number,channel: string,responseId: number
 * @return void
 */
napi_value PlatformViewOHOSNapi::nativeDispatchEmptyPlatformMessage(
    napi_env env,
    napi_callback_info info) {
  FML_DLOG(INFO) << "PlatformViewOHOSNapi::nativeDispatchEmptyPlatformMessage";
  napi_status ret;
  size_t argc = 3;
  napi_value args[3] = {nullptr};
  napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  int64_t shell_holder, responseId;
  std::string channel;
  ret = napi_get_value_int64(env, args[0], &shell_holder);
  if (ret != napi_ok) {
    LOGE("nativeDispatchEmptyPlatformMessage napi get shell_holder error");
    return nullptr;
  }
  fml::napi::GetString(env, args[1], channel);
  FML_DLOG(INFO) << "nativeDispatchEmptyPlatformMessage channel:" << channel;
  ret = napi_get_value_int64(env, args[2], &responseId);
  if (ret != napi_ok) {
    LOGE("nativeDispatchEmptyPlatformMessage napi get responseId error");
    return nullptr;
  }
  FML_DLOG(INFO) << "PlatformViewOHOSNapi::nativeDispatchEmptyPlatformMessage "
                    "DispatchEmptyPlatformMessage";
  OHOS_SHELL_HOLDER->GetPlatformView()->DispatchEmptyPlatformMessage(
      channel, responseId);
  return nullptr;
}

/**
 * @brief send PlatformMessage
 * @note
 * @param  nativeShellHolderId: number,channel: string,message:
 * ArrayBuffer,position: number,responseId: number
 * @return void
 */
napi_value PlatformViewOHOSNapi::nativeDispatchPlatformMessage(
    napi_env env,
    napi_callback_info info) {
  FML_DLOG(INFO) << "PlatformViewOHOSNapi::nativeDispatchPlatformMessage";
  napi_status ret;
  napi_value thisArg;
  size_t argc = 5;
  napi_value args[5] = {nullptr};
  int64_t shell_holder, responseId, position;
  std::string channel;
  void* message = nullptr;
  size_t message_lenth = 0;

  int32_t status;

  ret = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
  if (argc < 5 || ret != napi_ok) {
    FML_DLOG(ERROR) << "nativeDispatchPlatformMessage napi get argc ,argc="
                    << argc << "<5,error:" << ret;
    napi_throw_type_error(env, nullptr, "Wrong number of arguments");
    return nullptr;
  }
  napi_value napiShellHolder = args[0];
  napi_value napiChannel = args[1];
  napi_value napiMessage = args[2];
  napi_value napiPos = args[3];
  napi_value napiResponseId = args[4];

  ret = napi_get_value_int64(env, napiShellHolder, &shell_holder);
  if (ret != napi_ok) {
    LOGE("nativeDispatchPlatformMessage napi get shell_holder error");
    return nullptr;
  }
  FML_DLOG(INFO) << "nativeDispatchPlatformMessage:shell_holder:"
                 << shell_holder;

  if (0 != (status = fml::napi::GetString(env, napiChannel, channel))) {
    FML_DLOG(ERROR) << "nativeDispatchPlatformMessage napi get channel error:"
                    << status;
    return nullptr;
  }
  FML_DLOG(INFO) << "nativeDispatchEmptyPlatformMessage channel:" << channel;

  if (0 != (status = fml::napi::GetArrayBuffer(env, napiMessage, &message,
                                               &message_lenth))) {
    FML_DLOG(ERROR) << "nativeDispatchPlatformMessage napi get message error:"
                    << status;
    return nullptr;
  }
  if (message == nullptr) {
    FML_LOG(ERROR)
        << "nativeInvokePlatformMessageResponseCallback message null";
    return nullptr;
  }
  ret = napi_get_value_int64(env, napiPos, &position);
  if (ret != napi_ok) {
    LOGE("nativeDispatchPlatformMessage napi get position error");
    return nullptr;
  }
  ret = napi_get_value_int64(env, napiResponseId, &responseId);
  if (ret != napi_ok) {
    LOGE("nativeDispatchPlatformMessage napi get responseId error");
    return nullptr;
  }
  FML_DLOG(INFO) << "DispatchPlatformMessage,channel:" << channel
                 << ",message:" << message << ",position:" << position
                 << ",responseId:" << responseId;

  OHOS_SHELL_HOLDER->GetPlatformView()->DispatchPlatformMessage(
      channel, message, position, responseId);
  return nullptr;
}
/**
 * @brief
 * @note
 * @param  nativeShellHolderId: number,responseId: number
 * @return void
 */
napi_value
PlatformViewOHOSNapi::nativeInvokePlatformMessageEmptyResponseCallback(
    napi_env env,
    napi_callback_info info) {
  FML_DLOG(INFO) << "nativeInvokePlatformMessageEmptyResponseCallback";
  napi_status ret;
  size_t argc = 2;
  napi_value args[2] = {nullptr};
  napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  int64_t shell_holder, responseId;
  ret = napi_get_value_int64(env, args[0], &shell_holder);
  if (ret != napi_ok) {
    LOGE(
        "nativeInvokePlatformMessageEmptyResponseCallback napi get "
        "shell_holder error");
    return nullptr;
  }
  ret = napi_get_value_int64(env, args[1], &responseId);
  if (ret != napi_ok) {
    LOGE(" napi get responseId error");
    return nullptr;
  }
  FML_DLOG(INFO) << "InvokePlatformMessageEmptyResponseCallback";
  OHOS_SHELL_HOLDER->GetPlatformMessageHandler()
      ->InvokePlatformMessageEmptyResponseCallback(responseId);
  return nullptr;
}
/**
 * @brief
 * @note
 * @param  nativeShellHolderId: number, responseId: number, message:
 * ArrayBuffer,position: number
 * @return void
 */
napi_value PlatformViewOHOSNapi::nativeInvokePlatformMessageResponseCallback(
    napi_env env,
    napi_callback_info info) {
  FML_DLOG(INFO) << "nativeInvokePlatformMessageResponseCallback";
  napi_status ret;
  size_t argc = 4;
  napi_value args[4] = {nullptr};
  napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  int64_t shell_holder, responseId, position;
  void* message = nullptr;
  size_t message_lenth = 0;
  ret = napi_get_value_int64(env, args[0], &shell_holder);
  if (ret != napi_ok) {
    LOGE(" napi get shell_holdererror");
    return nullptr;
  }
  ret = napi_get_value_int64(env, args[1], &responseId);
  if (ret != napi_ok) {
    LOGE(" napi get responseId error");
    return nullptr;
  }
  int32_t result =
      fml::napi::GetArrayBuffer(env, args[2], &message, &message_lenth);
  if (result != 0) {
    FML_DLOG(ERROR)
        << "nativeInvokePlatformMessageResponseCallback GetArrayBuffer error "
        << result;
  }
  if (message == nullptr) {
    FML_LOG(ERROR)
        << "nativeInvokePlatformMessageResponseCallback message null";
    return nullptr;
  }
  ret = napi_get_value_int64(env, args[3], &position);
  if (ret != napi_ok) {
    LOGE("nativeInvokePlatformMessageResponseCallback napi get position error");
    return nullptr;
  }

  uint8_t* response_data = static_cast<uint8_t*>(message);
  FML_DCHECK(response_data != nullptr);
  auto mapping = std::make_unique<fml::MallocMapping>(
      fml::MallocMapping::Copy(response_data, response_data + position));
  FML_DLOG(INFO) << "InvokePlatformMessageResponseCallback";
  OHOS_SHELL_HOLDER->GetPlatformMessageHandler()
      ->InvokePlatformMessageResponseCallback(responseId, std::move(mapping));
  return nullptr;
}

/* void PlatformViewOHOSNapi::FlutterViewHandlePlatformMessageResponse(
    int responseId,
    std::unique_ptr<fml::Mapping> data) {

}
 */
PlatformViewOHOSNapi::PlatformViewOHOSNapi(napi_env env) {}

void PlatformViewOHOSNapi::FlutterViewHandlePlatformMessageResponse(
    int reponse_id,
    std::unique_ptr<fml::Mapping> data) {
  FML_DLOG(INFO) << "FlutterViewHandlePlatformMessageResponse";
  napi_status status;
  napi_value callbackParam[2];
  status = napi_create_int64(env_, reponse_id, callbackParam);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "napi_create_int64 reponse_id fail";
  }

  if (data == nullptr) {
    callbackParam[1] = NULL;
  } else {
    callbackParam[1] = fml::napi::CreateArrayBuffer(
        env_, (void*)data->GetMapping(), data->GetSize());
  }

  status = fml::napi::InvokeJsMethod(
      env_, ref_napi_obj_, "handlePlatformMessageResponse", 2, callbackParam);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "InvokeJsMethod fail ";
  }
}

void PlatformViewOHOSNapi::FlutterViewHandlePlatformMessage(
    int reponse_id,
    std::unique_ptr<flutter::PlatformMessage> message) {
  FML_DLOG(INFO) << "FlutterViewHandlePlatformMessage message channal "
                 << message->channel().c_str();

  napi_value callbackParam[4];
  napi_status status;

  status = napi_create_string_utf8(env_, message->channel().c_str(),
                                   message->channel().size(), callbackParam);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "napi_create_string_utf8 err " << status;
    return;
  }

  callbackParam[1] = fml::napi::CreateArrayBuffer(
      env_, (void*)message->data().GetMapping(), message->data().GetSize());

  status = napi_create_int64(env_, reponse_id, &callbackParam[2]);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "napi_create_int64 err " << status;
    return;
  }
  if (message->hasData()) {
    fml::MallocMapping mapping = message->releaseData();
    char* mapData = (char*)mapping.Release();
    status = napi_create_string_utf8(env_, mapData, strlen(mapData),
                                     &callbackParam[3]);
    if (status != napi_ok) {
      FML_DLOG(ERROR) << "napi_create_string_utf8 err " << status;
      return;
    }

    if (mapData) {
      delete mapData;
    }
  } else {
    callbackParam[3] = nullptr;
  }

  status = fml::napi::InvokeJsMethod(env_, ref_napi_obj_,
                                     "handlePlatformMessage", 4, callbackParam);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "InvokeJsMethod fail ";
  }
}

void PlatformViewOHOSNapi::FlutterViewOnFirstFrame() {
  FML_DLOG(INFO) << "FlutterViewOnFirstFrame";
  napi_status status = fml::napi::InvokeJsMethod(env_, ref_napi_obj_,
                                                 "onFirstFrame", 0, nullptr);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "InvokeJsMethod onFirstFrame fail ";
  }
}

void PlatformViewOHOSNapi::FlutterViewOnPreEngineRestart() {
  FML_DLOG(INFO) << "FlutterViewOnPreEngineRestart";
  napi_status status = fml::napi::InvokeJsMethod(
      env_, ref_napi_obj_, "onPreEngineRestart", 0, nullptr);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "InvokeJsMethod onPreEngineRestart fail ";
  }
}

std::vector<std::string> splitString(const std::string& input, char delimiter) {
  std::vector<std::string> result;
  std::stringstream ss(input);
  std::string token;

  while (std::getline(ss, token, delimiter)) {
    result.push_back(token);
  }

  return result;
}
flutter::locale PlatformViewOHOSNapi::resolveNativeLocale(
    std::vector<flutter::locale> supportedLocales) {
  if (supportedLocales.empty()) {
    flutter::locale default_locale;
    default_locale.language = "zh";
    default_locale.script = "Hans";
    default_locale.region = "CN";
    return default_locale;
  }
  char delimiter = '-';
  if (PlatformViewOHOSNapi::system_languages.empty()) {
    PlatformViewOHOSNapi::system_languages.push_back("zh-Hans");
  }
  for (size_t i = 0; i < PlatformViewOHOSNapi::system_languages.size(); i++) {
    std::string language = PlatformViewOHOSNapi::system_languages
        [i];  // 格式language-script-region,例如en-Latn-US
    for (const locale& localeInfo : supportedLocales) {
      if (language == localeInfo.language + "-" + localeInfo.script + "-" +
                          localeInfo.region) {
        return localeInfo;
      }
      std::vector<std::string> element = splitString(language, delimiter);
      if (element[0] + "-" + element[1] ==
          localeInfo.language + "-" + localeInfo.region) {
        return localeInfo;
      }
      if (element[0] == localeInfo.language) {
        return localeInfo;
      }
    }
  }
  return supportedLocales[0];
}

std::unique_ptr<std::vector<std::string>>
PlatformViewOHOSNapi::FlutterViewComputePlatformResolvedLocales(
    const std::vector<std::string>& support_locale_data) {
  std::vector<flutter::locale> supportedLocales;
  std::vector<std::string> result;
  const int localeDataLength = 3;
  flutter::locale mlocale;
  for (size_t i = 0; i < support_locale_data.size(); i += localeDataLength) {
    mlocale.language = support_locale_data[i + LANGUAGE_INDEX];
    mlocale.region = support_locale_data[i + REGION_INDEX];
    mlocale.script = support_locale_data[i + SCRIPT_INDEX];
    supportedLocales.push_back(mlocale);
  }
  mlocale = resolveNativeLocale(supportedLocales);
  result.push_back(mlocale.language);
  result.push_back(mlocale.region);
  result.push_back(mlocale.script);
  FML_DLOG(INFO) << "resolveNativeLocale result to flutter language: "
                 << result[LANGUAGE_INDEX]
                 << " region: " << result[REGION_INDEX]
                 << " script: " << result[SCRIPT_INDEX];
  return std::make_unique<std::vector<std::string>>(std::move(result));
}

void PlatformViewOHOSNapi::DecodeImage(int64_t imageGeneratorAddress,
                                       void* inputData,
                                       size_t dataSize) {
  FML_DLOG(INFO) << "start decodeImage";
  platform_task_runner_->PostTask(fml::MakeCopyable(
      [imageGeneratorAddress_ = imageGeneratorAddress,
       inputData_ = std::move(inputData), dataSize_ = dataSize, this]() mutable {
        napi_value callbackParam[2];

        callbackParam[0] =
            fml::napi::CreateArrayBuffer(env_, inputData_, dataSize_);
        napi_status status =
            napi_create_int64(env_, imageGeneratorAddress_, &callbackParam[1]);
        if (status != napi_ok) {
          FML_DLOG(ERROR) << "napi_create_int64 decodeImage fail ";
        }
        status = fml::napi::InvokeJsMethod(env_, ref_napi_obj_, "decodeImage",
                                           2, callbackParam);
        if (status != napi_ok) {
          FML_DLOG(ERROR) << "InvokeJsMethod decodeImage fail ";
        }
      }));
}

/**
 *   attach flutterNapi实例给到 native
 * engine，这个支持rkts到flutter平台的无关引擎之间的通信 attach只需要执行一次
 */
napi_value PlatformViewOHOSNapi::nativeAttach(napi_env env,
                                              napi_callback_info info) {
  FML_DLOG(INFO) << "PlatformViewOHOSNapi::nativeAttach";

  napi_status status;
  // 获取传入的参数
  size_t argc = 1;
  napi_value argv[1];
  status = napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "nativeAttach Failed to get napiObjec info";
  }

  std::shared_ptr<PlatformViewOHOSNapi> napi_facade =
      std::make_shared<PlatformViewOHOSNapi>(env);
  napi_create_reference(env, argv[0], 1, &(napi_facade->ref_napi_obj_));

  uv_loop_t* platform_loop = nullptr;
  status = napi_get_uv_event_loop(env, &platform_loop);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "nativeAttach napi_get_uv_event_loop  fail";
  }

  auto shell_holder = std::make_unique<OHOSShellHolder>(
      OhosMain::Get().GetSettings(), napi_facade, platform_loop);
  if (shell_holder->IsValid()) {
    int64_t shell_holder_value =
        reinterpret_cast<int64_t>(shell_holder.get());
    FML_DLOG(INFO) << "PlatformViewOHOSNapi shell_holder:"
                   << shell_holder_value;
    napi_value id;
    napi_create_int64(env, reinterpret_cast<int64_t>(shell_holder.release()),
                      &id);
    return id;
  } else {
    FML_DLOG(ERROR) << "shell holder inValid";
    napi_value id;
    napi_create_int64(env, 0, &id);
    return id;
  }
}

/**
 *  加载dart工程构建产物
 */
napi_value PlatformViewOHOSNapi::nativeRunBundleAndSnapshotFromLibrary(
    napi_env env,
    napi_callback_info info) {
  napi_status ret;
  size_t argc = 6;
  napi_value args[6] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeRunBundleAndSnapshotFromLibrary napi_get_cb_info error");
    return nullptr;
  }

  int64_t shell_holder;
  ret = napi_get_value_int64(env, args[0], &shell_holder);
  if (ret != napi_ok) {
    LOGE("nativeRunBundleAndSnapshotFromLibrary napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeRunBundleAndSnapshotFromLibrary::shell_holder : %{public}ld",
       shell_holder);

  std::string bundlePath;
  if (fml::napi::SUCCESS != fml::napi::GetString(env, args[1], bundlePath)) {
    LOGE(" napi_get_value_string_utf8 error");
    return nullptr;
  }
  LOGD("nativeRunBundleAndSnapshotFromLibrary: bundlePath: %{public}s",
       bundlePath.c_str());

  std::string entrypointFunctionName;
  if (fml::napi::SUCCESS !=
      fml::napi::GetString(env, args[2], entrypointFunctionName)) {
    LOGE(" napi_get_value_string_utf8 error");
    return nullptr;
  }
  LOGD("entrypointFunctionName: %{public}s", entrypointFunctionName.c_str());

  std::string pathToEntrypointFunction;
  if (fml::napi::SUCCESS !=
      fml::napi::GetString(env, args[3], pathToEntrypointFunction)) {
    LOGE(" napi_get_value_string_utf8 error");
    return nullptr;
  }
  LOGD(" pathToEntrypointFunction: %{public}s",
       pathToEntrypointFunction.c_str());

  NativeResourceManager* ResourceManager =
      OH_ResourceManager_InitNativeResourceManager(env, args[4]);

  std::vector<std::string> entrypointArgs;
  if (fml::napi::SUCCESS !=
      fml::napi::GetArrayString(env, args[5], entrypointArgs)) {
    LOGE("nativeRunBundleAndSnapshotFromLibrary GetArrayString error");
    return nullptr;
  }

  auto ohos_asset_provider = std::make_unique<flutter::OHOSAssetProvider>(
      static_cast<void*>(ResourceManager));
  OHOS_SHELL_HOLDER->Launch(std::move(ohos_asset_provider),
                            entrypointFunctionName, pathToEntrypointFunction,
                            entrypointArgs);

  env_ = env;
  return nullptr;
}

/**
 *  设置ResourceManager和assetBundlePath到engine
 */
napi_value PlatformViewOHOSNapi::nativeUpdateOhosAssetManager(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeUpdateOhosAssetManager");

  // TODO:
  return nullptr;
}

/**
 * 从engine获取当前绘制pixelMap
 */
napi_value PlatformViewOHOSNapi::nativeGetPixelMap(napi_env env,
                                                   napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeGetPixelMap");

  // TODO:
  return nullptr;
}

/**
 * 从当前的flutterNapi复制一个新的实例
 */
napi_value PlatformViewOHOSNapi::nativeSpawn(napi_env env, napi_callback_info info) {
  napi_status ret;
  size_t argc = 6;
  napi_value args[6] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeSpawn napi_get_cb_info error");
    return nullptr;
  }

  int64_t shell_holder;
  ret = napi_get_value_int64(env, args[0], &shell_holder);
  if (ret != napi_ok) {
    LOGE("nativeSpawn napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSpawn::shell_holder : %{public}ld", shell_holder);

  std::string entrypoint;
  if (fml::napi::SUCCESS != fml::napi::GetString(env, args[1], entrypoint)) {
    LOGE(" napi_get_value_string_utf8 error");
    return nullptr;
  }
  LOGD("entrypoint: %{public}s", entrypoint.c_str());

  std::string libraryUrl;
  if (fml::napi::SUCCESS != fml::napi::GetString(env, args[2], libraryUrl)) {
    LOGE(" napi_get_value_string_utf8 error");
    return nullptr;
  }
  LOGD(" libraryUrl: %{public}s", libraryUrl.c_str());

  std::string initial_route;
  if (fml::napi::SUCCESS != fml::napi::GetString(env, args[3], initial_route)) {
    LOGE(" napi_get_value_string_utf8 error");
    return nullptr;
  }
  LOGD(" initialRoute: %{public}s", initial_route.c_str());

  std::vector<std::string> entrypoint_args;
  if (fml::napi::SUCCESS != fml::napi::GetArrayString(env, args[4], entrypoint_args)) {
    LOGE("nativeRunBundleAndSnapshotFromLibrary GetArrayString error");
    return nullptr;
  }

  std::shared_ptr<PlatformViewOHOSNapi> napi_facade = std::make_shared<PlatformViewOHOSNapi>(env);
  auto spawned_shell_holder = OHOS_SHELL_HOLDER->Spawn(
      napi_facade, entrypoint, libraryUrl, initial_route, entrypoint_args);

  if (spawned_shell_holder == nullptr || !spawned_shell_holder->IsValid()) {
    FML_LOG(ERROR) << "Could not spawn Shell";
    return nullptr;
  }

  napi_value shell_holder_id;
  napi_create_int64(env, reinterpret_cast<int64_t>(spawned_shell_holder.release()), &shell_holder_id);
  return shell_holder_id;
}

static void LoadLoadingUnitFailure(intptr_t loading_unit_id,
                                   const std::string& message,
                                   bool transient) {
  // TODO(garyq): Implement
  LOGD("LoadLoadingUnitFailure: message  %s  transient %d", message.c_str(),
       transient);
}

/**
 * load一个合法的.so文件到dart vm
 */
napi_value PlatformViewOHOSNapi::nativeLoadDartDeferredLibrary(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeLoadDartDeferredLibrary");

  napi_status ret;
  size_t argc = 3;
  napi_value args[3] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeLoadDartDeferredLibrary napi_get_cb_info error");
    return nullptr;
  }

  int64_t shell_holder;
  ret = napi_get_value_int64(env, args[0], &shell_holder);
  if (ret != napi_ok) {
    LOGE("nativeLoadDartDeferredLibrary napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeLoadDartDeferredLibrary::shell_holder : %{public}ld",
       shell_holder);

  int64_t loadingUnitId;
  ret = napi_get_value_int64(env, args[1], &loadingUnitId);
  if (ret != napi_ok) {
    LOGE("nativeLoadDartDeferredLibrary napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeLoadDartDeferredLibrary::loadingUnitId : %{public}ld",
       loadingUnitId);

  std::vector<std::string> search_paths;
  if (fml::napi::SUCCESS !=
      fml::napi::GetArrayString(env, args[2], search_paths)) {
    LOGE("nativeLoadDartDeferredLibrary GetArrayString error");
    return nullptr;
  }

  LOGD("nativeLoadDartDeferredLibrary::search_paths");
  for (const std::string& path : search_paths) {
    LOGD("%{public}s", path.c_str());
  }

  intptr_t loading_unit_id = static_cast<intptr_t>(loadingUnitId);
  // Use dlopen here to directly check if handle is nullptr before creating a
  // NativeLibrary.
  void* handle = nullptr;
  while (handle == nullptr && !search_paths.empty()) {
    std::string path = search_paths.back();
    handle = ::dlopen(path.c_str(), RTLD_NOW);
    search_paths.pop_back();
  }
  if (handle == nullptr) {
    LoadLoadingUnitFailure(loading_unit_id,
                           "No lib .so found for provided search paths.", true);
    return nullptr;
  }
  fml::RefPtr<fml::NativeLibrary> native_lib =
      fml::NativeLibrary::CreateWithHandle(handle, false);

  // Resolve symbols.
  std::unique_ptr<const fml::SymbolMapping> data_mapping =
      std::make_unique<const fml::SymbolMapping>(
          native_lib, DartSnapshot::kIsolateDataSymbol);
  std::unique_ptr<const fml::SymbolMapping> instructions_mapping =
      std::make_unique<const fml::SymbolMapping>(
          native_lib, DartSnapshot::kIsolateInstructionsSymbol);

  OHOS_SHELL_HOLDER->GetPlatformView()->LoadDartDeferredLibrary(
      loading_unit_id, std::move(data_mapping),
      std::move(instructions_mapping));

  return nullptr;
}

/**
 *  把物理屏幕参数通知到native
 */
napi_value PlatformViewOHOSNapi::nativeSetViewportMetrics(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeSetViewportMetrics");

  napi_status ret;
  size_t argc = 20;
  napi_value args[20] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_cb_info error");
    return nullptr;
  }

  int64_t shell_holder;
  ret = napi_get_value_int64(env, args[0], &shell_holder);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::shell_holder : %{public}ld", shell_holder);

  double devicePixelRatio;
  ret = napi_get_value_double(env, args[1], &devicePixelRatio);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::devicePixelRatio : %{public}lf",
       devicePixelRatio);

  int64_t physicalWidth;
  ret = napi_get_value_int64(env, args[2], &physicalWidth);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::physicalWidth : %{public}ld", physicalWidth);

  int64_t physicalHeight;
  ret = napi_get_value_int64(env, args[3], &physicalHeight);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::physicalHeight : %{public}ld",
       physicalHeight);

  int64_t physicalPaddingTop;
  ret = napi_get_value_int64(env, args[4], &physicalPaddingTop);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::physicalPaddingTop : %{public}ld",
       physicalPaddingTop);

  int64_t physicalPaddingRight;
  ret = napi_get_value_int64(env, args[5], &physicalPaddingRight);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::physicalPaddingRight : %{public}ld",
       physicalPaddingRight);

  int64_t physicalPaddingBottom;
  ret = napi_get_value_int64(env, args[6], &physicalPaddingBottom);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::physicalPaddingBottom : %{public}ld",
       physicalPaddingBottom);

  int64_t physicalPaddingLeft;
  ret = napi_get_value_int64(env, args[7], &physicalPaddingLeft);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::physicalPaddingLeft : %{public}ld",
       physicalPaddingLeft);

  int64_t physicalViewInsetTop;
  ret = napi_get_value_int64(env, args[8], &physicalViewInsetTop);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::physicalViewInsetTop : %{public}ld",
       physicalViewInsetTop);

  int64_t physicalViewInsetRight;
  ret = napi_get_value_int64(env, args[9], &physicalViewInsetRight);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::physicalViewInsetRight : %{public}ld",
       physicalViewInsetRight);

  int64_t physicalViewInsetBottom;
  ret = napi_get_value_int64(env, args[10], &physicalViewInsetBottom);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::physicalViewInsetBottom : %{public}ld",
       physicalViewInsetBottom);

  int64_t physicalViewInsetLeft;
  ret = napi_get_value_int64(env, args[11], &physicalViewInsetLeft);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::physicalViewInsetLeft : %{public}ld",
       physicalViewInsetLeft);
  int64_t systemGestureInsetTop;
  ret = napi_get_value_int64(env, args[12], &systemGestureInsetTop);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::systemGestureInsetTop : %{public}ld",
       systemGestureInsetTop);
  int64_t systemGestureInsetRight;
  ret = napi_get_value_int64(env, args[13], &systemGestureInsetRight);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::systemGestureInsetRight : %{public}ld",
       systemGestureInsetRight);

  int64_t systemGestureInsetBottom;
  ret = napi_get_value_int64(env, args[14], &systemGestureInsetBottom);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::systemGestureInsetBottom : %{public}ld",
       systemGestureInsetBottom);
  int64_t systemGestureInsetLeft;
  ret = napi_get_value_int64(env, args[15], &systemGestureInsetLeft);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::systemGestureInsetLeft : %{public}ld",
       systemGestureInsetLeft);

  int64_t physicalTouchSlop;
  ret = napi_get_value_int64(env, args[16], &physicalTouchSlop);
  if (ret != napi_ok) {
    LOGE("nativeSetViewportMetrics napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetViewportMetrics::physicalTouchSlop : %{public}ld",
       physicalTouchSlop);

  std::vector<double> displayFeaturesBounds;
  napi_value array = args[17];
  uint32_t length;
  napi_get_array_length(env, array, &length);
  displayFeaturesBounds.resize(length);
  for (uint32_t i = 0; i < length; ++i) {
    napi_value element;
    napi_get_element(env, array, i, &element);
    napi_get_value_double(env, element, &(displayFeaturesBounds[i]));
  }

  LOGD("nativeSetViewportMetrics::displayFeaturesBounds");
  for (const uint64_t& bounds : displayFeaturesBounds) {
    LOGD(" %{public}ld", bounds);
  }

  std::vector<int64_t> displayFeaturesType;
  array = args[18];
  napi_get_array_length(env, array, &length);
  displayFeaturesType.resize(length);
  for (uint32_t i = 0; i < length; ++i) {
    napi_value element;
    napi_get_element(env, array, i, &element);
    napi_get_value_int64(env, element, &(displayFeaturesType[i]));
  }

  LOGD("nativeSetViewportMetrics::displayFeaturesType");
  for (const uint64_t& featuresType : displayFeaturesType) {
    LOGD(" %{public}ld", featuresType);
  }

  std::vector<int64_t> displayFeaturesState;
  array = args[19];
  napi_get_array_length(env, array, &length);
  displayFeaturesState.resize(length);
  for (uint32_t i = 0; i < length; ++i) {
    napi_value element;
    napi_get_element(env, array, i, &element);
    napi_get_value_int64(env, element, &(displayFeaturesState[i]));
  }

  LOGD("nativeSetViewportMetrics::displayFeaturesState");
  for (const uint64_t& featurestate : displayFeaturesState) {
    LOGD(" %{public}ld", featurestate);
  }

  const flutter::ViewportMetrics metrics{
      static_cast<double>(devicePixelRatio),
      static_cast<double>(physicalWidth),
      static_cast<double>(physicalHeight),
      static_cast<double>(physicalPaddingTop),
      static_cast<double>(physicalPaddingRight),
      static_cast<double>(physicalPaddingBottom),
      static_cast<double>(physicalPaddingLeft),
      static_cast<double>(physicalViewInsetTop),
      static_cast<double>(physicalViewInsetRight),
      static_cast<double>(physicalViewInsetBottom),
      static_cast<double>(physicalViewInsetLeft),
      static_cast<double>(systemGestureInsetTop),
      static_cast<double>(systemGestureInsetRight),
      static_cast<double>(systemGestureInsetBottom),
      static_cast<double>(systemGestureInsetLeft),
      static_cast<double>(physicalTouchSlop),
      displayFeaturesBounds,
      std::vector<int>(displayFeaturesType.begin(), displayFeaturesType.end()),
      std::vector<int>(displayFeaturesState.begin(),
                       displayFeaturesState.end()),
  };

  OHOS_SHELL_HOLDER->GetPlatformView()->SetViewportMetrics(metrics);

  return nullptr;
}

/**
 *  清除某个messageData
 */
napi_value PlatformViewOHOSNapi::nativeCleanupMessageData(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeCleanupMessageData");

  napi_status ret;
  size_t argc = 1;
  napi_value args[1] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeUpdateRefreshRate napi_get_cb_info error");
    return nullptr;
  }

  int64_t messageData;
  ret = napi_get_value_int64(env, args[0], &messageData);
  if (ret != napi_ok) {
    LOGE("nativeUpdateRefreshRate napi_get_value_int64 error");
    return nullptr;
  }

  LOGD("nativeCleanupMessageData  messageData: %{public}ld", messageData);
  free(reinterpret_cast<void*>(messageData));
  return nullptr;
}

/**
 *   设置刷新率
 */
napi_value PlatformViewOHOSNapi::nativeUpdateRefreshRate(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeUpdateRefreshRate");

  int64_t refreshRate;
  napi_status ret;
  size_t argc = 1;
  napi_value args[1] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeUpdateRefreshRate napi_get_cb_info error");
    return nullptr;
  }

  ret = napi_get_value_int64(env, args[0], &refreshRate);
  if (ret != napi_ok) {
    LOGE("nativeUpdateRefreshRate napi_get_value_int64 error");
    return nullptr;
  }

  LOGD("PlatformViewOHOSNapi::nativeUpdateRefreshRate: %{public}ld",
       refreshRate);
  FML_DCHECK(refreshRate > 0);
  VsyncWaiterOHOS::OnUpdateRefreshRate(refreshRate);
  return nullptr;
}

/**
 *  初始化SkFontMgr::RefDefault()，skia引擎文字管理初始化
 */
napi_value PlatformViewOHOSNapi::nativePrefetchDefaultFontManager(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativePrefetchDefaultFontManager");

  SkFontMgr::RefDefault();
  return nullptr;
}

/**
 *  返回是否支持软件绘制
 */
napi_value PlatformViewOHOSNapi::nativeGetIsSoftwareRenderingEnabled(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeGetIsSoftwareRenderingEnabled");
  napi_value result = nullptr;
  // TODO:  需要 FlutterMain 初始化
  napi_status ret = napi_get_boolean(
      env, OhosMain::Get().GetSettings().enable_software_rendering, &result);
  if (ret != napi_ok) {
    LOGE("nativeGetIsSoftwareRenderingEnabled napi_get_boolean error");
    return nullptr;
  }

  return result;
}

/**
 *  Detaches flutterNapi和engine之间的关联
 */
napi_value PlatformViewOHOSNapi::nativeDestroy(napi_env env,
                                               napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeDestroy");

  napi_status ret;
  size_t argc = 1;
  napi_value args[1] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeDestroy napi_get_cb_info error");
    return nullptr;
  }

  int64_t shell_holder;
  ret = napi_get_value_int64(env, args[0], &shell_holder);
  if (ret != napi_ok) {
    LOGE("nativeDestroy napi_get_value_int64 error");
    return nullptr;
  }

  LOGD("nativeDestroy shell_holder: %{public}ld", shell_holder);

  delete OHOS_SHELL_HOLDER;
  return nullptr;
}

/**
 *  设置能力参数
 */
napi_value PlatformViewOHOSNapi::nativeSetAccessibilityFeatures(
    napi_env env,
    napi_callback_info info) {
  LOGD("nativeSetAccessibilityFeatures");

  napi_status ret;
  size_t argc = 2;
  napi_value args[2] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeSetAccessibilityFeatures napi_get_cb_info error");
    return nullptr;
  }

  int64_t shell_holder;
  ret = napi_get_value_int64(env, args[0], &shell_holder);
  if (ret != napi_ok) {
    LOGE("nativeDestroy napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeSetAccessibilityFeatures shell_holder: %{public}ld",
       shell_holder);
  int64_t flags;
  ret = napi_get_value_int64(env, args[1], &flags);
  if (ret != napi_ok) {
    LOGE("nativeSetAccessibilityFeatures napi_get_value_int64 error");
    return nullptr;
  }
  LOGD(
      "PlatformViewOHOSNapi::nativeSetAccessibilityFeatures flags: %{public}ld",
      flags);
  OHOS_SHELL_HOLDER->GetPlatformView()->SetAccessibilityFeatures(flags);
  return nullptr;
}

/**
 * 加载动态库，或者dart库失败时的通知
 */
napi_value PlatformViewOHOSNapi::nativeDeferredComponentInstallFailure(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeDeferredComponentInstallFailure");

  napi_status ret;
  size_t argc = 3;
  napi_value args[3] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeDeferredComponentInstallFailure napi_get_cb_info error");
    return nullptr;
  }

  int64_t loadingUnitId;
  ret = napi_get_value_int64(env, args[0], &loadingUnitId);
  if (ret != napi_ok) {
    LOGE("nativeDeferredComponentInstallFailure napi_get_value_int64 error");
    return nullptr;
  }
  LOGD(
      "PlatformViewOHOSNapi::nativeSetAccessibilityFeatures loadingUnitId: "
      "%{public}ld",
      loadingUnitId);
  std::string error;
  if (fml::napi::SUCCESS != fml::napi::GetString(env, args[1], error)) {
    LOGE(
        "nativeDeferredComponentInstallFailure napi_get_value_string_utf8 "
        "error");
    return nullptr;
  }
  LOGD("nativeSetAccessibilityFeatures loadingUnitId: %s", error.c_str());

  bool isTransient;
  ret = napi_get_value_bool(env, args[2], &isTransient);
  if (ret != napi_ok) {
    LOGE("nativeDeferredComponentInstallFailure napi_get_value_bool error");
    return nullptr;
  }
  LOGD("nativeSetAccessibilityFeatures loadingUnitId: %{public}d", isTransient);

  LoadLoadingUnitFailure(static_cast<intptr_t>(loadingUnitId),
                         std::string(error), static_cast<bool>(isTransient));

  return nullptr;
}

/**
 * 应用低内存警告
 */
napi_value PlatformViewOHOSNapi::nativeNotifyLowMemoryWarning(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeNotifyLowMemoryWarning");

  napi_status ret;
  size_t argc = 1;
  napi_value args[1] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeNotifyLowMemoryWarning napi_get_cb_info error");
    return nullptr;
  }

  int64_t shell_holder;
  ret = napi_get_value_int64(env, args[0], &shell_holder);
  if (ret != napi_ok) {
    LOGE("nativeNotifyLowMemoryWarning napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeNotifyLowMemoryWarning shell_holder: %{public}ld", shell_holder);
  OHOS_SHELL_HOLDER->NotifyLowMemoryWarning();

  return nullptr;
}

// 下面的方法，从键盘输入中判断当前字符是否是emoji

/**
 *
 */
napi_value PlatformViewOHOSNapi::nativeFlutterTextUtilsIsEmoji(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeFlutterTextUtilsIsEmoji");
  napi_status ret;
  size_t argc = 1;
  napi_value args[1] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsEmoji napi_get_cb_info error");
    return nullptr;
  }

  int64_t codePoint;
  ret = napi_get_value_int64(env, args[0], &codePoint);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsEmoji napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeFlutterTextUtilsIsEmoji codePoint: %{public}ld ", codePoint);

  bool value = u_hasBinaryProperty(codePoint, UProperty::UCHAR_EMOJI);
  napi_value result = nullptr;
  ret = napi_get_boolean(env, value, &result);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsEmoji napi_get_boolean error");
    return nullptr;
  }

  return result;
}

/**
 *
 */
napi_value PlatformViewOHOSNapi::nativeFlutterTextUtilsIsEmojiModifier(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeFlutterTextUtilsIsEmojiModifier");

  napi_status ret;
  size_t argc = 1;
  napi_value args[1] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsEmojiModifier napi_get_cb_info error");
    return nullptr;
  }

  int64_t codePoint;
  ret = napi_get_value_int64(env, args[0], &codePoint);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsEmojiModifier napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeFlutterTextUtilsIsEmojiModifier codePoint: %{public}ld ",
       codePoint);

  bool value = u_hasBinaryProperty(codePoint, UProperty::UCHAR_EMOJI_MODIFIER);
  napi_value result = nullptr;
  ret = napi_get_boolean(env, value, &result);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsEmojiModifier napi_get_boolean error");
    return nullptr;
  }

  return result;
}

/**
 *
 */
napi_value PlatformViewOHOSNapi::nativeFlutterTextUtilsIsEmojiModifierBase(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeFlutterTextUtilsIsEmojiModifierBase");

  napi_status ret;
  size_t argc = 1;
  napi_value args[1] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsEmojiModifierBase napi_get_cb_info error");
    return nullptr;
  }

  int64_t codePoint;
  ret = napi_get_value_int64(env, args[0], &codePoint);
  if (ret != napi_ok) {
    LOGE(
        "nativeFlutterTextUtilsIsEmojiModifierBase napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeFlutterTextUtilsIsEmojiModifierBase codePoint: %{public}ld ",
       codePoint);

  bool value =
      u_hasBinaryProperty(codePoint, UProperty::UCHAR_EMOJI_MODIFIER_BASE);
  napi_value result = nullptr;
  ret = napi_get_boolean(env, value, &result);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsEmojiModifierBase napi_get_boolean error");
    return nullptr;
  }

  return result;
}

/**
 *
 */
napi_value PlatformViewOHOSNapi::nativeFlutterTextUtilsIsVariationSelector(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeFlutterTextUtilsIsVariationSelector");

  napi_status ret;
  size_t argc = 1;
  napi_value args[1] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsVariationSelector napi_get_cb_info error");
    return nullptr;
  }

  int64_t codePoint;
  ret = napi_get_value_int64(env, args[0], &codePoint);
  if (ret != napi_ok) {
    LOGE(
        "nativeFlutterTextUtilsIsVariationSelector napi_get_value_int64 error");
    return nullptr;
  }
  LOGD("nativeFlutterTextUtilsIsVariationSelector codePoint: %{public}ld ",
       codePoint);

  bool value =
      u_hasBinaryProperty(codePoint, UProperty::UCHAR_VARIATION_SELECTOR);
  napi_value result = nullptr;
  ret = napi_get_boolean(env, value, &result);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsVariationSelector napi_get_boolean error");
    return nullptr;
  }

  return result;
}

/**
 *
 */
napi_value PlatformViewOHOSNapi::nativeFlutterTextUtilsIsRegionalIndicator(
    napi_env env,
    napi_callback_info info) {
  LOGD("PlatformViewOHOSNapi::nativeFlutterTextUtilsIsRegionalIndicator");

  napi_status ret;
  size_t argc = 1;
  napi_value args[1] = {nullptr};
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsRegionalIndicator napi_get_cb_info error");
    return nullptr;
  }

  int64_t codePoint;
  ret = napi_get_value_int64(env, args[0], &codePoint);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsRegionalIndicator napi_get_value_int64 fail");
    return nullptr;
  }
  LOGD("nativeFlutterTextUtilsIsRegionalIndicator codePoint: %{public}ld ",
       codePoint);

  bool value =
      u_hasBinaryProperty(codePoint, UProperty::UCHAR_REGIONAL_INDICATOR);
  napi_value result = nullptr;
  ret = napi_get_boolean(env, value, &result);
  if (ret != napi_ok) {
    LOGE("nativeFlutterTextUtilsIsRegionalIndicator napi_get_boolean error");
    return nullptr;
  }

  return result;
}

/**
 * @brief   ArkTS下发系统语言设置列表
 * @note
 * @param  nativeShellHolderId: number
 * @param  systemLanguages: Array<string>
 * @return void
 */
napi_value PlatformViewOHOSNapi::nativeGetSystemLanguages(
    napi_env env,
    napi_callback_info info) {
  napi_status ret;
  size_t argc = 2;
  napi_value args[2] = {nullptr};
  int64_t shell_holder;
  std::vector<std::string> local_languages;
  ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
  if (ret != napi_ok) {
    FML_DLOG(ERROR) << "nativeGetSystemLanguages napi_get_cb_info error:"
                    << ret;
    return nullptr;
  }
  ret = napi_get_value_int64(env, args[0], &shell_holder);
  if (ret != napi_ok) {
    FML_DLOG(ERROR) << "nativeGetSystemLanguages napi_get_value_int64 error";
    return nullptr;
  }
  if (fml::napi::SUCCESS !=
      fml::napi::GetArrayString(env, args[1], local_languages)) {
    FML_DLOG(ERROR) << "nativeGetSystemLanguages GetArrayString error";
    return nullptr;
  }
  system_languages = local_languages;
  return nullptr;
}

void PlatformViewOHOSNapi::SurfaceCreated(int64_t shell_holder, void* window) {
  auto native_window = fml::MakeRefCounted<OHOSNativeWindow>(
      static_cast<OHNativeWindow*>(window));
  OHOS_SHELL_HOLDER->GetPlatformView()->NotifyCreate(std::move(native_window));
}

void PlatformViewOHOSNapi::SurfaceChanged(int64_t shell_holder,
                                          int32_t width,
                                          int32_t height) {
  OHOS_SHELL_HOLDER->GetPlatformView()->NotifyChanged(
      SkISize::Make(width, height));
}

void PlatformViewOHOSNapi::SurfaceDestroyed(int64_t shell_holder) {
  OHOS_SHELL_HOLDER->GetPlatformView()->NotifyDestroyed();
}

void PlatformViewOHOSNapi::SetPlatformTaskRunner(
    fml::RefPtr<fml::TaskRunner> platform_task_runner) {
  platform_task_runner_ = platform_task_runner;
}

/**
 * @brief   xcomponent与flutter引擎绑定
 * @note
 * @param  nativeShellHolderId: number
 * @param  xcomponentId: number
 * @return void
 */
napi_value PlatformViewOHOSNapi::nativeXComponentAttachFlutterEngine(
    napi_env env,
    napi_callback_info info){
    napi_status ret;
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    int64_t xcomponent_id;
    int64_t shell_holder;
    ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (ret != napi_ok) {
        FML_DLOG(ERROR) << "nativeXComponentAttachFlutterEngine napi_get_cb_info error:"
                        << ret;
        return nullptr;
    }
    ret = napi_get_value_int64(env, args[0], &xcomponent_id);
    if (ret != napi_ok) {
        FML_DLOG(ERROR) << "nativeXComponentAttachFlutterEngine xcomponent_id napi_get_value_int64 error";
        return nullptr;
    }
    ret = napi_get_value_int64(env, args[1], &shell_holder);
    if (ret != napi_ok) {
        FML_DLOG(ERROR) << "nativeXComponentAttachFlutterEngine shell_holder napi_get_value_int64 error";
        return nullptr;
    }
    std::string xcomponent_id_str = std::to_string(xcomponent_id);
    std::string shell_holder_str = std::to_string(shell_holder);

    LOGD("nativeXComponentAttachFlutterEngine xcomponent_id: %{public}ld , shell_holder: %{public}ld ",
         xcomponent_id, shell_holder);

    XComponentAdapter::GetInstance()->AttachFlutterEngine(xcomponent_id_str,
                                                          shell_holder_str);
    return nullptr;
}
/**
 * @brief xcomponent解除flutter引擎绑定
 * @note
 * @param  nativeShellHolderId: number
 * @param  xcomponentId: number
 * @return napi_value
 */
napi_value PlatformViewOHOSNapi::nativeXComponentDetachFlutterEngine(
    napi_env env,
    napi_callback_info info){
    napi_status ret;
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    int64_t xcomponent_id;
    int64_t shell_holder;
    ret = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (ret != napi_ok) {
        FML_DLOG(ERROR) << "nativeXComponentAttachFlutterEngine napi_get_cb_info error:"
                        << ret;
        return nullptr;
    }
    ret = napi_get_value_int64(env, args[0], &xcomponent_id);
    if (ret != napi_ok) {
        FML_DLOG(ERROR) << "nativeXComponentAttachFlutterEngine xcomponent_id napi_get_value_int64 error";
        return nullptr;
    }
    ret = napi_get_value_int64(env, args[1], &shell_holder);
    if (ret != napi_ok) {
        FML_DLOG(ERROR) << "nativeXComponentAttachFlutterEngine shell_holder napi_get_value_int64 error";
        return nullptr;
    }
    std::string xcomponent_id_str = std::to_string(xcomponent_id);

    LOGD("nativeXComponentDetachFlutterEngine xcomponent_id: %{public}ld",
         xcomponent_id);
    XComponentAdapter::GetInstance()->DetachFlutterEngine(xcomponent_id_str);
    return nullptr;
}

}  // namespace flutter
