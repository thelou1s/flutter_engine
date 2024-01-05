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
import { FlutterAbilityAndEntryDelegate, Host } from './FlutterAbilityAndEntryDelegate';
import Log from '../../util/Log';
import FlutterEngine from '../engine/FlutterEngine';
import FlutterShellArgs from '../engine/FlutterShellArgs';
import FlutterAbilityLaunchConfigs from './FlutterAbilityLaunchConfigs';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import { FlutterPlugin } from '../engine/plugins/FlutterPlugin';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import I18n from '@ohos.i18n'
import { PlatformBrightness } from '../engine/systemchannels/SettingsChannel';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import { Configuration } from '@ohos.app.ability.Configuration';

import List from '@ohos.util.List';
import ExclusiveAppComponent from './ExclusiveAppComponent';
import errorManager from '@ohos.app.ability.errorManager';
import appRecovery from '@ohos.app.ability.appRecovery';
import FlutterManager from './FlutterManager';
import { FlutterView } from '../../view/FlutterView';

const TAG = "FlutterAbility";
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS';

/**
 * flutter ohos基础ability，请在让主ability继承自该类。
 * 该类主要职责：
 * 1、持有FlutterAbilityDelegate并初始化；
 * 2、生命周期传递；
 */
export class FlutterAbility extends UIAbility implements Host {
  private delegate?: FlutterAbilityAndEntryDelegate | null;
  private flutterView?: FlutterView | null;
  private mainWindow?: window.Window | null;
  private errorManagerId:number = 0;
  pagePath(): string {
    return "pages/Index"
  }

  /**
   * onCreate
   * 1、create and attach delegate
   * 2、config windows transparent noNeed?
   * 3、lifecycle.onCreate
   * 4. setContentView()  noNeed
   */
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    Log.i(TAG, "bundleCodeDir=" + this.context.bundleCodeDir);
    FlutterManager.getInstance().pushUIAbility(this)

    this.delegate = new FlutterAbilityAndEntryDelegate(this);
    await this?.delegate?.onAttach(this.context);
    Log.i(TAG, 'onAttach end');
    this?.delegate?.platformPlugin?.setUIAbilityContext(this.context);
    this?.delegate?.onRestoreInstanceState(want);

    if (this.stillAttachedForEvent("onCreate")) {
      this.delegate?.onCreate();
    }

    if (this.stillAttachedForEvent("onWindowStageCreate")) {
      this?.delegate?.onWindowStageCreate();
    }

    console.log('MyAbility onCreate');

