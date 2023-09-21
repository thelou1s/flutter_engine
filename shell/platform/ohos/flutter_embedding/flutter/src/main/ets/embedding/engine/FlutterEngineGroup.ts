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

import FlutterEngine from "./FlutterEngine"
import common from '@ohos.app.ability.common'
import FlutterLoader from './loader/FlutterLoader'
import FlutterInjector from '../../FlutterInjector'
import { DartEntrypoint } from './dart/DartExecutor'

export default class FlutterEngineGroup {
  private activeEngines: Array<FlutterEngine> = new Array();

  constructor() {

  }

  async checkLoader(context: common.Context, args: Array<string>) {
    var loader: FlutterLoader = FlutterInjector.getInstance().getFlutterLoader();
    if (!loader.initialized) {
      await loader.startInitialization(context.getApplicationContext());
      loader.ensureInitializationComplete(args);
    }
  }

  async createAndRunEngineByOptions(options: Options) {
    let engine: FlutterEngine = null;
    let context: common.Context = options.getContext();
    let dartEntrypoint: DartEntrypoint = options.getDartEntrypoint();
    let initialRoute: string = options.getInitialRoute();
    let dartEntrypointArgs: Array<string> = options.getDartEntrypointArgs();
    //TODO:接入PlatformViewsController
    let automaticallyRegisterPlugins: boolean = options.getAutomaticallyRegisterPlugins();
    let waitForRestorationData: boolean = options.getWaitForRestorationData();

    if (dartEntrypoint == null) {
      dartEntrypoint = DartEntrypoint.createDefault();
    }

    if (this.activeEngines.length == 0) {
      engine = this.createEngine(context);
      await engine.init(context, null, // String[]. The Dart VM has already started, this arguments will have no effect.
        automaticallyRegisterPlugins, // boolean.
        waitForRestorationData, // boolean.
        this)
      if (initialRoute != null) {
        engine.getNavigationChannel().setInitialRoute(initialRoute);
      }
    } else {
      engine = await this.activeEngines[0]
        .spawn(
          context,
          dartEntrypoint,
          initialRoute,
          dartEntrypointArgs,
          automaticallyRegisterPlugins,
          waitForRestorationData);
    }
    this.activeEngines.push(engine);

    const engineToCleanUpOnDestroy = engine;
    engine.addEngineLifecycleListener({
      onPreEngineRestart(): void {
        // No-op. Not interested.
      },
      onEngineWillDestroy(): void {
        this.activeEngines.remove(engineToCleanUpOnDestroy);
      }
    });
    return engine;
  }

  createEngine(context: common.Context): FlutterEngine {
    return new FlutterEngine(context, null, null);
  }
}

export class Options {
  private context: common.Context;
  private dartEntrypoint: DartEntrypoint;
  private initialRoute: string;
  private dartEntrypointArgs: Array<string>;
  //TODO:声明成员platformViewsController:PlatformViewsController
  private automaticallyRegisterPlugins: boolean = true;
  private waitForRestorationData: boolean = false;

  constructor(context: common.Context) {
    this.context = context;
  }

  getContext(): any {
    return this.context;
  }

  getDartEntrypoint(): DartEntrypoint {
    return this.dartEntrypoint;
  }

  getInitialRoute(): string {
    return this.initialRoute;
  }

  getDartEntrypointArgs(): Array<string> {
    return this.dartEntrypointArgs;
  }

  getAutomaticallyRegisterPlugins(): boolean {
    return this.automaticallyRegisterPlugins;
  }

  getWaitForRestorationData(): boolean {
    return this.waitForRestorationData;
  }
  //TODO:实现getPlatformViewsController

  setDartEntrypoint(dartEntrypoint: DartEntrypoint): Options {
    this.dartEntrypoint = dartEntrypoint;
    return this;
  }

  setInitialRoute(initialRoute: string): Options {
    this.initialRoute = initialRoute;
    return this;
  }

  setDartEntrypointArgs(dartEntrypointArgs: Array<string>): Options {
    this.dartEntrypointArgs = dartEntrypointArgs;
    return this;
  }

  setAutomaticallyRegisterPlugins(automaticallyRegisterPlugins: boolean): Options {
    this.automaticallyRegisterPlugins = automaticallyRegisterPlugins;
    return this;
  }

  setWaitForRestorationData(waitForRestorationData: boolean): Options {
    this.waitForRestorationData = waitForRestorationData;
    return this;
  }
  //TODO:实现setPlatformViewsController
}