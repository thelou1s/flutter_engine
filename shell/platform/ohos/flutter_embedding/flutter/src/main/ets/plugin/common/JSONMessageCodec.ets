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

import MessageCodec from './MessageCodec';
import MethodCodec from './MethodCodec';
import StringCodec from './StringCodec';

/**
 * A {@link MethodCodec} using UTF-8 encoded JSON method calls and result envelopes.
 *
 * <p>This codec is guaranteed to be compatible with the corresponding <a
 * href="https://api.flutter.dev/flutter/services/JSONMethodCodec-class.html">JSONMethodCodec</a> on
 * the Dart side. These parts of the Flutter SDK are evolved synchronously.
 *
 * <p>On the Dart side, JSON messages are handled by the JSON facilities of the <a
 * href="https://api.dartlang.org/stable/dart-convert/JSON-constant.html">dart:convert</a> package.
 */
export default class JSONMessageCodec implements MessageCodec<Object> {
  static INSTANCE = new JSONMessageCodec();

  encodeMessage(message: ESObject): ArrayBuffer {
    if (message == null) {
      return null;
    }
    return StringCodec.INSTANCE.encodeMessage(JSON.stringify(message));
  }

  decodeMessage(message: ArrayBuffer): ESObject {
    if (message == null) {
      return null;
    }
    try {
      const jsonStr = StringCodec.INSTANCE.decodeMessage(message);
      return JSON.parse(jsonStr);
    } catch (e) {
      throw new Error("Invalid JSON");
    }
  }
}