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
import FlutterAbilityLaunchConfigs, { ParamsConfigs } from './FlutterAbilityLaunchConfigs';
import Log from '../../util/Log';
import { FlutterView } from '../../view/FlutterView';
import FlutterManager from './FlutterManager';
import window from '@ohos.window';
import FlutterEngineConfigurator from './FlutterEngineConfigurator';

const TAG = "FlutterEntry";

export default class FlutterEntry implements Host {
  private static ARG_SHOULD_ATTACH_ENGINE_TO_ABILITY: string =  "should_attach_engine_to_ability";

  protected uiAbility: UIAbility | null = null
  protected delegate: FlutterAbilityAndEntryDelegate | null = null
  private flutterView: FlutterView | null = null
  private context: Context;
  private windowStage: window.WindowStage | null = null
  private parameters: ParamsConfigs;
  private engineConfigurator: FlutterEngineConfigurator | null = null
  private hasInit: boolean = false;
  
  constructor(context: Context, params: ParamsConfigs) {
    this.context = context;
    this.uiAbility = FlutterManager.getInstance().getUIAbility(context);
    this.parameters = params;
    this.windowStage = FlutterManager.getInstance().getWindowStage(this.uiAbility);
    this.hasInit = false;
  }

  async aboutToAppear() {
    Log.i(TAG, 'aboutToAppear');
    if (this.hasInit == false) {
      this.delegate = new FlutterAbilityAndEntryDelegate(this);
      this.flutterView = this.delegate?.createView(this.context);
      await this?.delegate?.onAttach(this.context);
      Log.i(TAG, 'onAttach end');
      this?.delegate?.platformPlugin?.setUIAbilityContext(this.uiAbility!!.context);
      this.delegate?.onCreate();
      this.delegate?.onWindowStageCreate()
      this.windowStage?.on('windowStageEvent', this.windowStageEventCallback);
      this.hasInit = true;
    }
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
      this.delegate?.release()
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
    return this.parameters!.should_attach_engine_to_ability as boolean
  }

  getCachedEngineId(): string {
    return this.parameters!.cached_engine_id as string
  }

  getCachedEngineGroupId(): string | null {
    return this.parameters!.cached_engine_group_id as string
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
    if (this.parameters!.dart_entrypoint_args) {
      return this.parameters!.dart_entrypoint_args as Array<string>;
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
    if (this.parameters!.dart_entrypoint) {
      return this.parameters!.dart_entrypoint as string;
    }
    return FlutterAbilityLaunchConfigs.DEFAULT_DART_ENTRYPOINT
  }

  getInitialRoute(): string {
    if (this.parameters!.route) {
      return this.parameters!.route as string
    }
    return "";
  }

  getWant(): Want {
    return new Want();
  }

  shouldRestoreAndSaveState(): boolean {
    if (this.parameters!.cached_engine_id != undefined) {
      return true;
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