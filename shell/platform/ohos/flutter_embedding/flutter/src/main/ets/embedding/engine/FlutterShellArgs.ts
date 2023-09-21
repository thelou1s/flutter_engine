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

import Want from '@ohos.app.ability.Want';

/**
 * 封装flutter shell的参数
 */
export default class FlutterShellArgs {
  static ARG_KEY_TRACE_STARTUP = "trace-startup";
  static ARG_TRACE_STARTUP = "--trace-startup";
  static ARG_KEY_START_PAUSED = "start-paused";
  static ARG_START_PAUSED = "--start-paused";
  static ARG_KEY_DISABLE_SERVICE_AUTH_CODES = "disable-service-auth-codes";
  static ARG_DISABLE_SERVICE_AUTH_CODES = "--disable-service-auth-codes";
  static ARG_KEY_ENDLESS_TRACE_BUFFER = "endless-trace-buffer";
  static ARG_ENDLESS_TRACE_BUFFER = "--endless-trace-buffer";
  static ARG_KEY_USE_TEST_FONTS = "use-test-fonts";
  static ARG_USE_TEST_FONTS = "--use-test-fonts";
  static ARG_KEY_ENABLE_DART_PROFILING = "enable-dart-profiling";
  static ARG_ENABLE_DART_PROFILING = "--enable-dart-profiling";
  static ARG_KEY_ENABLE_SOFTWARE_RENDERING = "enable-software-rendering";
  static ARG_ENABLE_SOFTWARE_RENDERING = "--enable-software-rendering";
  static ARG_KEY_SKIA_DETERMINISTIC_RENDERING = "skia-deterministic-rendering";
  static ARG_SKIA_DETERMINISTIC_RENDERING = "--skia-deterministic-rendering";
  static ARG_KEY_TRACE_SKIA = "trace-skia";
  static ARG_TRACE_SKIA = "--trace-skia";
  static ARG_KEY_TRACE_SKIA_ALLOWLIST = "trace-skia-allowlist";
  static ARG_TRACE_SKIA_ALLOWLIST = "--trace-skia-allowlist=";
  static ARG_KEY_TRACE_SYSTRACE = "trace-systrace";
  static ARG_TRACE_SYSTRACE = "--trace-systrace";
  static ARG_KEY_ENABLE_IMPELLER = "enable-impeller";
  static ARG_ENABLE_IMPELLER = "--enable-impeller";
  static ARG_KEY_DUMP_SHADER_SKP_ON_SHADER_COMPILATION =
    "dump-skp-on-shader-compilation";
  static ARG_DUMP_SHADER_SKP_ON_SHADER_COMPILATION =
    "--dump-skp-on-shader-compilation";
  static ARG_KEY_CACHE_SKSL = "cache-sksl";
  static ARG_CACHE_SKSL = "--cache-sksl";
  static ARG_KEY_PURGE_PERSISTENT_CACHE = "purge-persistent-cache";
  static ARG_PURGE_PERSISTENT_CACHE = "--purge-persistent-cache";
  static ARG_KEY_VERBOSE_LOGGING = "verbose-logging";
  static ARG_VERBOSE_LOGGING = "--verbose-logging";
  static ARG_KEY_OBSERVATORY_PORT = "observatory-port";
  static ARG_OBSERVATORY_PORT = "--observatory-port=";
  static ARG_KEY_DART_FLAGS = "dart-flags";
  static ARG_DART_FLAGS = "--dart-flags";
  static ARG_KEY_MSAA_SAMPLES = "msaa-samples";
  static ARG_MSAA_SAMPLES = "--msaa-samples";

  /**
   * 从意图中解析参数，创建shellArgs
   * @returns
   */
  static fromWant(want: Want): FlutterShellArgs {
    //tdo 解析want
    return new FlutterShellArgs();
  }

  //参数
  args: Set<string> = new Set();

  add(arg: string) {
    this.args.add(arg);
  }

  remove(arg: string) {
    this.args.delete(arg);
  }

  toArray(): Array<string> {
    return Array.from(this.args);
  }
}