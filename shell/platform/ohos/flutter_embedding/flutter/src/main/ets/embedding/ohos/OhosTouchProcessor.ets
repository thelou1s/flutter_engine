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

import { TouchEvent } from '@ohos.multimodalInput.touchEvent';

export default class OhosTouchProcessor {
  private static POINTER_DATA_FIELD_COUNT: number = 35;

  static BYTES_PER_FIELD: number = 8;

  private static POINTER_DATA_FLAG_BATCHED: number = 1;

  public onTouchEvent(event: TouchEvent, transformMatrix: any): void {

  }
}

export enum PointerChange {
  CANCEL = 0,
  ADD = 1,
  REMOVE = 2,
  HOVER = 3,
  DOWN = 4,
  MOVE = 5,
  UP = 6,
  PAN_ZOOM_START = 7,
  PAN_ZOOM_UPDATE = 8,
  PAN_ZOOM_END = 9
}

export enum PointerDeviceKind {
  TOUCH = 0,
  MOUSE = 1,
  STYLUS = 2,
  INVERTED_STYLUS = 3,
  TRACKPAD = 4,
  UNKNOWN = 5
}

export enum PointerSignalKind {
  NONE = 0,
  SCROLL = 1,
  SCROLL_INERTIA_CANCEL = 2,
  SCALE = 3,
  UNKNOWN = 4
}