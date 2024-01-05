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

import FlutterEngine from '../engine/FlutterEngine';
import Want from '@ohos.app.ability.Want';
import FlutterShellArgs from '../engine/FlutterShellArgs';
import UIAbility from '@ohos.app.ability.UIAbility';
import ExclusiveAppComponent from './ExclusiveAppComponent';
import { FlutterPlugin } from '../engine/plugins/FlutterPlugin';
import List from '@ohos.util.List';
import { FlutterAbilityAndEntryDelegate, Host } from './FlutterAbilityAndEntryDelegate';
import FlutterAbilityLaunchConfigs from './FlutterAbilityLaunchConfigs';
import Log from '../../util/Log';
import { FlutterView } from '../../view/FlutterView';
import FlutterManager from './FlutterManager';
import window from '@ohos.window';
import FlutterEngineConfigurator from './FlutterEngineConfigurator';

const TAG = "FlutterEntry";

export default class FlutterEntry implements Host {
  private static ARG_SHOULD_ATTACH_ENGINE_TO_ABILITY: string =  "should_attach_engine_to_ability";

  private uiAbility: UIAbility | null = null
  private delegate: FlutterAbilityAndEntryDelegate | null = null
  private flutterView: FlutterView | null = null
  private context: Context;
  private windowStage: window.WindowStage | null = null
  private parameters: ESObject = {};
  private engineConfigurator: FlutterEngineConfigurator | null = null

  constructor(context: Context, params: ESObject = {}) {
    this.context = context;
    this.uiAbility = FlutterManager.getInstance().getUIAbility(context);
    this.parameters = params;
    this.windowStage = FlutterManager.getInstance().getWindowStage(this.uiAbility);
  }

  async aboutToAppear() {
    Log.i(TAG, 'aboutToAppear');
    this.delegate = new FlutterAbilityAndEntryDelegate(this);
    this.flutterView = this.delegate?.createView(this.context);
    await this?.delegate?.onAttach(this.context);
    Log.i(TAG, 'onAttach end');
    this?.delegate?.platformPlugin?.setUIAbilityContext(this.uiAbility!!.context);
    this.delegate?.onCreate();
    this.delegate?.onWindowStageCreate()
    this.windowStage?.on('windowStageEvent', this.windowStageEventCallback);
  }

  private windowStageEventCallback = (data: window.WindowStageEventType) => {
    let stageEventType: window.WindowStageEventType = data;
    switch (stageEventType) {
      case window.WindowStageEventType.SHOWN: // 切到前台
        Log.i(TAG, 'windowStage foreground.');
        break;
      case window.WindowStageEventType.ACTIVE: // 获焦状态
        Log.i(TAG, 'windowStage active.');
        this?.delegate?.onWindowFocusChanged(true);
        break;
      case window.WindowStageEventType.INACTIVE: // 失焦状态
        Log.i(TAG, 'windowStage inactive.');
        this?.delegate?.onWindowFocusChanged(false);
        break;
      case window.WindowStageEventType.HIDDEN: // 切到后台
        Log.i(TAG, 'windowStage background.');
        break;
    }
  }

  setFlutterEngineConfigurator(configurator: FlutterEngineConfigurator) {
    this.engineConfigurator = configurator;
  }

  getFlutterView(): FlutterView {
    return this.flutterView!!
  }

  getFlutterEngine(): FlutterEngine | null {
    return this.delegate?.flutterEngine!
  }

  aboutToDisappear() {
    Log.d(TAG, "FlutterEntry aboutToDisappear===");
    try {
      this.windowStage?.off('windowStageEvent', this.windowStageEventCallback);
    } catch (err) {

    }
    if (this.flutterView != null) {
      this.flutterView.onDestroy();
      this.flutterView = null;
    }
    if (this.delegate != null) {
      this.delegate?.onDetach();
      this.delegate?.onDestroy();
    }
  }

  onPageShow() { //生命周期
    Log.d(TAG, "FlutterEntry onPageShow===");
    this?.delegate?.onForeground();
  }

  onPageHide() { //生命周期
    Log.d(TAG, "FlutterEntry onPageHide===");
    this?.delegate?.onBackground();
  }

  shouldDispatchAppLifecycleState(): boolean {
    return true;
  }

  detachFromFlutterEngine() {
    if (this?.delegate != null) {
      this?.delegate?.onDetach();
    }
  }

  getAbility(): UIAbility {
    return this.uiAbility!!
  }

  loadContent() {

  }

  shouldAttachEngineToAbility(): boolean {
    return this.parameters![FlutterEntry.ARG_SHOULD_ATTACH_ENGINE_TO_ABILITY] as boolean
  }

  getCachedEngineId(): string {
    return this.parameters![FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_ID] as string
  }

  getCachedEngineGroupId(): string | null {
    return this.parameters![FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_GROUP_ID] as string
  }

  shouldDestroyEngineWithHost(): boolean {
    if ((this.getCachedEngineId() != null && this.getCachedEngineId().length > 0) || this.delegate!!.isFlutterEngineFromHost()) {
      // Only destroy a cached engine if explicitly requested by app developer.
      return false;
    }
    return true;
  }

  getFlutterShellArgs(): FlutterShellArgs {
    return new FlutterShellArgs();
  }

  getDartEntrypointArgs(): string[] {
    if (this.parameters![FlutterAbilityLaunchConfigs.EXTRA_DART_ENTRYPOINT_ARGS]) {
      return this.parameters![FlutterAbilityLaunchConfigs.EXTRA_DART_ENTRYPOINT_ARGS] as Array<string>;
    }
    return new Array<string>()
  }

  getDartEntrypointLibraryUri(): string {
    return "";
  }

  getAppBundlePath(): string {
    return "";
  }

  getDartEntrypointFunctionName(): string {
    if (this.parameters![FlutterAbilityLaunchConfigs.EXTRA_DART_ENTRYPOINT]) {
      return this.parameters![FlutterAbilityLaunchConfigs.EXTRA_DART_ENTRYPOINT] as string;
    }
    return FlutterAbilityLaunchConfigs.DEFAULT_DART_ENTRYPOINT
  }

  getInitialRoute(): string {
    if (this.parameters![FlutterAbilityLaunchConfigs.EXTRA_INITIAL_ROUTE]) {
      return this.parameters![FlutterAbilityLaunchConfigs.EXTRA_INITIAL_ROUTE] as string
    }
    return "";
  }

  getWant(): Want {
    return new Want();
  }

  shouldRestoreAndSaveState(): boolean {
    if (this.parameters![FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_ID] != undefined) {
      return this.parameters![FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_ID] as boolean;
    }
    if (this.getCachedEngineId() != null && this.getCachedEngineId().length > 0) {
      // Prevent overwriting the existing state in a cached engine with restoration state.
      return false;
    }
    return true;
  }

  getPlugins(): List<FlutterPlugin> {
    return new List()
  }

  getExclusiveAppComponent(): ExclusiveAppComponent<UIAbility> | null {
    return this.delegate ? this.delegate : null
  }

  provideFlutterEngine(context: Context): FlutterEngine | null {
    return null;
  }

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    if (this.engineConfigurator) {
      this.engineConfigurator.configureFlutterEngine(flutterEngine)
    }
  }

  cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    if (this.engineConfigurator) {
      this.engineConfigurator.cleanUpFlutterEngine(flutterEngine)
    }
  }

  popSystemNavigator(): boolean {
    return false;
  }
}