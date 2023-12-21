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
import FlutterEngineConfigurator from './FlutterEngineConfigurator';
import FlutterEngineProvider from './FlutterEngineProvider';
import FlutterEngine from '../engine/FlutterEngine';
import PlatformPlugin, { PlatformPluginDelegate } from '../../plugin/PlatformPlugin';
import Want from '@ohos.app.ability.Want';
import FlutterShellArgs from '../engine/FlutterShellArgs';
import DartExecutor, { DartEntrypoint } from '../engine/dart/DartExecutor';
import FlutterAbilityLaunchConfigs from './FlutterAbilityLaunchConfigs';
import Log from '../../util/Log';
import FlutterInjector from '../../FlutterInjector';
import UIAbility from '@ohos.app.ability.UIAbility';
import ExclusiveAppComponent from './ExclusiveAppComponent';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import TextInputPlugin from '../../plugin/editing/TextInputPlugin';
import { FlutterPlugin } from '../engine/plugins/FlutterPlugin';
import FlutterEngineCache from '../engine/FlutterEngineCache';
import FlutterEngineGroupCache from '../engine/FlutterEngineGroupCache';
import FlutterEngineGroup, { Options } from '../engine/FlutterEngineGroup';
import MouseCursorPlugin, { MouseCursorViewDelegate } from '../../plugin/mouse/MouseCursorPlugin';
import Settings from './Settings';
import FlutterNapi from '../engine/FlutterNapi';
import List from '@ohos.util.List';
import GeneratedPluginRegister from '../engine/plugins/util/GeneratedPluginRegister';

const TAG = "FlutterAbilityDelegate";
const PLUGINS_RESTORATION_BUNDLE_KEY = "plugins";
const FRAMEWORK_RESTORATION_BUNDLE_KEY = "framework";

/**
 * 主要职责：
 * 1、初始化engine
 * 2、处理ability生命周期回调
 */
class FlutterAbilityDelegate implements ExclusiveAppComponent<UIAbility> {
  private host?: Host | null;
  flutterEngine?: FlutterEngine | null;
  platformPlugin?: PlatformPlugin;
  private context?: common.Context;
  private textInputPlugin?: TextInputPlugin;
  private isFlutterEngineFromHost: boolean = false;
  private engineGroup?: FlutterEngineGroup;
  private settings?: Settings;
  private isHost:boolean = false;

  constructor(host?: Host) {
    this.host = host;
    if (this.host) {
      this.isHost = true;
    }
  }

  /**
   * 是否还attach在ability上
   */
  isAttached = false;

  async onAttach(context: common.Context): Promise<void> {
    this.context = context;
    this.ensureAlive();
    if (this.flutterEngine == null) {
      await this.setupFlutterEngine();
    }
    //shouldAttachEngineToActivity
    if (this.host?.shouldAttachEngineToActivity()) {
      // Notify any plugins that are currently attached to our FlutterEngine that they
      // are now attached to an Ability.
      Log.d(TAG, "Attaching FlutterEngine to the Ability that owns this delegate.");
      this.flutterEngine?.getAbilityControlSurface()?.attachToAbility(this);
    }

    //providePlatformPlugin

    //configureFlutterEngine
    this.isAttached = true;
    const plugins = this.host?.getPlugins()
    if (plugins) {
      GeneratedPluginRegister.registerGeneratedPlugins(this.flutterEngine!, plugins);
    }
    Log.d(TAG, "onAttach end start loadcontent")
    this.host?.loadContent()
    if (this.flutterEngine) {
      this.textInputPlugin = new TextInputPlugin(this.flutterEngine.getTextInputChannel()!);
      this.platformPlugin = new PlatformPlugin(this.flutterEngine.getPlatformChannel()!, this.context);
      this.settings = new Settings(this.flutterEngine.getSettingsChannel()!);
      this.flutterEngine.getSystemLanguages();
    }
  }

