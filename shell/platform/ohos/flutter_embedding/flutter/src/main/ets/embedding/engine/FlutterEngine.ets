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

import LifecycleChannel from './systemchannels/LifecycleChannel';
import DartExecutor, { DartEntrypoint } from './dart/DartExecutor';
import FlutterShellArgs from './FlutterShellArgs';
import FlutterInjector from '../../FlutterInjector';
import FlutterLoader from './loader/FlutterLoader';
import common from '@ohos.app.ability.common';
import resourceManager from '@ohos.resourceManager';
import FlutterNapi from './FlutterNapi';
import NavigationChannel from './systemchannels/NavigationChannel';
import Log from '../../util/Log';
import TestChannel from './systemchannels/TestChannel'
import FlutterEngineConnectionRegistry from './FlutterEngineConnectionRegistry';
import PluginRegistry from './plugins/PluginRegistry';
import AbilityControlSurface from './plugins/ability/AbilityControlSurface';
import TextInputChannel from './systemchannels/TextInputChannel';
import TextInputPlugin from '../../plugin/editing/TextInputPlugin';
import PlatformChannel from './systemchannels/PlatformChannel';
import FlutterEngineGroup from './FlutterEngineGroup';
import SystemChannel from './systemchannels/SystemChannel';
import MouseCursorChannel from './systemchannels/MouseCursorChannel';
import RestorationChannel from './systemchannels/RestorationChannel';
import LocalizationChannel from './systemchannels/LocalizationChannel';
import AccessibilityChannel from './systemchannels/AccessibilityChannel';
import LocalizationPlugin from '../../plugin/localization/LocalizationPlugin'
import SettingsChannel from './systemchannels/SettingsChannel';
import PlatformViewsController from '../../plugin/platform/PlatformViewsController';
import { FlutterPlugin } from './plugins/FlutterPlugin';
import List from '@ohos.util.List';
import GeneratedPluginRegister from './plugins/util/GeneratedPluginRegister';


const TAG = "FlutterEngine";

/**
 * 操作FlutterEngin相关
 */
export default class FlutterEngine implements EngineLifecycleListener{
  private engineLifecycleListeners = new Set<EngineLifecycleListener>();

  dartExecutor: DartExecutor;
  private flutterLoader: FlutterLoader;
  private assetManager: resourceManager.ResourceManager;
  //channel定义
  private lifecycleChannel: LifecycleChannel | null = null;
  private navigationChannel: NavigationChannel | null = null;
  private textInputChannel: TextInputChannel | null = null;
  private testChannel: TestChannel | null = null;
  private platformChannel: PlatformChannel | null = null;
  private systemChannel: SystemChannel | null = null;
  private mouseCursorChannel: MouseCursorChannel | null = null;
  private restorationChannel: RestorationChannel | null = null;

  private accessibilityChannel: AccessibilityChannel | null = null;
  private localeChannel: LocalizationChannel | null = null;
  private flutterNapi: FlutterNapi;
  private pluginRegistry: FlutterEngineConnectionRegistry | null = null;
  private textInputPlugin: TextInputPlugin | null = null;
  private localizationPlugin: LocalizationPlugin | null = null;
  private settingsChannel: SettingsChannel | null = null;
  private platformViewsController: PlatformViewsController;

  /**
   * 需要初始化的工作：
   * 1、初始化DartExecutor
   * 2、初始化所有channel
   * 3、初始化plugin
   * 4、初始化flutterLoader
   * 5、初始化flutterNapi
   * 6、engineLifecycleListeners
   */
  constructor(context: common.Context, flutterLoader: FlutterLoader | null, flutterNapi: FlutterNapi | null, platformViewsController: PlatformViewsController) {
    const injector: FlutterInjector = FlutterInjector.getInstance();

    if(flutterNapi == null){
      flutterNapi = FlutterInjector.getInstance().getFlutterNapi();
    }
    this.flutterNapi = flutterNapi;
    this.assetManager = context.resourceManager;

    this.dartExecutor = new DartExecutor(this.flutterNapi, this.assetManager);
    this.dartExecutor.onAttachedToNAPI();

    if(flutterLoader == null){
      flutterLoader = injector.getFlutterLoader();
    }
    this.flutterLoader = flutterLoader;

    if(platformViewsController == null) {
      platformViewsController = new PlatformViewsController();
    }
    this.platformViewsController = platformViewsController;
    this.platformViewsController.attach(context, null, this.dartExecutor);
  }

