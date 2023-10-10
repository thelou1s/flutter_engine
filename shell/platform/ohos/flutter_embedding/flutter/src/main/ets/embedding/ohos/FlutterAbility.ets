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

import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { FlutterAbilityDelegate, Host } from './FlutterAbilityDelegate';
import Log from '../../util/Log';
import FlutterEngine from '../engine/FlutterEngine';
import FlutterShellArgs from '../engine/FlutterShellArgs';
import FlutterAbilityLaunchConfigs from './FlutterAbilityLaunchConfigs';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import display from '@ohos.display';
import { FlutterPlugin } from '../engine/plugins/FlutterPlugin';
import { AsyncCallback } from '@ohos.base';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import I18n from '@ohos.i18n'
import { PlatformBrightness } from '../engine/systemchannels/SettingsChannel';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import { DVModelContainer } from '../../view/DynamicView/dynamicView';
import { RootDvModeManager } from '../../plugin/platform/RootDvModelManager';

const TAG = "FlutterAbility";
/**
 * flutter ohos基础ability，请在让主ability继承自该类。
 * 该类主要职责：
 * 1、持有FlutterAbilityDelegate并初始化；
 * 2、生命周期传递；
 */
export class FlutterAbility extends UIAbility implements Host {
  private delegate: FlutterAbilityDelegate;
  private windowStage: window.WindowStage;
  private mainWindow: window.Window;
  private viewportMetrics = new ViewportMetrics();
  private displayInfo: display.Display;

  /**
   * onCreate
   * 1、create and attach delegate
   * 2、config windows transparent noNeed?
   * 3、lifecycle.onCreate
   * 4. setContentView()  noNeed
   */
  async onCreate(want, launchParam) {
    Log.i(TAG, "bundleCodeDir=" + this.context.bundleCodeDir);
    globalThis.flutterAbility = this
    this.displayInfo = display.getDefaultDisplaySync()
    this.viewportMetrics.devicePixelRatio = this.displayInfo.densityPixels

    this.delegate = new FlutterAbilityDelegate(this);
    await this.delegate.onAttach(this.context);
    Log.i(TAG, 'onAttach end');
    this.delegate.platformPlugin.setUIAbilityContext(this.context);
    this.delegate.onRestoreInstanceState(want);
    this.delegate.sendSettings();

    if (this.stillAttachedForEvent("onCreate")) {
      this.delegate.onCreate();
    }

    console.log('MyAbility onCreate');
    globalThis.applicationContext = this.context.getApplicationContext();
  }

  onDestroy() {
    if (this.stillAttachedForEvent("onDestroy")) {
      this.delegate.onDestroy();
    }
  }

  /**
   * window状态改变回调
   * @param windowStage
   */
  async onWindowStageCreate(windowStage: window.WindowStage) {
    this.windowStage = windowStage
    try {
      windowStage.on('windowStageEvent', (data) => {
        let stageEventType: window.WindowStageEventType = data;
        switch (stageEventType) {
          case window.WindowStageEventType.SHOWN: // 切到前台
            Log.i(TAG, 'windowStage foreground.');
            break;
          case window.WindowStageEventType.ACTIVE: // 获焦状态
            Log.i(TAG, 'windowStage active.');
            if (this.stillAttachedForEvent("onWindowFocusChanged")) {
              this.delegate.onWindowFocusChanged(true);
            }
            break;
          case window.WindowStageEventType.INACTIVE: // 失焦状态
            Log.i(TAG, 'windowStage inactive.');
            if (this.stillAttachedForEvent("onWindowFocusChanged")) {
              this.delegate.onWindowFocusChanged(false);
            }
            break;
          case window.WindowStageEventType.HIDDEN: // 切到后台
            Log.i(TAG, 'windowStage background.');
            break;
          default:
            break;
        }
      });

      this.mainWindow = windowStage.getMainWindowSync()
      this.mainWindow.on('windowSizeChange', (data) => {
        this.onWindowPropertiesUpdated();
      });

      this.mainWindow.on('avoidAreaChange', (data) => {
        this.onWindowPropertiesUpdated();
      });

      this.mainWindow.on('keyboardHeightChange', (data) => {
        this.onWindowPropertiesUpdated();
      });

      this.loadContent();
      this.mainWindow.setWindowLayoutFullScreen(true);
    } catch (exception) {
      Log.e(TAG, 'Failed to enable the listener for window stage event changes. Cause:' + JSON.stringify(exception));
    }
  }

