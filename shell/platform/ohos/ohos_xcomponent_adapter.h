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

#ifndef OHOS_XCOMPONENT_ADAPTER_H
#define OHOS_XCOMPONENT_ADAPTER_H
#include <ace/xcomponent/native_interface_xcomponent.h>
#include <string>
#include "flutter/shell/platform/ohos/ohos_touch_processor.h"
#include "napi/native_api.h"
#include "napi_common.h"
#include <map>
namespace flutter {

class XComponentBase
{
private:
  void BindXComponentCallback();
  
public:
  XComponentBase(std::string id);
  ~XComponentBase();

  void AttachFlutterEngine(std::string shellholderId);
  void DetachFlutterEngine();
  void SetNativeXComponent(OH_NativeXComponent* nativeXComponent);

  // Callback, called by ACE XComponent
  void OnSurfaceCreated(OH_NativeXComponent* component, void* window);
  void OnSurfaceChanged(OH_NativeXComponent* component, void* window);
  void OnSurfaceDestroyed(OH_NativeXComponent* component, void* window);
  void OnDispatchTouchEvent(OH_NativeXComponent* component, void* window);

  OH_NativeXComponent_TouchEvent touchEvent_;
  OH_NativeXComponent_Callback callback_;
  std::string id_;
  std::string shellholderId_;
  bool isEngineAttached_;
  bool isWindowAttached_;
  OH_NativeXComponent* nativeXComponent_;
  void* window_;
  uint64_t width_;
  uint64_t height_;
  OhosTouchProcessor ohosTouchProcessor_;

};

class XComponentAdapter {
 public:
  XComponentAdapter(/* args */);
  ~XComponentAdapter();
  static XComponentAdapter* GetInstance();
  bool Export(napi_env env, napi_value exports);
  void SetNativeXComponent(std::string& id,
                           OH_NativeXComponent* nativeXComponent);
  void AttachFlutterEngine(std::string& id, std::string& shellholderId);
  void DetachFlutterEngine(std::string& id);

 public:
  std::map<std::string, XComponentBase*> xcomponetMap_;

 private:
  static XComponentAdapter mXComponentAdapter;
};

}  // namespace flutter

#endif