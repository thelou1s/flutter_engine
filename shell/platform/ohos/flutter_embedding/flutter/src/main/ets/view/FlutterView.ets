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
import FlutterEngine from '../embedding/engine/FlutterEngine';
import Log from '../util/Log';
import { DVModel, DVModelChildren, DVModelEvents, DVModelParameters } from './DynamicView/dynamicView';
import display from '@ohos.display';
import FlutterManager from '../embedding/ohos/FlutterManager';
import window from '@ohos.window';
import KeyboardManager from '../embedding/ohos/KeyboardManager';

const TAG = "FlutterView";

class ViewportMetrics {
  devicePixelRatio: number = 1.0;
  physicalWidth: number = 0;
  physicalHeight: number = 0;
  physicalViewPaddingTop: number = 0;
  physicalViewPaddingRight: number = 0;
  physicalViewPaddingBottom: number = 0;
  physicalViewPaddingLeft: number = 0;
  physicalViewInsetTop: number = 0;
  physicalViewInsetRight: number = 0;
  physicalViewInsetBottom: number = 0;
  physicalViewInsetLeft: number = 0;
  systemGestureInsetTop: number = 0;
  systemGestureInsetRight: number = 0;
  systemGestureInsetBottom: number = 0;
  systemGestureInsetLeft: number = 0;
  physicalTouchSlop = -1;
}

export class FlutterView {
  private flutterEngine: FlutterEngine | null = null
  private id: string = ""
  private dVModel: DVModel = new DVModel("Stack", new DVModelParameters(), new DVModelEvents(), new DVModelChildren(), null);
  private isSurfaceAvailableForRendering: boolean = false
  private viewportMetrics = new ViewportMetrics();
  private displayInfo?: display.Display;
  private keyboardManager: KeyboardManager | null = null;
  private mainWindow: window.Window

  constructor(viewId: string, context: Context) {
    this.id = viewId
    this.displayInfo = display.getDefaultDisplaySync();
    this.viewportMetrics.devicePixelRatio = this.displayInfo?.densityPixels
    this.mainWindow = FlutterManager.getInstance()
      .getWindowStage(FlutterManager.getInstance().getUIAbility(context))
      .getMainWindowSync();

    this.mainWindow?.on('windowSizeChange', this.windowSizeChangeCallback);
    this.mainWindow?.on('avoidAreaChange', this.avoidAreaChangeCallback);
    this.mainWindow?.on('keyboardHeightChange', this.keyboardHeightChangeCallback);
  }

  private  windowSizeChangeCallback= (data: window.Size) => {
    Log.i(TAG, "windowSizeChangeCallback");
    this.onAreaChange(null);
  }
  private avoidAreaChangeCallback = (data: ESObject) => {
    Log.i(TAG, "avoidAreaChangeCallback");
    this.onAreaChange(null);
  }
  private keyboardHeightChangeCallback = (data: number) => {
    Log.i(TAG, "keyboardHeightChangeCallback");
    this.onAreaChange(null);
  }

  getId(): string {
    return this.id
  }

  getDVModel() {
    return this.dVModel
  }

  onDestroy() {
    try {
      this.mainWindow?.off('windowSizeChange', this.windowSizeChangeCallback);
      this.mainWindow?.off('avoidAreaChange', this.avoidAreaChangeCallback);
      this.mainWindow?.off('keyboardHeightChange', this.keyboardHeightChangeCallback);
    } catch (e) {
    }
  }

  attachToFlutterEngine(flutterEngine: FlutterEngine): void {
    if (this.isAttachedToFlutterEngine()) {
      if (flutterEngine == this.flutterEngine) {
        Log.i(TAG, "Already attached to this engine. Doing nothing.");
        return;
      }
      // Detach from a previous FlutterEngine so we can attach to this new one.f
      Log.i(
        TAG,
        "Currently attached to a different engine. Detaching and then attaching"
          + " to new engine.");
      this.detachFromFlutterEngine();
    }
    Log.i(TAG, "attachToFlutterEngine");
    this.flutterEngine = flutterEngine;
    this.keyboardManager = new KeyboardManager(flutterEngine);
    if (this.isSurfaceAvailableForRendering) {
      this.flutterEngine.getFlutterNapi().xComponentAttachFlutterEngine(Number(this.id))
    }
    this.flutterEngine?.getFlutterNapi()?.updateRefreshRate(this.displayInfo!.refreshRate)
    flutterEngine.getPlatformViewsController()?.attachToView(this);
    this.updateViewportMetrics()
  }