  /**
   * 加载app.so资源或者snapshot
   */
  private doInitialFlutterViewRun(): void {
    let initialRoute = this.host?.getInitialRoute();
    if (initialRoute == null && this.host != null) {
      initialRoute = this.maybeGetInitialRouteFromIntent(this.host.getWant());

    }
    if (initialRoute == null) {
      initialRoute = FlutterAbilityLaunchConfigs.DEFAULT_INITIAL_ROUTE;
    }
    const libraryUri = this.host?.getDartEntrypointLibraryUri();
    Log.d(TAG, "Executing Dart entrypoint: " + this.host?.getDartEntrypointFunctionName() + ", library uri: " + libraryUri == null ? "\"\"" : libraryUri + ", and sending initial route: " + initialRoute);

    // The engine needs to receive the Flutter app's initial route before executing any
    // Dart code to ensure that the initial route arrives in time to be applied.
    this.flutterEngine?.getNavigationChannel()?.setInitialRoute(initialRoute ?? '');

    let appBundlePathOverride = this.host?.getAppBundlePath();
    if (appBundlePathOverride == null || appBundlePathOverride == '') {
      appBundlePathOverride = FlutterInjector.getInstance().getFlutterLoader().findAppBundlePath();
    }

    const dartEntrypoint: DartEntrypoint = new DartEntrypoint(
      appBundlePathOverride,
      this.host?.getDartEntrypointLibraryUri() ?? '',
      this.host?.getDartEntrypointFunctionName() ?? ''
    );
    this.flutterEngine?.dartExecutor.executeDartEntrypoint(dartEntrypoint, this.host?.getDartEntrypointArgs());
  }

  private maybeGetInitialRouteFromIntent(want: Want): string {
    return '';
  }


  /**
   * 通过参数，配置flutterEngine
   * @param want
   */
  onRestoreInstanceState(want: Want) {
    let frameworkState = want.parameters != null
      ? want.parameters[FRAMEWORK_RESTORATION_BUNDLE_KEY] as Uint8Array
      : new Uint8Array(1).fill(0);
    if (this.host?.shouldRestoreAndSaveState()) {
      this.flutterEngine?.getRestorationChannel()?.setRestorationData(frameworkState);
    }
  }

  /**
   * 初始化flutterEngine
   */
  async setupFlutterEngine() {
    // First, check if the host wants to use a cached FlutterEngine.
    const cachedEngineId = this.host?.getCachedEngineId();
    Log.d(TAG, "cachedEngineId=" + cachedEngineId);
    if (cachedEngineId && cachedEngineId.length > 0) {
      this.flutterEngine = FlutterEngineCache.getInstance().get(cachedEngineId);
      this.isFlutterEngineFromHost = true;
      if (this.flutterEngine == null) {
        throw new Error(
            "The requested cached FlutterEngine did not exist in the FlutterEngineCache: '"
                + cachedEngineId
                + "'");
      }
      return;
    }

    // Second, defer to subclasses for a custom FlutterEngine.
    if (this.host && this.context) {
      this.flutterEngine = this.host.provideFlutterEngine(this.context);
    }
    if (this.flutterEngine != null) {
      this.isFlutterEngineFromHost = true;
      return;
    }

    // Third, check if the host wants to use a cached FlutterEngineGroup
    // and create new FlutterEngine using FlutterEngineGroup#createAndRunEngine
    const cachedEngineGroupId = this.host?.getCachedEngineGroupId();
    Log.d(TAG, "cachedEngineGroupId=" + cachedEngineGroupId);
    if (cachedEngineGroupId != null) {
      const flutterEngineGroup = FlutterEngineGroupCache.instance.get(cachedEngineGroupId);
      if (flutterEngineGroup == null) {
        throw new Error(
            "The requested cached FlutterEngineGroup did not exist in the FlutterEngineGroupCache: '"
                + cachedEngineGroupId
                + "'");
      }

      if (this.context != null) {
        this.flutterEngine = await flutterEngineGroup.createAndRunEngineByOptions(
          this.addEntrypointOptions(new Options(this.context)));
      }
      this.isFlutterEngineFromHost = false;
      return;
    }

    // Our host did not provide a custom FlutterEngine. Create a FlutterEngine to back our
    // FlutterView.
    Log.d(
        TAG,
        "No preferred FlutterEngine was provided. Creating a new FlutterEngine for this FlutterAbility.");

    let group = this.engineGroup;
    if (group == null && this.context != null) {
      group = new FlutterEngineGroup();
      const flutterShellArgs = this.host? this.host.getFlutterShellArgs(): new FlutterShellArgs();
      await group.checkLoader(this.context, flutterShellArgs.toArray() ?? []);
      this.engineGroup = group;
    }
    if (this.context) {
      this.flutterEngine = await group?.createAndRunEngineByOptions(this.addEntrypointOptions(new Options(this.context)
        .setAutomaticallyRegisterPlugins(false)
        .setWaitForRestorationData(this.host?.shouldRestoreAndSaveState() || false)));
    }
    this.isFlutterEngineFromHost = false;
  }

