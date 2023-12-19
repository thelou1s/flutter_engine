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

import common from '@ohos.app.ability.common';
import { FlutterAbilityDelegate } from './FlutterAbilityDelegate';
import window from '@ohos.window';
import { ViewportMetrics } from './FlutterAbility';
import {
  BuilderParams,
  DVModel, DVModelChildren, DVModelEvents, DVModelParameters } from '../../view/DynamicView/dynamicView';
import display from '@ohos.display';
import { RootDvModeManager } from '../../plugin/platform/RootDvModelManager';
import { FlutterPlugin } from '../engine/plugins/FlutterPlugin';

export class FlutterComponentDelegate {
  private context:common.UIAbilityContext
  private delegate?: FlutterAbilityDelegate | null;
  private mainWindow?: window.Window;
  private viewportMetrics = new ViewportMetrics();

  constructor(context:common.UIAbilityContext) {
    this.context = context;
    this.delegate = new FlutterAbilityDelegate();
  }

  async init(): Promise<void> {
    let displayInfo = display.getDefaultDisplaySync();
    this.viewportMetrics.devicePixelRatio = displayInfo?.densityPixels;
    await this?.delegate?.onAttach(this.context);
    this?.delegate?.platformPlugin?.setUIAbilityContext(this.context);
    this?.delegate?.sendSettings();
    let params: DVModelParameters = new DVModelParameters();
    (params as Record<string, ESObject>)["xComponentId"] =
    this.delegate?.getFlutterNapi()?.nativeShellHolderId?.toString();
    let xComponentModel: DVModel =
      new DVModel("xComponent", params, new DVModelEvents(), new DVModelChildren(), BuildXComponentStruct);
    RootDvModeManager.addDvModel(xComponentModel);
    this.mainWindow = await window.getLastWindow(this.context);
    this.mainWindow?.on('windowSizeChange', (data) => {
      this.onWindowPropertiesUpdated();
    });

    this.mainWindow?.on('avoidAreaChange', (data) => {
      this.onWindowPropertiesUpdated();
    });

    this.mainWindow?.on('keyboardHeightChange', (data) => {
      this.onWindowPropertiesUpdated();
    });
    this.onWindowPropertiesUpdated();
    this?.delegate?.onWindowStageCreate();
    this?.delegate?.onWindowFocusChanged(true);
    this?.delegate?.onForeground();
  }

  private onWindowPropertiesUpdated(){
    if (this.delegate == null || !this.delegate.isAttached) {
      return;
    }
    let systemAvoidArea = this.mainWindow?.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    let gestureAvoidArea = this.mainWindow?.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM_GESTURE);
    let keyboardAvoidArea = this.mainWindow?.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD);
    const properties = this.mainWindow?.getWindowProperties();
    if (properties!.windowRect.width < this.viewportMetrics.physicalWidth) {
      this.viewportMetrics.physicalWidth = properties!.windowRect.width;
    }
    if (properties!.windowRect.height < this.viewportMetrics.physicalHeight) {
      this.viewportMetrics.physicalHeight = properties!.windowRect.height;


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

  private updateViewportMetrics() {
    this?.delegate?.getFlutterNapi()?.setViewportMetrics(this.viewportMetrics.devicePixelRatio,
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

  addPlugin(plugin: FlutterPlugin): void {
    this.delegate?.addPlugin(plugin)
  }

  release():void {
    if (this?.delegate != null) {
      this?.delegate?.onDestroy();
      this?.delegate?.release();
      this.delegate = null;
    }
  }

  updateView(width:number, height:number):void {
    this.viewportMetrics.physicalWidth = width;
    this.viewportMetrics.physicalHeight = height;
    this.updateViewportMetrics();
  }
}

@Component
struct XComponentStruct {
  private context:ESObject;
  dvModelParams: DVModelParameters = new DVModelParameters();

  build() {
    XComponent({ id: (this.dvModelParams as Record<string, ESObject>)["xComponentId"], type: 'texture', libraryname: 'flutter'})
      .onLoad((context) => {
        this.context = context;
      })
      .onDestroy(() => {
      })
  }
}

@Builder function BuildXComponentStruct(buildParams: BuilderParams) {
  XComponentStruct({dvModelParams: buildParams.params});
}