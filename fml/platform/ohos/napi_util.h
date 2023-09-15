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

#ifndef OHOS_FLUTTER_NAPI_UTIL_H
#define OHOS_FLUTTER_NAPI_UTIL_H
#include <string.h>
#include <uv.h>
#include <string>
#include <vector>
#include "flutter/fml/logging.h"
#include "napi/native_api.h"

namespace fml {
namespace napi {
enum {
  SUCCESS = 0,
  ERROR_TYPE = -100,
  ERROR_NULL,
};
const int32_t STRING_MAX_LENGTH = 512;
int32_t GetString(napi_env env, napi_value arg, std::string& strValue);
int32_t GetArrayString(napi_env env,
                       napi_value arg,
                       std::vector<std::string>& arrayString);
int32_t GetArrayBuffer(napi_env env,
                       napi_value arg,
                       void** message,
                       size_t* lenth);

/**
 *  打印napi_value @args 的类型信息
 */
void NapiPrintValueTypes(napi_env env, int argc, napi_value* argv);
/**
 *  打印napi_value @cur 的类型信息
 */
void NapiPrintValueType(napi_env env, napi_value cur);

/**
 * 判断napi value  类型
 */
bool NapiIsType(napi_env env, napi_value value, napi_valuetype type);
bool NapiIsNotType(napi_env env, napi_value value, napi_valuetype type);
/**
 * 判断napi value类型是否是其中的一种
 */
bool NapiIsAnyType(napi_env env, napi_value value, ...);
/**
 * 判断值是否为空
 */
bool NapiIsNull(napi_env env, napi_value value);

/**
 * 创建ArrayBuffer
 */
napi_value CreateArrayBuffer(napi_env env, void* inputData, size_t dataSize);

/**
 * 回调JS方法
 */
napi_status InvokeJsMethod(napi_env env_,
                           napi_ref ref_napi_obj_,
                           const char* methodName,
                           size_t argc,
                           const napi_value* argv);
}  // namespace napi
}  // namespace fml
#endif
