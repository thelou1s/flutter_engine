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
import DartExecutor from '../embedding/engine/dart/DartExecutor';
import { EngineLifecycleListener } from '../embedding/engine/FlutterEngine';
import FlutterNapi from '../embedding/engine/FlutterNapi';
import Log from '../util/Log';
import FlutterPluginRegistry from '../app/FlutterPluginRegistry';
import FlutterRunArguments from './FlutterRunArguments';
import { FlutterView } from './FlutterView';

const TAG: string = "FlutterNativeView";

export default class FlutterNativeView {
  private mContext: common.Context;
  private mPluginRegistry: FlutterPluginRegistry;
  private mFlutterNapi: FlutterNapi;
  private dartExecutor: DartExecutor;
  private mFlutterView: FlutterView;
  private applicationIsRunning: boolean;

  constructor(context: common.Context, isBackgroundView?: boolean) {
    if (isBackgroundView) {
      Log.i(TAG, "isBackgroundView is no longer supported and will be ignored");
    }
    this.mContext = context;
    this.mPluginRegistry = new FlutterPluginRegistry();
    this.mFlutterNapi = new FlutterNapi();
    //this.mFlutterNapi.addIsDisplayingFlutterUiListener(this.flutterUiDisplayListener);
    this.dartExecutor = new DartExecutor(this.mFlutterNapi, this.mContext.resourceManager);
    this.mFlutterNapi.addEngineLifecycleListener(new EngineLifecycleListenerImpl(this.mFlutterView, this.mPluginRegistry));
    this.attach(this.mFlutterNapi, this.dartExecutor);
    this.assertAttached(this.mFlutterNapi);
  }

  attach(flutterNapi: FlutterNapi, dartExecutor: DartExecutor): void {
    flutterNapi.attachToNative();
    dartExecutor.onAttachedToNAPI();
  }

  assertAttached(flutterNapi: FlutterNapi): void {
    if (!this.isAttached(flutterNapi)) {
      throw new Error('Platform View is not attached');
    }
  }

  isAttached(flutterNapi: FlutterNapi): boolean {
    return flutterNapi.isAttached();
  }

  detachFromFlutterView(): void {
    this.mPluginRegistry.detach();
    this.mFlutterView = null;
  }

  destroy(): void {
    this.mPluginRegistry.destroy();
    this.dartExecutor.onDetachedFromNAPI();
    this.mFlutterView = null;
    //this.mFlutterNapi.removeIsDisplayingFlutterUiListener(this.flutterUiDisplayListener);
    this.applicationIsRunning = false;
  }

  getDartExecutor(): DartExecutor {
    return this.dartExecutor;
  }

  getPluginRegistry(): FlutterPluginRegistry {
    return this.mPluginRegistry;
  }

  attachViewAndAbility(flutterView: FlutterView, context: common.Context): void {
    this.mFlutterView = flutterView;
    this.mPluginRegistry.attach(flutterView, context);
  }

  runFromBundle(args: FlutterRunArguments): void {
    if (args.entrypoint == null) {
      throw new Error("an entrypoint must be specific");
    }
    this.assertAttached(this.mFlutterNapi);
    if (this.applicationIsRunning) {
      throw new Error("this flutter engine instance is already running an application");
    }
    this.mFlutterNapi.runBundleAndSnapshotFromLibrary(args.bundlePath, args.entrypoint, args.libraryPath, this.mContext.resourceManager, null);
    this.applicationIsRunning = true;
  }

  isApplicationRunning(): boolean {
    return this.applicationIsRunning;
  }

  // getObservatoryUri(): string {
  //   return this.mFlutterNapi.getObservatoryUri();
  // }
}

class EngineLifecycleListenerImpl implements EngineLifecycleListener {
  private flutterView: FlutterView;
  private pluginRegistry: FlutterPluginRegistry;

  onPreEngineRestart(): void {
    if (this.flutterView != null) {
      //this.flutterView.resetAccessibilityTree();
    }

    if (this.pluginRegistry == null) {
      return;
    }

    this.pluginRegistry.onPreEngineRestart();
  }

  onEngineWillDestroy(): void {

  }

  constructor(flutterView: FlutterView, pluginRegistry: FlutterPluginRegistry) {
    this.flutterView = flutterView;
    this.pluginRegistry = pluginRegistry;
  }
}


