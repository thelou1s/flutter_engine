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

#include "ohos_xcomponent_adapter.h"
#include "flutter/shell/platform/ohos/napi/platform_view_ohos_napi.h"
#include "types.h"
#include <functional>
namespace flutter {

XComponentAdapter XComponentAdapter::mXComponentAdapter;

XComponentAdapter::XComponentAdapter(/* args */) {}

XComponentAdapter::~XComponentAdapter() {}

XComponentAdapter* XComponentAdapter::GetInstance() {
  return &XComponentAdapter::mXComponentAdapter;
}

bool XComponentAdapter::Export(napi_env env, napi_value exports) {
  napi_status status;
  napi_value exportInstance = nullptr;
  OH_NativeXComponent* nativeXComponent = nullptr;
  int32_t ret;
  char idStr[OH_XCOMPONENT_ID_LEN_MAX + 1] = {};
  uint64_t idSize = OH_XCOMPONENT_ID_LEN_MAX + 1;

  status = napi_get_named_property(env, exports, OH_NATIVE_XCOMPONENT_OBJ,
                                   &exportInstance);
  LOGD("napi_get_named_property,status = %{public}d", status);
  if (status != napi_ok) {
    return false;
  }

  status = napi_unwrap(env, exportInstance,
                       reinterpret_cast<void**>(&nativeXComponent));
  LOGD("napi_unwrap,status = %{public}d", status);
  if (status != napi_ok) {
    return false;
  }

  ret = OH_NativeXComponent_GetXComponentId(nativeXComponent, idStr, &idSize);
  LOGD("NativeXComponent id:%{public}s", idStr);
  if (ret != OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
    return false;
  }
  std::string id(idStr);
  auto context = XComponentAdapter::GetInstance();
  if (context) {
    context->SetNativeXComponent(id, nativeXComponent);
    return true;
  }

  return false;
}

void XComponentAdapter::SetNativeXComponent(
    std::string& id,
    OH_NativeXComponent* nativeXComponent) {
  auto iter = xcomponetMap_.find(id);
  if (iter == xcomponetMap_.end()) {
    XComponentBase* xcomponet = new XComponentBase(id);
    xcomponetMap_[id] = xcomponet;
  }

  iter = xcomponetMap_.find(id);
  if (iter != xcomponetMap_.end()) {
    iter->second->SetNativeXComponent(nativeXComponent);
  }
}

void XComponentAdapter::AttachFlutterEngine(std::string& id,
                                            std::string& shellholderId) {
  auto iter = xcomponetMap_.find(id);
  if (iter == xcomponetMap_.end()) {
    XComponentBase* xcomponet = new XComponentBase(id);
    xcomponetMap_[id] = xcomponet;
  }

  auto findIter = xcomponetMap_.find(id);
  if (findIter != xcomponetMap_.end()) {
    findIter->second->AttachFlutterEngine(shellholderId);
  }
}

void XComponentAdapter::DetachFlutterEngine(std::string& id) {
  auto iter = xcomponetMap_.find(id);
  if (iter != xcomponetMap_.end()) {
    iter->second->DetachFlutterEngine();
  }
}

#include <native_window/external_window.h>
using OHOS_SurfaceBufferUsage = enum {
  BUFFER_USAGE_CPU_READ = (1ULL << 0),  /**< CPU read buffer */
  BUFFER_USAGE_CPU_WRITE = (1ULL << 1), /**< CPU write memory */
  BUFFER_USAGE_MEM_MMZ = (1ULL << 2),   /**< Media memory zone (MMZ) */
  BUFFER_USAGE_MEM_DMA = (1ULL << 3), /**< Direct memory access (DMA) buffer */
  BUFFER_USAGE_MEM_SHARE = (1ULL << 4),     /**< Shared memory buffer*/
  BUFFER_USAGE_MEM_MMZ_CACHE = (1ULL << 5), /**< MMZ with cache*/
  BUFFER_USAGE_MEM_FB = (1ULL << 6),        /**< Framebuffer */
  BUFFER_USAGE_ASSIGN_SIZE = (1ULL << 7),   /**< Memory assigned */
  BUFFER_USAGE_HW_RENDER = (1ULL << 8),     /**< For GPU write case */
  BUFFER_USAGE_HW_TEXTURE = (1ULL << 9),    /**< For GPU read case */
  BUFFER_USAGE_HW_COMPOSER = (1ULL << 10),  /**< For hardware composer */
  BUFFER_USAGE_PROTECTED =
      (1ULL << 11), /**< For safe buffer case, such as DRM */
  BUFFER_USAGE_CAMERA_READ = (1ULL << 12),   /**< For camera read case */
  BUFFER_USAGE_CAMERA_WRITE = (1ULL << 13),  /**< For camera write case */
  BUFFER_USAGE_VIDEO_ENCODER = (1ULL << 14), /**< For encode case */
  BUFFER_USAGE_VIDEO_DECODER = (1ULL << 15), /**< For decode case */
  BUFFER_USAGE_VENDOR_PRI0 = (1ULL << 44),   /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI1 = (1ULL << 45),   /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI2 = (1ULL << 46),   /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI3 = (1ULL << 47),   /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI4 = (1ULL << 48),   /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI5 = (1ULL << 49),   /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI6 = (1ULL << 50),   /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI7 = (1ULL << 51),   /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI8 = (1ULL << 52),   /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI9 = (1ULL << 53),   /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI10 = (1ULL << 54),  /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI11 = (1ULL << 55),  /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI12 = (1ULL << 56),  /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI13 = (1ULL << 57),  /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI14 = (1ULL << 58),  /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI15 = (1ULL << 59),  /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI16 = (1ULL << 60),  /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI17 = (1ULL << 61),  /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI18 = (1ULL << 62),  /**< Reserverd for vendor */
  BUFFER_USAGE_VENDOR_PRI19 = (1ULL << 63),  /**< Reserverd for vendor */
};
static int32_t SetNativeWindowOpt(OHNativeWindow* nativeWindow,
                                  int32_t width,
                                  int height) {
  // Set the read and write scenarios of the native window buffer.
  int code = SET_USAGE;
  int32_t usage =
      BUFFER_USAGE_CPU_READ | BUFFER_USAGE_CPU_WRITE | BUFFER_USAGE_MEM_DMA;
  int32_t ret =
      OH_NativeWindow_NativeWindowHandleOpt(nativeWindow, code, usage);
  if (ret) {
    LOGE(
        "Set NativeWindow Usage Failed :window:%{public}p ,w:%{public}d x "
        "%{public}d:%{public}d",
        nativeWindow, width, height, ret);
  }
  // Set the width and height of the native window buffer.
  code = SET_BUFFER_GEOMETRY;
  ret =
      OH_NativeWindow_NativeWindowHandleOpt(nativeWindow, code, width, height);
  if (ret) {
    LOGE(
        "Set NativeWindow GEOMETRY  Failed :window:%{public}p ,w:%{public}d x "
        "%{public}d:%{public}d",
        nativeWindow, width, height, ret);
  }
  // Set the step of the native window buffer.
  code = SET_STRIDE;
  int32_t stride = 0x8;
  ret = OH_NativeWindow_NativeWindowHandleOpt(nativeWindow, code, stride);
  if (ret) {
    LOGE(
        "Set NativeWindow stride   Failed :window:%{public}p ,w:%{public}d x "
        "%{public}d:%{public}d",
        nativeWindow, width, height, ret);
  }
  // Set the format of the native window buffer.
  code = SET_FORMAT;
  int32_t format = PIXEL_FMT_RGBA_8888;

  ret = OH_NativeWindow_NativeWindowHandleOpt(nativeWindow, code, format);
  if (ret) {
    LOGE(
        "Set NativeWindow PIXEL_FMT_RGBA_8888   Failed :window:%{public}p "
        ",w:%{public}d x %{public}d:%{public}d",
        nativeWindow, width, height, ret);
  }
  return ret;
}

void OnSurfaceCreatedCB(OH_NativeXComponent* component, void* window) {
  for(auto it: XComponentAdapter::GetInstance()->xcomponetMap_)
  {
    if(it.second->nativeXComponent_ == component) {
      it.second->OnSurfaceCreated(component, window);
    }
  }
}

void OnSurfaceChangedCB(OH_NativeXComponent* component, void* window) {
  for(auto it: XComponentAdapter::GetInstance()->xcomponetMap_)
  {
    if(it.second->nativeXComponent_ == component) {
      it.second->OnSurfaceChanged(component, window);
    }
  }
}

void OnSurfaceDestroyedCB(OH_NativeXComponent* component, void* window) {
  for(auto it = XComponentAdapter::GetInstance()->xcomponetMap_.begin(); 
    it != XComponentAdapter::GetInstance()->xcomponetMap_.end();)
  {
    if(it->second->nativeXComponent_ == component) {
      it->second->OnSurfaceDestroyed(component, window);
      delete it->second;
      it = XComponentAdapter::GetInstance()->xcomponetMap_.erase(it);
    } else {
      ++it;
    }
  }

}
void DispatchTouchEventCB(OH_NativeXComponent* component, void* window) {
  for(auto it: XComponentAdapter::GetInstance()->xcomponetMap_)
  {
    if(it.second->nativeXComponent_ == component) {
      it.second->OnDispatchTouchEvent(component, window);
    }
  }
}

void XComponentBase::BindXComponentCallback() {
  callback_.OnSurfaceCreated = OnSurfaceCreatedCB;
  callback_.OnSurfaceChanged = OnSurfaceChangedCB;
  callback_.OnSurfaceDestroyed = OnSurfaceDestroyedCB;
  callback_.DispatchTouchEvent = DispatchTouchEventCB;
}

XComponentBase::XComponentBase(std::string id){
  id_ = id;
  isEngineAttached_ = false;
}

XComponentBase::~XComponentBase() {}

void XComponentBase::AttachFlutterEngine(std::string shellholderId) {
  LOGD(
      "XComponentManger::AttachFlutterEngine xcomponentId:%{public}s, "
      "shellholderId:%{public}s",
      id_.c_str(), shellholderId.c_str());
  shellholderId_ = shellholderId;
  isEngineAttached_ = true;
  if (window_ != nullptr) {
    PlatformViewOHOSNapi::SurfaceCreated(std::stoll(shellholderId_), window_);
  } else {
    LOGE("OnSurfaceCreated XComponentBase is not attached");
  }
}

void XComponentBase::DetachFlutterEngine() {
  LOGD(
      "XComponentManger::DetachFlutterEngine xcomponentId:%{public}s, "
      "shellholderId:%{public}s",
      id_.c_str(), shellholderId_.c_str());
  if (window_ != nullptr) {
    PlatformViewOHOSNapi::SurfaceDestroyed(std::stoll(shellholderId_));
  } else {
    LOGE("DetachFlutterEngine XComponentBase is not attached");
  }
  shellholderId_ = "";
  isEngineAttached_ = false;
}

void XComponentBase::SetNativeXComponent(OH_NativeXComponent* nativeXComponent){
  nativeXComponent_ = nativeXComponent;
  if (nativeXComponent_ != nullptr) {
    BindXComponentCallback();
    OH_NativeXComponent_RegisterCallback(nativeXComponent_, &callback_);
  }
}

void XComponentBase::OnSurfaceCreated(OH_NativeXComponent* component,
                                      void* window) {
  LOGD(
      "XComponentManger::OnSurfaceCreated window = %{public}p component = "
      "%{public}p",
      window, component);
      window_ = window;
  int32_t ret = OH_NativeXComponent_GetXComponentSize(component, window,
                                                      &width_, &height_);
  if (ret == OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
    LOGD("XComponent Current width:%{public}d,height:%{public}d",
         static_cast<int>(width_), static_cast<int>(height_));
  } else {
    LOGE("GetXComponentSize result:%{public}d", ret);
  }

  LOGD("OnSurfaceCreated,window.size:%{public}d,%{public}d", (int)width_,
       (int)height_);
  ret = SetNativeWindowOpt((OHNativeWindow*)window, width_, height_);
  if (ret) {
    LOGD("SetNativeWindowOpt failed:%{public}d", ret);
  }
  if (isEngineAttached_) {
    PlatformViewOHOSNapi::SurfaceCreated(std::stoll(shellholderId_), window);
  } else {
    LOGE("OnSurfaceCreated XComponentBase is not attached");
  }
}

void XComponentBase::OnSurfaceChanged(OH_NativeXComponent* component, void* window)
{
  LOGD("XComponentManger::OnSurfaceChanged ");
  int32_t ret = OH_NativeXComponent_GetXComponentSize(component, window,
                                                      &width_, &height_);
  if (ret == OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
    LOGD("XComponent Current width:%{public}d,height:%{public}d",
         static_cast<int>(width_), static_cast<int>(height_));
  }
  if (isEngineAttached_) {
    PlatformViewOHOSNapi::SurfaceChanged(std::stoll(shellholderId_), width_,
                                         height_);
  } else {
    LOGE("OnSurfaceChanged XComponentBase is not attached");
  }
}

void XComponentBase::OnSurfaceDestroyed(OH_NativeXComponent* component,
                                        void* window) {
  window_ = nullptr;
  LOGD("XComponentManger::OnSurfaceDestroyed");
  if (isEngineAttached_) {
    PlatformViewOHOSNapi::SurfaceDestroyed(std::stoll(shellholderId_));
  } else {
    LOGE("OnSurfaceCreated OnSurfaceDestroyed is not attached");
  }
}

void XComponentBase::OnDispatchTouchEvent(OH_NativeXComponent* component,
                                          void* window) {
  LOGD("XComponentManger::DispatchTouchEvent");
  int32_t ret =
      OH_NativeXComponent_GetTouchEvent(component, window, &touchEvent_);
  if (ret == OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
    if (isEngineAttached_) {
       LOGD("XComponentManger::HandleTouchEvent");
      ohosTouchProcessor_.HandleTouchEvent(std::stoll(shellholderId_),
                                           component, &touchEvent_);
    } else {
      LOGE(
          "XComponentManger::DispatchTouchEvent XComponentBase is not "
          "attached");
    }
  }
}

}  // namespace flutter