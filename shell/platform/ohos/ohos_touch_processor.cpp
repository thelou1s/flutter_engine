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

#include "flutter/shell/platform/ohos/ohos_touch_processor.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "flutter/shell/platform/ohos/ohos_shell_holder.h"

namespace flutter {

constexpr int MSEC_PER_SECOND = 1000;

PointerData::Change OhosTouchProcessor::getPointerChangeForAction(
    int maskedAction) {
  switch (maskedAction) {
    case OH_NATIVEXCOMPONENT_DOWN:
      return PointerData::Change::kDown;
    case OH_NATIVEXCOMPONENT_UP:
      return PointerData::Change::kUp;
    case OH_NATIVEXCOMPONENT_CANCEL:
      return PointerData::Change::kCancel;
    case OH_NATIVEXCOMPONENT_MOVE:
      return PointerData::Change::kMove;
  }
  return PointerData::Change::kCancel;
}

PointerData::DeviceKind OhosTouchProcessor::getPointerDeviceTypeForToolType(
    int toolType) {
  switch (toolType) {
    case OH_NATIVEXCOMPONENT_TOOL_TYPE_FINGER:
      return PointerData::DeviceKind::kTouch;
    case OH_NATIVEXCOMPONENT_TOOL_TYPE_PEN:
      return PointerData::DeviceKind::kStylus;
    case OH_NATIVEXCOMPONENT_TOOL_TYPE_RUBBER:
      return PointerData::DeviceKind::kInvertedStylus;
    case OH_NATIVEXCOMPONENT_TOOL_TYPE_BRUSH:
      return PointerData::DeviceKind::kStylus;
    case OH_NATIVEXCOMPONENT_TOOL_TYPE_PENCIL:
      return PointerData::DeviceKind::kStylus;
    case OH_NATIVEXCOMPONENT_TOOL_TYPE_AIRBRUSH:
      return PointerData::DeviceKind::kStylus;
    case OH_NATIVEXCOMPONENT_TOOL_TYPE_MOUSE:
      return PointerData::DeviceKind::kMouse;
    case OH_NATIVEXCOMPONENT_TOOL_TYPE_LENS:
      return PointerData::DeviceKind::kTouch;
    case OH_NATIVEXCOMPONENT_TOOL_TYPE_UNKNOWN:
      return PointerData::DeviceKind::kTouch;
  }
  return PointerData::DeviceKind::kTouch;
}

void OhosTouchProcessor::HandleTouchEvent(
    int64_t shell_holderID,
    OH_NativeXComponent* component,
    OH_NativeXComponent_TouchEvent* touchEvent) {
  if (touchEvent == nullptr) {
    LOGE("touchEvent Invalid");
    return;
  }
  auto packet =
      std::make_unique<flutter::PointerDataPacket>(touchEvent->numPoints);
  for (size_t index = 0; index < touchEvent->numPoints; ++index) {
    PointerData pointerData;
    pointerData.Clear();
    pointerData.embedder_id = touchEvent->id;
    pointerData.time_stamp =
        touchEvent->touchPoints[index].timeStamp / MSEC_PER_SECOND;
    pointerData.change =
        getPointerChangeForAction(touchEvent->touchPoints[index].type);
    pointerData.physical_y = touchEvent->touchPoints[index].y;
    pointerData.physical_x = touchEvent->touchPoints[index].x;
    // Delta will be generated in pointer_data_packet_converter.cc.
    pointerData.physical_delta_x = 0.0;
    pointerData.physical_delta_y = 0.0;
    pointerData.device = touchEvent->touchPoints[index].id;
    // Pointer identifier will be generated in pointer_data_packet_converter.cc.
    pointerData.pointer_identifier = 0;
    // XComponent not support Scroll
    pointerData.signal_kind = PointerData::SignalKind::kNone;
    pointerData.scroll_delta_x = 0.0;
    pointerData.scroll_delta_y = 0.0;
    pointerData.pressure = touchEvent->touchPoints[index].force;
    pointerData.pressure_max = 1.0;
    pointerData.pressure_min = 0.0;
    OH_NativeXComponent_TouchPointToolType toolType;
    OH_NativeXComponent_GetTouchPointToolType(component, index, &toolType);
    pointerData.kind = getPointerDeviceTypeForToolType(toolType);
    if (pointerData.kind == PointerData::DeviceKind::kTouch) {
      if (pointerData.change == PointerData::Change::kDown ||
          pointerData.change == PointerData::Change::kMove) {
        pointerData.buttons = kPointerButtonTouchContact;
      }
    } else if (pointerData.kind == PointerData::DeviceKind::kMouse) {
      // TODO:button获取鼠标EventButton
    }
    pointerData.pan_x = 0.0;
    pointerData.pan_y = 0.0;
    // Delta will be generated in pointer_data_packet_converter.cc.
    pointerData.pan_delta_x = 0.0;
    pointerData.pan_delta_y = 0.0;
    // The contact area between the fingerpad and the screen
    pointerData.size = touchEvent->touchPoints[index].size;
    pointerData.scale = 1.0;
    pointerData.rotation = 0.0;
    packet->SetPointerData(index, pointerData);
  }
  auto ohos_shell_holder = reinterpret_cast<OHOSShellHolder*>(shell_holderID);
  ohos_shell_holder->GetPlatformView()->DispatchPointerDataPacket(
      std::move(packet));
}

}  // namespace flutter