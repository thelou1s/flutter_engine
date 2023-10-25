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

export default class FlutterEngineCache {
  private static instance : FlutterEngineCache;
  private cachedEngines: Map<String, FlutterEngine> = new Map();

  static getInstance(): FlutterEngineCache {
    if (FlutterEngineCache.instance == null) {
      FlutterEngineCache.instance = new FlutterEngineCache();
    }
    return FlutterEngineCache.instance;
  }
  /**
   * 返回engineId对应的FlutterEngine是否存在
   */
  contains(engineId: String) : boolean {
    return this.cachedEngines.has(engineId);
  }

  /**
   * 返回engineId对应的FlutterEngine
   */
  get(engineId: String) : FlutterEngine | null {
    return this.cachedEngines.get(engineId) || null;
  }
  /**
   * 将传入的FlutterEngine与engineId放在缓存中
   */
  put(engineId :String, engine: FlutterEngine | null): void {
    if(engine != null) {
      this.cachedEngines.set(engineId, engine);
    } else {
      this.cachedEngines.delete(engineId);
    }
  }
  /**
   * 移除engineId对应的FlutterEngine
   */
  remove(engineId: String) : void {
    this.put(engineId, null);
  }

  /**
   * 移除cachedEngines所有中所有的FlutterEngine
   */
  clear():void {
    this.cachedEngines.clear();
  }
}