    this.context.eventHub.on(EVENT_BACK_PRESS, () => {
      this.delegate?.flutterEngine?.getNavigationChannel()?.popRoute();
    });
    let observer:errorManager.ErrorObserver = {
      onUnhandledException(errorMsg) {
        console.log("onUnhandledException, errorMsg:", errorMsg);
        appRecovery.saveAppState();
        appRecovery.restartApp();
      }
    }
    this.errorManagerId = errorManager.on('error', observer);
  }

  onDestroy() {
    FlutterManager.getInstance().popUIAbility(this);
    this.context.eventHub.off(EVENT_BACK_PRESS);
    if (this.stillAttachedForEvent("onDestroy")) {
      this?.delegate?.onDestroy();
    }
    errorManager.off('error', this.errorManagerId);

    if (this.flutterView != null) {
      this.flutterView.onDestroy()
      this.flutterView = null;
    }
  }
  
  onSaveState(reason: AbilityConstant.StateType, wantParam: Record<string, Object>): AbilityConstant.OnSaveResult {
    return this?.delegate?.onSaveState(reason, wantParam) ?? AbilityConstant.OnSaveResult.ALL_REJECT;
  }

  /**
   * window状态改变回调
   * @param windowStage
   */
  async onWindowStageCreate(windowStage: window.WindowStage) {
    FlutterManager.getInstance().pushWindowStage(this, windowStage);
    this.mainWindow = windowStage.getMainWindowSync();
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
              this?.delegate?.onWindowFocusChanged(true);
            }
            break;
          case window.WindowStageEventType.INACTIVE: // 失焦状态
            Log.i(TAG, 'windowStage inactive.');
            if (this.stillAttachedForEvent("onWindowFocusChanged")) {
              this?.delegate?.onWindowFocusChanged(false);
            }
            break;
          case window.WindowStageEventType.HIDDEN: // 切到后台
            Log.i(TAG, 'windowStage background.');
            break;
        }
      });

      this.flutterView = this.delegate?.createView(this.context)
      Log.e(TAG, 'onWindowStageCreate:' +  this.flutterView!!.getId());
      let storage: LocalStorage = new LocalStorage();
      storage.setOrCreate("viewId", this.flutterView!!.getId())
      windowStage.loadContent(this.pagePath(), storage, (err, data) => {
        if (err.code) {
          Log.e(TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
          return;
        }

        Log.i(TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
      });
      this.mainWindow?.setWindowLayoutFullScreen(true);
    } catch (exception) {
      Log.e(TAG, 'Failed to enable the listener for window stage event changes. Cause:' + JSON.stringify(exception));
    }
  }

  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    this?.delegate?.onNewWant(want,launchParams)
  }

  onWindowStageDestroy() {
    FlutterManager.getInstance().popWindowStage(this);
    if (this.stillAttachedForEvent("onWindowStageDestroy")) {
      this?.delegate?.onWindowStageDestroy();
    }
  }

  onForeground() {
    if (this.stillAttachedForEvent("onForeground")) {
      this?.delegate?.onForeground();
    }
  }

  onBackground() {
    if (this.stillAttachedForEvent("onBackground")) {
      this?.delegate?.onBackground();
    }
  }

  release() {
    if (this?.delegate != null) {
      this?.delegate?.release();
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

  provideFlutterEngine(context: common.Context): FlutterEngine | null {
    return null;
  }

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    let _UIContext = this.mainWindow?.getUIContext();
    this.delegate?.setUIContext(_UIContext);
    this.delegate?.sendSettings();
  }

  cleanUpFlutterEngine(flutterEngine: FlutterEngine) {

  }

  getFlutterShellArgs(): FlutterShellArgs {
    return FlutterShellArgs.fromWant(this.getWant());
  }

  getDartEntrypointArgs(): Array<string> {
    if (this.launchWant.parameters![FlutterAbilityLaunchConfigs.EXTRA_DART_ENTRYPOINT_ARGS]) {
      return this.launchWant.parameters![FlutterAbilityLaunchConfigs.EXTRA_DART_ENTRYPOINT_ARGS] as Array<string>;
    }
    return new Array<string>()
  }

  detachFromFlutterEngine() {
    if (this?.delegate != null) {
      this?.delegate?.onDetach();
    }
  }

  popSystemNavigator(): boolean {
    return false;
  }

  shouldAttachEngineToAbility(): boolean {
    return true;
  }

  getDartEntrypointLibraryUri(): string {
    return "";
  }

  getAppBundlePath(): string {
    return "";
  }

  getDartEntrypointFunctionName(): string {
    if (this.launchWant.parameters![FlutterAbilityLaunchConfigs.EXTRA_DART_ENTRYPOINT]) {
      return this.launchWant.parameters![FlutterAbilityLaunchConfigs.EXTRA_DART_ENTRYPOINT] as string;
    }
    return FlutterAbilityLaunchConfigs.DEFAULT_DART_ENTRYPOINT
  }

  getInitialRoute(): string {
    if (this.launchWant.parameters![FlutterAbilityLaunchConfigs.EXTRA_INITIAL_ROUTE]) {
      return this.launchWant.parameters![FlutterAbilityLaunchConfigs.EXTRA_INITIAL_ROUTE] as string;
    }
    return ""
  }

  getWant(): Want {
    return this.launchWant;
  }

  shouldDestroyEngineWithHost(): boolean {
    if ((this.getCachedEngineId() != null && this.getCachedEngineId().length > 0) || this.delegate!!.isFlutterEngineFromHost()) {
      // Only destroy a cached engine if explicitly requested by app developer.
      return false;
    }
    return true;
  }

  shouldRestoreAndSaveState(): boolean{
    if (this.launchWant.parameters![FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_ID] != undefined) {
      return this.launchWant.parameters![FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_ID] as boolean;
    }
    if (this.getCachedEngineId() != null) {
      // Prevent overwriting the existing state in a cached engine with restoration state.
      return false;
    }
    return true;
  }

  getPlugins(): List<FlutterPlugin>{
    // Subclasses should override this function.
    return new List()
  }

  getExclusiveAppComponent(): ExclusiveAppComponent<UIAbility> | null {
    return this.delegate ? this.delegate : null
  }

  getCachedEngineId(): string {
    return this.launchWant.parameters![FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_ID] as string
  }

  getCachedEngineGroupId(): string | null {
    return this.launchWant.parameters![FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_GROUP_ID] as string
  }

  /**
   * host所有实现方法结束======end
   */
  private stillAttachedForEvent(event: string) {
    Log.i(TAG, 'Ability ' + event);
    if (this?.delegate == null) {
      Log.w(TAG, "FlutterAbility " + event + " call after release.");
      return false;
    }
    if (!this?.delegate?.isAttached) {
      Log.w(TAG, "FlutterAbility " + event + " call after detach.");
      return false;
    }
    return true;
  }

  addPlugin(plugin: FlutterPlugin): void {
    if (this?.delegate != null) {
      this?.delegate?.addPlugin(plugin)
    }
  }

  removePlugin(plugin: FlutterPlugin): void {
    if (this?.delegate != null) {
      this?.delegate?.removePlugin(plugin)
    }
  }

  onMemoryLevel(level: AbilityConstant.MemoryLevel): void {
    Log.i(TAG, 'onMemoryLevel: ' + level);
    if (level === AbilityConstant.MemoryLevel.MEMORY_LEVEL_CRITICAL) {
      this?.delegate?.onLowMemory();
    }
  }

  onConfigurationUpdated(config: Configuration){
    Log.i(TAG, 'onConfigurationUpdated config:' + JSON.stringify(config));
    this?.delegate?.flutterEngine?.getSettingsChannel()?.startMessage()
      .setAlwaysUse24HourFormat(I18n.System.is24HourClock())
      .setPlatformBrightness(config.colorMode != ConfigurationConstant.ColorMode.COLOR_MODE_DARK
        ? PlatformBrightness.LIGHT : PlatformBrightness.DARK);
  }

  getFlutterEngine(): FlutterEngine | null {
    return this.delegate?.flutterEngine || null;
  }
}