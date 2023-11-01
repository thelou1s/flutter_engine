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

#include "flutter/fml/platform/ohos/napi_util.h"
#include <node_api.h>
#include <cstdarg>
#include <string>

namespace fml {
namespace napi {

bool NapiIsNull(napi_env env, napi_value value) {
  return value == nullptr || NapiIsType(env, value, napi_null);
}
bool NapiIsNotType(napi_env env, napi_value value, napi_valuetype type) {
  return !NapiIsType(env, value, type);
}
std::string NapiGetLastError(napi_env env, napi_status status) {
  std::string ret("Napi Error:");
  ret += status;

  const napi_extended_error_info* error_info;
  napi_get_last_error_info(env, &error_info);
  ret += error_info->error_message;
  return ret;
}
bool NapiIsType(napi_env env, napi_value value, napi_valuetype type) {
  napi_status status;
  napi_valuetype argType;
  status = napi_typeof(env, value, &argType);
  return status == napi_ok && type == argType;
}
bool NapiIsAnyType(napi_env env, napi_value value, ...) {
  napi_status status;
  napi_valuetype argType;
  status = napi_typeof(env, value, &argType);

  if (status != napi_ok) {
    return false;
  }

  bool matched = false;
  {
    va_list types;
    va_start(types, value);
    napi_valuetype cur;
    while (!matched) {
      cur = va_arg(types, napi_valuetype);
      matched = (cur == argType);
    }
    va_end(types);
  }
  return matched;
}
void NapiPrintValueTypes(napi_env env, int argc, napi_value* args) {
  FML_DLOG(INFO) << "argc: " << argc;
  for (int i = 0; i < argc; i++) {
    napi_value cur = args[i];
    FML_DLOG(INFO) << "arg: " << i << ",null?" << (cur == nullptr);
    if (cur != nullptr) {
      NapiPrintValueType(env, cur);
    }
  }
}

bool IsArrayBuffer(napi_env env, napi_value value) {
  napi_status status;
  bool result;

  // Check if the value is an ArrayBuffer
  status = napi_is_arraybuffer(env, value, &result);
  if (status != napi_ok) {
    FML_DLOG(INFO) << "napi_is_arraybuffer: failed:" << status;
    return false;
  }

  // If it's not an ArrayBuffer, check if it's an Array
  if (!result) {
    status = napi_is_array(env, value, &result);
    if (status != napi_ok) {
      FML_DLOG(INFO) << "napi_is_array: failed:"
                     << NapiGetLastError(env, status);
      return false;
    }
  }
  return true;
}

void NapiPrintValueType(napi_env env, napi_value cur) {
  napi_status status;
  napi_valuetype argType;
  int i = 0;
  status = napi_typeof(env, cur, &argType);
  if (status != napi_ok) {
    FML_DLOG(INFO) << "args,gettype: failed:" << status;
    return;
  }
  if (argType == napi_number) {
    FML_DLOG(INFO) << "args,type: " << argType << " number";
  } else if (argType == napi_string) {
    FML_DLOG(INFO) << "args[" << i << "],type: " << argType << " napi_string";
  } else if (argType == napi_boolean) {
    FML_DLOG(INFO) << "args[" << i << "],type: " << argType << " napi_boolean ";
  } else if (argType == napi_object) {
    FML_DLOG(INFO) << "args[" << i << "],type: " << argType << " napi_object";
  } else if (argType == napi_function) {
    FML_DLOG(INFO) << "args[" << i << "],type: " << argType << " napi_function";
  } else if (argType == napi_null) {
    FML_DLOG(INFO) << "args[" << i << "],type: " << argType << " napi_null ";
  } else if (argType == napi_symbol) {
    FML_DLOG(INFO) << "args[" << i << "],type: " << argType << " napi_symbol";
  } else if (argType == napi_external) {
    FML_DLOG(INFO) << "args[" << i << "],type: " << argType << " napi_external";
  } else if (argType == napi_bigint) {
    FML_DLOG(INFO) << "args[" << i << "],type: " << argType << " napi_bigint";
  } else {
    FML_DLOG(INFO) << "args[" << i << "],type: " << argType << " number";
  }
  bool ok = false;
  napi_is_array(env, cur, &ok);
  if (ok) {
    FML_DLOG(INFO) << "args[" << i << "],type: " << argType << " is_array ";
  }
  if (IsArrayBuffer(env, cur)) {
    FML_DLOG(INFO) << "args[" << i << "],type: " << argType
                   << " is_arraybuffer ";
  }
  napi_is_typedarray(env, cur, &ok);
  if (ok) {
    FML_DLOG(INFO) << "args[" << i << "],type: " << argType << " is_typearray";
  }
}

int32_t GetString(napi_env env, napi_value arg, std::string& strValue) {
  napi_status status;

  if (NapiIsType(env, arg, napi_null)) {
    FML_DLOG(INFO) << "napi_null";
    strValue = "";
    return SUCCESS;
  }
  if (!NapiIsType(env, arg, napi_string)) {
    FML_DLOG(ERROR) << "Invalid type:";
    return ERROR_TYPE;
  }

  std::vector<char> buff(STRING_MAX_LENGTH);
  size_t copy_lenth;
  status = napi_get_value_string_utf8(env, arg, static_cast<char*>(buff.data()),
                                      STRING_MAX_LENGTH, &copy_lenth);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "Error get string:" << status;
    FML_DLOG(ERROR) << "result size:" << copy_lenth;
    return status;
  }
  strValue.assign(buff.data(), copy_lenth);
  return SUCCESS;
}

int32_t GetArrayString(napi_env env,
                       napi_value arg,
                       std::vector<std::string>& arrayString) {
  uint32_t arrayLenth;
  napi_status status = napi_get_array_length(env, arg, &arrayLenth);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "Failed to napi_get_array_length:" << status;
    return status;
  }
  FML_DLOG(INFO) << "GetArrayString length:" << arrayLenth;
  for (uint32_t i = 0; i < arrayLenth; i++) {
    napi_value element;
    napi_get_element(env, arg, i, &element);
    std::string str;
    GetString(env, element, str);
    arrayString.push_back(str);
  }
  return SUCCESS;
}
int32_t GetArrayBuffer(napi_env env,
                       napi_value arg,
                       void** message,
                       size_t* lenth) {
  napi_status status;
  if (NapiIsType(env, arg, napi_null)) {
    FML_DLOG(ERROR) << "GetArrayBuffer value is null :";
    return ERROR_NULL;
  }

  if (!IsArrayBuffer(env, arg)) {
    NapiPrintValueType(env, arg);
    return napi_invalid_arg;
  }

  status = napi_get_arraybuffer_info(env, arg, message, lenth);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "napi_get_arraybuffer_info "
                    << NapiGetLastError(env, status);
    return status;
  }
  if (*message == nullptr) {
    return ERROR_NULL;
  }

  return SUCCESS;
}

