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

import FlutterNapi from './embedding/engine/FlutterNapi';
import FlutterLoader from './embedding/engine/loader/FlutterLoader';

/**
 * flutter相关主要类的单例持有，帮助实现自身和其他类的实例化管理
 */
export default class FlutterInjector {
  private static instance: FlutterInjector;

  private flutterLoader: FlutterLoader;

  static getInstance(): FlutterInjector {
    if (FlutterInjector.instance == null) {
      FlutterInjector.instance = new FlutterInjector();
    }
    return FlutterInjector.instance;
  }
  /**
   * 初始化
   */
  private constructor() {
    this.flutterLoader = new FlutterLoader(this.getFlutterNapi());
  }

  getFlutterLoader(): FlutterLoader {
    return this.flutterLoader;
  }

  getFlutterNapi(): FlutterNapi {
    return new FlutterNapi();
  }
}