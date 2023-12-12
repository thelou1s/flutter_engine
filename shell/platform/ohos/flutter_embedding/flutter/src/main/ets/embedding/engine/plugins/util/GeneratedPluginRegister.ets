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
import List from '@ohos.util.List';
import Log from '../../../../util/Log';
import FlutterEngine from '../../FlutterEngine';
import { FlutterPlugin } from '../FlutterPlugin';

const TAG = "GeneratedPluginRegister";

export default class GeneratedPluginRegister {
  // 因为ets不支持类似java反射功能能找到GeneratedPluginRegistrant，所以这里只能直接获取List<FlutterPlugin>
  public static registerGeneratedPlugins(flutterEngine: FlutterEngine, plugins: List<FlutterPlugin>) {
    try {
      for (let index = 0; index < plugins.length; index++) {
        const plugin = plugins[index] as FlutterPlugin;
        flutterEngine.getPlugins()?.add(plugin)
      }
    } catch (e) {
      Log.e(
        TAG,
        "Tried to automatically register plugins with FlutterEngine ("
          + flutterEngine
          + ") but could not find or invoke the GeneratedPluginRegistrant.");
      Log.e(TAG, "Received exception while registering", e);
    }
  }
}