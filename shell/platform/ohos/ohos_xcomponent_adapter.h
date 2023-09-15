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

namespace flutter {

class XComponentAdapter {
 public:
  XComponentAdapter(/* args */);
  ~XComponentAdapter();
  static XComponentAdapter* GetInstance();
  bool Export(napi_env env, napi_value exports);
  OH_NativeXComponent* GetNativeXComponent(std::string& id);
  void SetNativeXComponent(std::string& id,
                           OH_NativeXComponent* nativeXComponent);
  OH_NativeXComponent_Callback* GetNXComponentCallback();

  // Callback, called by ACE XComponent
  void OnSurfaceCreated(OH_NativeXComponent* component, void* window);
  void OnSurfaceChanged(OH_NativeXComponent* component, void* window);
  void OnSurfaceDestroyed(OH_NativeXComponent* component, void* window);
  void DispatchTouchEvent(OH_NativeXComponent* component, void* window);

  void BindXComponentCallback();
  void PackPointerDataAndDispatch(
      const OH_NativeXComponent_TouchEvent touchEvent);

 public:
  static OH_NativeXComponent_Callback callback_;
  std::string id_;
  uint64_t width_;
  uint64_t height_;
  OH_NativeXComponent_TouchEvent touchEvent_;

 private:
  static XComponentAdapter mXComponentAdapter;
  OH_NativeXComponent* nativeXComponent_;
  int64_t shell_holder;
  OhosTouchProcessor ohosTouchProcessor_;
};

}  // namespace flutter

#endif