  async init(context: common.Context, dartVmArgs: Array<string> | null, automaticallyRegisterPlugins: boolean,
             waitForRestorationData: boolean, group: FlutterEngineGroup | null, plugins: List<FlutterPlugin> | null) {
    if (!this.flutterNapi.isAttached()) {
      await this.flutterLoader.startInitialization(context)
      this.flutterLoader.ensureInitializationComplete(dartVmArgs);
    }
    //channel初始化
    this.lifecycleChannel = new LifecycleChannel(this.dartExecutor);
    this.navigationChannel = new NavigationChannel(this.dartExecutor);
    this.textInputChannel = new TextInputChannel(this.dartExecutor);
    this.testChannel = new TestChannel(this.dartExecutor);
    this.platformChannel = new PlatformChannel(this.dartExecutor);
    this.systemChannel = new SystemChannel(this.dartExecutor);
    this.mouseCursorChannel = new MouseCursorChannel(this.dartExecutor);
    this.restorationChannel = new RestorationChannel(this.dartExecutor, waitForRestorationData);
    this.settingsChannel = new SettingsChannel(this.dartExecutor);

    this.localeChannel = new LocalizationChannel(this.dartExecutor);
    this.accessibilityChannel = new AccessibilityChannel(this.dartExecutor, this.flutterNapi);
    this.flutterNapi.addEngineLifecycleListener(this);
    this.localizationPlugin = new LocalizationPlugin(context, this.localeChannel);

    // It should typically be a fresh, unattached NAPI. But on a spawned engine, the NAPI instance
    // is already attached to a native shell. In that case, the Java FlutterEngine is created around
    // an existing shell.
    if (!this.flutterNapi.isAttached()) {
      this.attachToNapi();
    }

    this.pluginRegistry = new FlutterEngineConnectionRegistry(context.getApplicationContext(), this, this.flutterLoader, group!);
    this.localizationPlugin.sendLocaleToFlutter();

    if (automaticallyRegisterPlugins && plugins) {
      GeneratedPluginRegister.registerGeneratedPlugins(this, plugins);
    }
  }

  private attachToNapi(): void {
    Log.d(TAG, "Attaching to NAPI.");
    this.flutterNapi.attachToNative();

    if (!this.isAttachedToNapi()) {
      throw new Error("FlutterEngine failed to attach to its native Object reference.");
    }
    this.flutterNapi.setLocalizationPlugin(this.localizationPlugin);
  }

  async spawn(context: common.Context,
              dartEntrypoint: DartEntrypoint,
              initialRoute: string,
              dartEntrypointArgs: Array<string>,
              platformViewsController: PlatformViewsController,
              automaticallyRegisterPlugins: boolean,
              waitForRestorationData: boolean,
              plugins: List<FlutterPlugin> | null) {
    if (!this.isAttachedToNapi()) {
      throw new Error(
        "Spawn can only be called on a fully constructed FlutterEngine");
    }

    const newFlutterNapi =
    this.flutterNapi.spawn(
      dartEntrypoint.dartEntrypointFunctionName,
      dartEntrypoint.dartEntrypointLibrary,
      initialRoute,
      dartEntrypointArgs);
    const flutterEngine = new FlutterEngine(
      context,
      null,
      newFlutterNapi,
      platformViewsController
    );
    await flutterEngine.init(context, null, automaticallyRegisterPlugins, waitForRestorationData, null, plugins)
    return flutterEngine
  }

  private isAttachedToNapi(): boolean {
    return this.flutterNapi.isAttached();
  }

  getLifecycleChannel(): LifecycleChannel | null {
    return this.lifecycleChannel;
  }

  getNavigationChannel(): NavigationChannel | null {
    return this.navigationChannel;
  }

  getTextInputChannel(): TextInputChannel | null {
    return this.textInputChannel;
  }

  getPlatformChannel(): PlatformChannel | null {
    return this.platformChannel;
  }

  getSystemChannel(): SystemChannel | null {
    return this.systemChannel;
  }

  getLocaleChannel(): LocalizationChannel | null {
    return this.localeChannel;
  }

  getMouseCursorChannel(): MouseCursorChannel | null {
    return this.mouseCursorChannel;
  }

  getFlutterNapi(): FlutterNapi {
    return this.flutterNapi;
  }

  getDartExecutor(): DartExecutor {
    return this.dartExecutor
  }

  getPlugins(): PluginRegistry | null {
    return this.pluginRegistry;
  }

  getAbilityControlSurface(): AbilityControlSurface | null {
    return this.pluginRegistry;
  }

  getSettingsChannel() {
    return this.settingsChannel;
  }

  onPreEngineRestart(): void {

  }

  onEngineWillDestroy(): void {

  }

  addEngineLifecycleListener(listener: EngineLifecycleListener): void {
    this.engineLifecycleListeners.add(listener);
  }

  removeEngineLifecycleListener(listener: EngineLifecycleListener): void {
    this.engineLifecycleListeners.delete(listener);
  }

  destroy(): void {
    Log.d(TAG, "Destroying.");
    this.engineLifecycleListeners.forEach(listener => listener.onEngineWillDestroy())
    this.flutterNapi.removeEngineLifecycleListener(this);
    this.pluginRegistry?.detachFromAbility();
    this.platformViewsController?.onDetachedFromNapi();
  }

  getRestorationChannel(): RestorationChannel | null {
    return this.restorationChannel;
  }

  getAccessibilityChannel(): AccessibilityChannel | null {
    return this.accessibilityChannel;
  }

  getLocalizationPlugin(): LocalizationPlugin | null {
    return this.localizationPlugin;
  }

  getSystemLanguages(): void {
    return this.flutterNapi.getSystemLanguages();
  }

  getPlatformViewsController(): PlatformViewsController | null {
    return this.platformViewsController;
  }
}

export interface EngineLifecycleListener {
  onPreEngineRestart(): void;

  onEngineWillDestroy(): void;
}