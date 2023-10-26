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

import MouseCursorChannel, { MouseCursorMethodHandler } from '../../embedding/engine/systemchannels/MouseCursorChannel';
import pointer from '@ohos.multimodalInput.pointer';
import HashMap from '@ohos.util.HashMap';
import Log from '../../util/Log';
import { AsyncCallback } from '@ohos.base';

const TAG: string = "MouseCursorPlugin";
export default class MouseCursorPlugin implements MouseCursorMethodHandler{
  private mView: MouseCursorViewDelegate;

  private mouseCursorChannel: MouseCursorChannel;

  private systemCursorConstants: HashMap<string, pointer.PointerStyle> | null = null;

  constructor(mouseCursorView: MouseCursorViewDelegate, mouseCursorChannel: MouseCursorChannel) {
    this.mView = mouseCursorView;
    this.mouseCursorChannel = mouseCursorChannel;
    this.mouseCursorChannel.setMethodHandler(this);
  }

  activateSystemCursor(kind: string): void {
    this.mView.getWindowId((error, windowId) => {
      if (windowId < 0) {
        Log.w(TAG, "set point style failed windowId is invalid");
        return;
      }
      let pointStyle: pointer.PointerStyle = this.resolveSystemCursor(kind);
      try {
        pointer.setPointerStyle(windowId, pointStyle, (err: ESObject) => {
          Log.i(TAG, "set point style success kind : " + kind);
        })
      } catch (e) {
        Log.e(TAG, "set point style failed : " + kind + " " + JSON.stringify(e));
      }
    });
  }

  /**
   * Return mouse cursor point style
   *
   * <p>This method guarantees to return a non-null object.
   *
   * @param kind mouse cursor type
   * @returns point style
   */
  private resolveSystemCursor(kind: string): pointer.PointerStyle {
    if (this.systemCursorConstants == null) {
      this.systemCursorConstants = new HashMap();
      this.systemCursorConstants.set("alias", pointer.PointerStyle.DEFAULT);
      this.systemCursorConstants.set("allScroll", pointer.PointerStyle.MOVE);
      this.systemCursorConstants.set("basic", pointer.PointerStyle.DEFAULT);
      this.systemCursorConstants.set("cell", pointer.PointerStyle.DEFAULT);
      this.systemCursorConstants.set("click", pointer.PointerStyle.HAND_POINTING);
      this.systemCursorConstants.set("contextMenu", pointer.PointerStyle.DEFAULT);
      this.systemCursorConstants.set("copy", pointer.PointerStyle.CURSOR_COPY);
      this.systemCursorConstants.set("forbidden", pointer.PointerStyle.CURSOR_FORBID);
      this.systemCursorConstants.set("grab", pointer.PointerStyle.HAND_OPEN);
      this.systemCursorConstants.set("grabbing", pointer.PointerStyle.HAND_GRABBING);
      this.systemCursorConstants.set("help", pointer.PointerStyle.HELP);
      this.systemCursorConstants.set("move", pointer.PointerStyle.MOVE);
      this.systemCursorConstants.set("none", pointer.PointerStyle.DEFAULT);
      this.systemCursorConstants.set("noDrop", pointer.PointerStyle.DEFAULT);
      this.systemCursorConstants.set("precise", pointer.PointerStyle.CROSS);
      this.systemCursorConstants.set("text", pointer.PointerStyle.TEXT_CURSOR);
      this.systemCursorConstants.set("resizeColum", pointer.PointerStyle.NORTH_SOUTH);
      this.systemCursorConstants.set("resizeDown", pointer.PointerStyle.SOUTH);
      this.systemCursorConstants.set("resizeUpLeft", pointer.PointerStyle.NORTH_WEST);
      this.systemCursorConstants.set("resizeDownRight", pointer.PointerStyle.SOUTH_EAST);
      this.systemCursorConstants.set("resizeLeft", pointer.PointerStyle.WEST);
      this.systemCursorConstants.set("resizeLeftRight", pointer.PointerStyle.RESIZE_LEFT_RIGHT);
      this.systemCursorConstants.set("resizeRight", pointer.PointerStyle.EAST);
      this.systemCursorConstants.set("resizeRow", pointer.PointerStyle.WEST_EAST);
      this.systemCursorConstants.set("resizeUp", pointer.PointerStyle.NORTH);
      this.systemCursorConstants.set("resizeUpDown", pointer.PointerStyle.RESIZE_UP_DOWN);
      this.systemCursorConstants.set("resizeUpLeft", pointer.PointerStyle.NORTH_WEST);
      this.systemCursorConstants.set("resizeUpRight", pointer.PointerStyle.NORTH_EAST);
      this.systemCursorConstants.set("resizeUpLeftDownRight", pointer.PointerStyle.MOVE);
      this.systemCursorConstants.set("resizeUpRightDownLeft", pointer.PointerStyle.MOVE);
      this.systemCursorConstants.set("verticalText", pointer.PointerStyle.TEXT_CURSOR);
      this.systemCursorConstants.set("wait", pointer.PointerStyle.DEFAULT);
      this.systemCursorConstants.set("zoomIn", pointer.PointerStyle.ZOOM_IN);
      this.systemCursorConstants.set("zoomOut", pointer.PointerStyle.ZOOM_OUT);
    }
    let pointStyle:pointer.PointerStyle = this.systemCursorConstants.get(kind);
    if (pointStyle === null) {
      return pointer.PointerStyle.DEFAULT;
    }
    return pointStyle;
  }

  /**
   * Detaches the text input plugin from the platform views controller;
   *
   * <p> The MouseCursorPlugin instance should not be used after call this.
   */
  destroy(): void {
    this.mouseCursorChannel.setMethodHandler(null);
  }
}

/**
 * Delegate interface for requesting the system to display a pointer icon object.
 *
 * <p>Typically implemented by an component, such as a{@code FlutterView}
 */
export interface MouseCursorViewDelegate {
  /**
   * get window id to set mouse style
   * <p> component need to implement this interface to get windowId
   *
   * @param callback windowId
   * */
  getWindowId(callback: AsyncCallback<number>): void;
}