napi_value CreateArrayBuffer(napi_env env, void* inputData, size_t dataSize) {
  void* data = nullptr;
  napi_value arrayBuffer = nullptr;
  napi_value result = nullptr;
  if (inputData == nullptr) {
    return nullptr;
  }
  napi_status status =
      napi_create_arraybuffer(env, dataSize, &data, &arrayBuffer);
  if (status) {
    FML_DLOG(ERROR) << "napi_create_arraybuffer error:" << status;
    return result;
  }
  memcpy(data, inputData, dataSize);
  return arrayBuffer;
}

napi_status InvokeJsMethod(napi_env env_,
                           napi_ref ref_napi_obj_,
                           const char* methodName,
                           size_t argc,
                           const napi_value* argv) {
  napi_value fn, napi_obj, ret;
  napi_status status;
  status = napi_get_reference_value(env_, ref_napi_obj_, &napi_obj);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "napi_get_reference_value fail ";
    return status;
  }

  status = napi_get_named_property(env_, napi_obj, methodName, &fn);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "napi_get_named_property fail " << methodName;
    return status;
  }
  status = napi_call_function(env_, napi_obj, fn, argc, argv, &ret);
  if (status != napi_ok) {
    FML_DLOG(ERROR) << "napi_call_function fail " << methodName;
    return status;
  }
  return napi_ok;
}

}  // end namespace napi
}  // end namespace fml