  loadContent() {
    if (this.windowStage != null && this.stillAttachedForEvent("loadContent")) {
      Log.i(TAG, 'loadContent');
      this.windowStage.loadContent('pages/Index', (err, data) => {
        if (err.code) {
          Log.e(TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
          return;
        }
        this.onWindowPropertiesUpdated();
        Log.i(TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
      });
      if (this.stillAttachedForEvent("onWindowStageCreate")) {
        this.delegate.onWindowStageCreate();
      }
      this.delegate.getFlutterNapi().updateRefreshRate(this.displayInfo.refreshRate)
      this.onFlutterEngineReady()
    }
  }

  onFlutterEngineReady(): void {

  }

  private updateViewportMetrics() {
    this.delegate.getFlutterNapi().setViewportMetrics(this.viewportMetrics.devicePixelRatio,
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

  onWindowStageDestroy() {
    if (this.stillAttachedForEvent("onWindowStageDestroy")) {
      this.delegate.onWindowStageDestroy();
    }
  }

  onForeground() {
    if (this.stillAttachedForEvent("onForeground")) {
      this.delegate.onForeground();
    }
  }

  onBackground() {
    if (this.stillAttachedForEvent("onBackground")) {
      this.delegate.onBackground();
    }
  }

  release() {
    if (this.delegate != null) {
      this.delegate.release();
      this.delegate = null;
    }
  }

  /**
   * host所有实现方法开始======start
   */

  getAbility(): UIAbility {
    return this;
  }

  shouldDispatchAppLifecycleState(): boolean {
    return true;
  }

  provideFlutterEngine(context: common.Context): FlutterEngine {
    return null;
  }

  configureFlutterEngine(flutterEngine: FlutterEngine) {

  }

  cleanUpFlutterEngine(flutterEngine: FlutterEngine) {

  }

  getFlutterShellArgs(): FlutterShellArgs {
    return FlutterShellArgs.fromWant(this.getWant());
  }

  getDartEntrypointArgs(): Array<string> {
    if (this.launchWant.parameters[FlutterAbilityLaunchConfigs.EXTRA_DART_ENTRYPOINT_ARGS]) {
      return this.launchWant.parameters[FlutterAbilityLaunchConfigs.EXTRA_DART_ENTRYPOINT_ARGS] as Array<string>;
    }
    return new Array<string>()
  }

  detachFromFlutterEngine() {
    if (this.delegate != null) {
      this.delegate.onDetach();
    }
  }

  popSystemNavigator(): boolean {
    return false;
  }

  shouldAttachEngineToActivity(): boolean {
    return true;
  }

  getDartEntrypointLibraryUri(): string {
    return null;
  }

  getAppBundlePath(): string {
    return null;
  }

  getDartEntrypointFunctionName(): string {
    if (this.launchWant.parameters[FlutterAbilityLaunchConfigs.EXTRA_DART_ENTRYPOINT]) {
      return this.launchWant.parameters[FlutterAbilityLaunchConfigs.EXTRA_DART_ENTRYPOINT] as string;
    }
    return FlutterAbilityLaunchConfigs.DEFAULT_DART_ENTRYPOINT
  }

  getInitialRoute(): string {
    if (this.launchWant.parameters[FlutterAbilityLaunchConfigs.EXTRA_INITIAL_ROUTE]) {
      return this.launchWant.parameters[FlutterAbilityLaunchConfigs.EXTRA_INITIAL_ROUTE] as string;
    }
    return null
  }

  getWant(): Want {
    return this.launchWant;
  }

  shouldDestroyEngineWithHost(): boolean {
    return true;
  }

  shouldRestoreAndSaveState(): boolean{
    if (this.launchWant.parameters[FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_ID] != undefined) {
      return this.launchWant.parameters[FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_ID] as boolean;
    }
    if (this.getCachedEngineId() != null) {
      // Prevent overwriting the existing state in a cached engine with restoration state.
      return false;
    }
    return true;
  }

  getCachedEngineId(): string {
    return this.launchWant.parameters[FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_ID] as string
  }

  getCachedEngineGroupId(): string {
    return this.launchWant.parameters[FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_GROUP_ID] as string
  }

  /**
   * host所有实现方法结束======end
   */
  private stillAttachedForEvent(event: string) {
    Log.i(TAG, 'Ability ' + event);
    if (this.delegate == null) {
      Log.w(TAG, "FlutterAbility " + event + " call after release.");
      return false;
    }
    if (!this.delegate.isAttached) {
      Log.w(TAG, "FlutterAbility " + event + " call after detach.");
      return false;
    }
    return true;
  }

  addPlugin(plugin: FlutterPlugin): void {
    if (this.delegate != null) {
      this.delegate.addPlugin(plugin)
    }
  }

  removePlugin(plugin: FlutterPlugin): void {
    if (this.delegate != null) {
      this.delegate.removePlugin(plugin)
    }
  }

  private onWindowPropertiesUpdated(){
    if (!this.delegate.isAttached) {
      return;
    }
    let systemAvoidArea = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    let gestureAvoidArea = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM_GESTURE);
    let keyboardAvoidArea = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD);
    const properties = this.mainWindow.getWindowProperties();
    this.viewportMetrics.physicalWidth = properties.windowRect.width;
    this.viewportMetrics.physicalHeight = properties.windowRect.height;

    this.viewportMetrics.physicalViewPaddingTop = systemAvoidArea.topRect.height
    this.viewportMetrics.physicalViewPaddingLeft = systemAvoidArea.leftRect.width
    this.viewportMetrics.physicalViewPaddingBottom = systemAvoidArea.bottomRect.height
    this.viewportMetrics.physicalViewPaddingRight = systemAvoidArea.rightRect.width

    this.viewportMetrics.physicalViewInsetTop = keyboardAvoidArea.topRect.height
    this.viewportMetrics.physicalViewInsetLeft = keyboardAvoidArea.leftRect.width
    this.viewportMetrics.physicalViewInsetBottom = keyboardAvoidArea.bottomRect.height
    this.viewportMetrics.physicalViewInsetRight = keyboardAvoidArea.rightRect.width

    this.viewportMetrics.systemGestureInsetTop = gestureAvoidArea.topRect.height
    this.viewportMetrics.systemGestureInsetLeft = gestureAvoidArea.leftRect.width
    this.viewportMetrics.systemGestureInsetBottom = gestureAvoidArea.bottomRect.height
    this.viewportMetrics.systemGestureInsetRight = gestureAvoidArea.rightRect.width

    this.updateViewportMetrics()
  }

  onMemoryLevel(level: AbilityConstant.MemoryLevel): void {
    Log.i(TAG, 'onMemoryLevel: ' + level);
    if (level === AbilityConstant.MemoryLevel.MEMORY_LEVEL_CRITICAL) {
      this.delegate.onLowMemory();
    }
  }

  onConfigurationUpdated(config){
    Log.i(TAG, 'onConfigurationUpdated config:' + JSON.stringify(config));
    this.delegate.flutterEngine.getSettingsChannel().startMessage()
      .setAlwaysUse24HourFormat(I18n.System.is24HourClock())
      .setPlatformBrightness(config.colorMode != ConfigurationConstant.ColorMode.COLOR_MODE_DARK
        ? PlatformBrightness.LIGHT : PlatformBrightness.DARK);
  }

  getWindowId(callback: AsyncCallback<number>): void {
    if (callback === null) {
      return;
    }
    try {
      window.getLastWindow(this.context, (error, win) => {
        if (error.code) {
          callback(error, -1);
          return;
        }
        let windowId = win.getWindowProperties().id;
        callback(error, windowId);
      });
    } catch (err) {
      Log.e(TAG, "get window id error!");
      callback(err, -1);
    }
  }
}

export class ViewportMetrics {
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