  addEntrypointOptions(options: Options): Options {
    let appBundlePathOverride = this.host?.getAppBundlePath();
    if (appBundlePathOverride == null || appBundlePathOverride.length == 0) {
      appBundlePathOverride = FlutterInjector.getInstance().getFlutterLoader().findAppBundlePath();
    }

    const dartEntrypoint = new DartEntrypoint(appBundlePathOverride ?? '',
      '',
      this.host?.getDartEntrypointFunctionName() ?? '');
    let initialRoute = this.host?.getInitialRoute();
    if (initialRoute == null && this.host != null) {
      initialRoute = this.maybeGetInitialRouteFromIntent(this.host.getWant());
    }
    if (initialRoute == null) {
      initialRoute = FlutterAbilityLaunchConfigs.DEFAULT_INITIAL_ROUTE;
    }
    return options
      .setDartEntrypoint(dartEntrypoint)
      .setInitialRoute(initialRoute)
      .setDartEntrypointArgs(this.host?.getDartEntrypointArgs() ?? []);
  }

  /**
   * 释放所有持有对象
   */
  release() {
    this.host = null;
    this.flutterEngine = null;
  }

  onDetach() {
    if (this.host?.shouldAttachEngineToActivity()) {
      // Notify plugins that they are no longer attached to an Activity.
      Log.d(TAG, "Detaching FlutterEngine from the Ability");
      this.flutterEngine?.getAbilityControlSurface()?.detachFromAbility();
    }
  }

  onLowMemory(): void {
    this.getFlutterNapi()?.notifyLowMemoryWarning();
    this.flutterEngine?.getSystemChannel()?.sendMemoryPressureWarning();
  }

  /**
   * 生命周期回调
   */

  onCreate() {
    this.ensureAlive();
    if (this.shouldDispatchAppLifecycleState()) {
      this.flutterEngine?.getLifecycleChannel()?.appIsResumed();
    }
  }

  onDestroy() {
    this.ensureAlive();
    if (this.shouldDispatchAppLifecycleState()) {
      this.flutterEngine?.getLifecycleChannel()?.appIsDetached();
    }
    this.textInputPlugin?.detach();
  }

  onWindowStageCreate() {
    this.ensureAlive();
    this.doInitialFlutterViewRun();
    if (this.shouldDispatchAppLifecycleState()) {
      this.flutterEngine?.getLifecycleChannel()?.appIsResumed();
    }
  }

  onWindowStageDestroy() {

  }

  onWindowFocusChanged(hasFocus: boolean):void {
    if (this.shouldDispatchAppLifecycleState()) {
      this.flutterEngine?.getAbilityControlSurface()?.onWindowFocusChanged(hasFocus);
      if (hasFocus) {
        this.flutterEngine?.getLifecycleChannel()?.aWindowIsFocused();
      } else {
        this.flutterEngine?.getLifecycleChannel()?.noWindowsAreFocused();
      }
    }
  }

  onForeground() {
    this.ensureAlive();
    if (this.shouldDispatchAppLifecycleState()) {
      this.flutterEngine?.getLifecycleChannel()?.appIsResumed();
    }
  }

  onBackground() {
    if (this.shouldDispatchAppLifecycleState()) {
      this.flutterEngine?.getLifecycleChannel()?.noWindowsAreFocused();
      this.flutterEngine?.getLifecycleChannel()?.appIsPaused();
    }
  }

  /**
   * 生命周期回调结束
   */

  shouldDispatchAppLifecycleState(): boolean {
    if (!this.isHost) {
      return this.isAttached;
    }
    if (this.host == null) {
      return false;
    }
    return this.host.shouldDispatchAppLifecycleState() && this.isAttached;
  }

  ensureAlive() {
    if (this.isHost && this.host == null) {
      throw new Error("Cannot execute method on a destroyed FlutterAbilityDelegate.");
    }
  }

  getFlutterNapi() : FlutterNapi | null {
    return this.flutterEngine?.getFlutterNapi() ?? null
  }

