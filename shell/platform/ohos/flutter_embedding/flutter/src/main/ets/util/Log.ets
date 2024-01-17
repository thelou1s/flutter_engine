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

import HiLog from '@ohos.hilog';

const DOMAIN: number = 0x00FF;
const TAG = "Flutter";
const SYMBOL = " --> ";
// const FILTER_KEYS = [
//   new RegExp('hide', "gi")
// ]

// export function filterKey(target: any, propKey: string, descriptor: PropertyDescriptor) {
//   const original = descriptor.value;
//   descriptor.value = function (...args: string[]) {
//     let filterResult = args.map((str) => {
//       let tempStr = str
//       FILTER_KEYS.forEach((filterKey) => tempStr = tempStr.replace(filterKey, "**"))
//       return tempStr
//     });
//     const result = original.call(this, ...filterResult);
//     return result;
//   };
// }

/**
 * Basic log class
 */
export default class Log {
  /**
   * Outputs debug-level logs.
   *
   * @param tag Identifies the log tag.
   * @param format Indicates the log format string.
   * @param args Indicates the log parameters.
   * @since 7
   */
  static d(tag: string, format: string, ...args: ESObject[]) {
    if (Log.isLoggable(HiLog.LogLevel.DEBUG)) {
      HiLog.debug(DOMAIN, TAG, tag + SYMBOL + format, args);
    }
  }

  /**
   * Outputs info-level logs.
   *
   * @param tag Identifies the log tag.
   * @param format Indicates the log format string.
   * @param args Indicates the log parameters.
   * @since 7
   */
  static i(tag: string, format: string, ...args: ESObject[]) {
    if (Log.isLoggable(HiLog.LogLevel.INFO)) {
      HiLog.info(DOMAIN, TAG, tag + SYMBOL + format, args);
    }
  }

  /**
   * Outputs warning-level logs.
   *
   * @param tag Identifies the log tag.
   * @param format Indicates the log format string.
   * @param args Indicates the log parameters.
   * @since 7
   */
  static w(tag: string, format: string, ...args: ESObject[]) {
    if (Log.isLoggable(HiLog.LogLevel.WARN)) {
      HiLog.warn(DOMAIN, TAG, tag + SYMBOL + format, args);
    }
  }

  /**
   * Outputs error-level logs.
   *
   * @param tag Identifies the log tag.
   * @param format Indicates the log format string.
   * @param args Indicates the log parameters.
   * @since 7
   */
  static e(tag: string, format: string, ...args: ESObject[]) {
    if (Log.isLoggable(HiLog.LogLevel.ERROR)) {
      args.format((item: ESObject, index: number) => {
        if (item instanceof Error) {
          args[index] = item.message + item.stack;
        }
        format+="%{public}s";
      })
      HiLog.error(DOMAIN, TAG, tag + SYMBOL + format, args);
    }
  }

  /**
   * Outputs fatal-level logs.
   *
   * @param tag Identifies the log tag.
   * @param format Indicates the log format string.
   * @param args Indicates the log parameters.
   * @since 7
   */
  static f(tag: string, format: string, ...args: ESObject[]) {
    if (Log.isLoggable(HiLog.LogLevel.FATAL)) {
      HiLog.fatal(DOMAIN, TAG, tag + SYMBOL + format, args);
    }
  }

  /**
   * Checks whether logs of the specified tag, and level can be printed.
   *
   * @param tag Identifies the log tag.
   * @param level log level
   * @since 7
   */
  private static isLoggable(level: HiLog.LogLevel): boolean {
    return HiLog.isLoggable(DOMAIN, TAG, level);
  }
}