  detachFromFlutterEngine(): void {
    Log.i(TAG, "detachFromFlutterEngine");
    if (!this.isAttachedToFlutterEngine()) {
      Log.d(TAG, "FlutterView not attached to an engine. Not detaching.");
      return;
    }
    if (this.isSurfaceAvailableForRendering) {
      this.flutterEngine!!.getFlutterNapi().xComponentDetachFlutterEngine(Number(this.id))
    }
    this.flutterEngine?.getPlatformViewsController()?.detachFromView();
    this.flutterEngine = null;
    this.keyboardManager = null;
  }

  onSurfaceCreated() {
    this.isSurfaceAvailableForRendering = true;
    if (this.isAttachedToFlutterEngine()) {
      this.flutterEngine!!.getFlutterNapi().xComponentAttachFlutterEngine(Number(this.id))
    }
  }

  onSurfaceDestroyed() {
    this.isSurfaceAvailableForRendering = false;
    if (this.isAttachedToFlutterEngine()) {
      this.flutterEngine!!.getFlutterNapi().xComponentDetachFlutterEngine(Number(this.id))
    }
  }

  onAreaChange(newArea: Area | null) {
    let systemAvoidArea = this.mainWindow?.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    let gestureAvoidArea = this.mainWindow?.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM_GESTURE);
    let keyboardAvoidArea = this.mainWindow?.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD);

    if (newArea != null) {
      this.viewportMetrics.physicalWidth = vp2px(newArea.width as number);
      this.viewportMetrics.physicalHeight = vp2px(newArea.height as number);
    }

    this.viewportMetrics.physicalViewPaddingTop = systemAvoidArea!.topRect.height
    this.viewportMetrics.physicalViewPaddingLeft = systemAvoidArea!.leftRect.width
    this.viewportMetrics.physicalViewPaddingBottom = systemAvoidArea!.bottomRect.height
    this.viewportMetrics.physicalViewPaddingRight = systemAvoidArea!.rightRect.width

    this.viewportMetrics.physicalViewInsetTop = keyboardAvoidArea!.topRect.height
    this.viewportMetrics.physicalViewInsetLeft = keyboardAvoidArea!.leftRect.width
    this.viewportMetrics.physicalViewInsetBottom = keyboardAvoidArea!.bottomRect.height
    this.viewportMetrics.physicalViewInsetRight = keyboardAvoidArea!.rightRect.width

    this.viewportMetrics.systemGestureInsetTop = gestureAvoidArea!.topRect.height
    this.viewportMetrics.systemGestureInsetLeft = gestureAvoidArea!.leftRect.width
    this.viewportMetrics.systemGestureInsetBottom = gestureAvoidArea!.bottomRect.height
    this.viewportMetrics.systemGestureInsetRight = gestureAvoidArea!.rightRect.width
    this.updateViewportMetrics()
  }

  private isAttachedToFlutterEngine(): boolean {
    return this.flutterEngine != null
  }

  private updateViewportMetrics() {
    if (this.isAttachedToFlutterEngine()) {
      this?.flutterEngine?.getFlutterNapi()?.setViewportMetrics(this.viewportMetrics.devicePixelRatio,
        this.viewportMetrics.physicalWidth,
        this.viewportMetrics.physicalHeight,
        this.viewportMetrics.physicalViewPaddingTop,
        this.viewportMetrics.physicalViewPaddingRight,
        this.viewportMetrics.physicalViewPaddingBottom,
        this.viewportMetrics.physicalViewPaddingLeft,
        this.viewportMetrics.physicalViewInsetTop,
        this.viewportMetrics.physicalViewInsetRight,
        this.viewportMetrics.physicalViewInsetBottom,
        this.viewportMetrics.physicalViewInsetLeft,
        this.viewportMetrics.systemGestureInsetTop,
        this.viewportMetrics.systemGestureInsetRight,
        this.viewportMetrics.systemGestureInsetBottom,
        this.viewportMetrics.systemGestureInsetLeft,
        this.viewportMetrics.physicalTouchSlop,
        new Array(0),
        new Array(0),
        new Array(0))
    }
  }

  onKeyEvent(event: KeyEvent) {
    this.keyboardManager?.handleKeyEvent(event)
  }
}