  detachFromFlutterEngine() {
    if (this.host?.shouldDestroyEngineWithHost()) {
      // The host owns the engine and should never have its engine taken by another exclusive
      // activity.
      throw new Error(
        "The internal FlutterEngine created by "
          + this.host
          + " has been attached to by another activity. To persist a FlutterEngine beyond the "
          + "ownership of this ablity, explicitly create a FlutterEngine");
    }

    // Default, but customizable, behavior is for the host to call {@link #onDetach}
    // deterministically as to not mix more events during the lifecycle of the next exclusive
    // activity.
    this.host?.detachFromFlutterEngine();
  }

  getAppComponent(): UIAbility {
    const ability = this.host?.getAbility();
    if (ability == null) {
      throw new Error(
        "FlutterActivityAndFragmentDelegate's getAppComponent should only "
          + "be queried after onAttach, when the host's ability should always be non-null");
    }
    return ability;
  }

  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    this.ensureAlive()
    if (this.flutterEngine != null) {
      Log.i(TAG, "Forwarding onNewWant() to FlutterEngine and sending pushRouteInformation message.");
      this.flutterEngine?.getAbilityControlSurface()?.onNewWant(want, launchParams);
      const initialRoute = this.maybeGetInitialRouteFromIntent(want);
      if (initialRoute && initialRoute.length > 0) {
        this.flutterEngine?.getNavigationChannel()?.pushRouteInformation(initialRoute);
      }
    } else {
      Log.w(TAG, "onNewIntent() invoked before FlutterFragment was attached to an Activity.");
    }
  }

  onSaveState(reason: AbilityConstant.StateType, wantParam: Record<string, Object>): AbilityConstant.OnSaveResult {
    Log.i(TAG, "onSaveInstanceState. Giving framework and plugins an opportunity to save state.");
    this.ensureAlive();
    if (this.host?.shouldRestoreAndSaveState()) {
      wantParam[FRAMEWORK_RESTORATION_BUNDLE_KEY] = this.flutterEngine!.getRestorationChannel()!.getRestorationData();
    }
    if (this.host?.shouldAttachEngineToActivity()) {
      const plugins:Record<string, Object> = {}
      const result = this.flutterEngine?.getAbilityControlSurface()?.onSaveState(reason, plugins);
      wantParam[PLUGINS_RESTORATION_BUNDLE_KEY] = plugins;
      return result ?? AbilityConstant.OnSaveResult.ALL_REJECT
    }
    return AbilityConstant.OnSaveResult.ALL_REJECT
  }

  addPlugin(plugin: FlutterPlugin): void {
    this.flutterEngine?.getPlugins()?.add(plugin)
  }

  removePlugin(plugin: FlutterPlugin): void {
    this.flutterEngine?.getPlugins()?.remove(plugin.getUniqueClassName())
  }

  sendSettings(): void {
    this.settings?.sendSettings()
  }
}


/**
 * FlutterAbility句柄
 */
interface Host extends FlutterEngineProvider, FlutterEngineConfigurator, PlatformPluginDelegate, MouseCursorViewDelegate {

  getAbility(): UIAbility;

  loadContent():void;

  shouldDispatchAppLifecycleState(): boolean;

  detachFromFlutterEngine();

  shouldAttachEngineToActivity(): boolean;

  getCachedEngineId(): string;

  getCachedEngineGroupId(): string;

  /**
   * Returns true if the {@link io.flutter.embedding.engine.FlutterEngine} used in this delegate
   * should be destroyed when the host/delegate are destroyed.
   */
  shouldDestroyEngineWithHost(): boolean;

  /** Returns the {@link FlutterShellArgs} that should be used when initializing Flutter. */
  getFlutterShellArgs(): FlutterShellArgs;

  /** Returns arguments that passed as a list of string to Dart's entrypoint function. */
  getDartEntrypointArgs(): Array<string>;

  /**
   * Returns the URI of the Dart library which contains the entrypoint method (example
   * "package:foo_package/main.dart"). If null, this will default to the same library as the
   * `main()` function in the Dart program.
   */
  getDartEntrypointLibraryUri(): string;

  /** Returns the path to the app bundle where the Dart code exists. */
  getAppBundlePath(): string;

  /**
   * Returns the Dart entrypoint that should run when a new {@link
   * io.flutter.embedding.engine.FlutterEngine} is created.
   */
  getDartEntrypointFunctionName(): string;

  /** Returns the initial route that Flutter renders. */
  getInitialRoute(): string;

  getWant(): Want;

  shouldRestoreAndSaveState(): boolean;

  /** Return the plugins */
  getPlugins(): List<FlutterPlugin>;
}

export { Host, FlutterAbilityDelegate }