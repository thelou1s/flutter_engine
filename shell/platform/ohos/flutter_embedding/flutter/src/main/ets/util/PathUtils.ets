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
import fs from '@ohos.file.fs';
import Log from './Log';

/**
 * ohos路径获取工具
 */
const TAG: string = "PathUtils";

export default class PathUtils {
  static getFilesDir(context: common.Context): string {
    return context.filesDir;
  }

  static getCacheDirectory(context: common.Context): string {
    return context.cacheDir;
  }

  static getDataDirectory(context: common.Context): string | null {
    const name = "flutter";
    const flutterDir = context.filesDir + "/" + name;
    if (!fs.accessSync(flutterDir)) {
      try {
        fs.mkdirSync(flutterDir);
      } catch (err) {
        Log.e(TAG, "mkdirSync failed err:" + err);
        return null;
      }
    }
    return flutterDir;
  }
}