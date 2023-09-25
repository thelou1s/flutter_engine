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
import Log from '../../util/Log';

import ToolUtils from '../../util/ToolUtils';
import FlutterException from './FlutterException';
import JSONMessageCodec from './JSONMessageCodec';
import MethodCall from './MethodCall';
import MethodCodec from './MethodCodec';

/**
 * A {@link MethodCodec} using UTF-8 encoded JSON method calls and result envelopes.
 *
 * <p>This codec is guaranteed to be compatible with the corresponding <a
 * href="https://api.flutter.dev/flutter/services/JSONMethodCodec-class.html">JSONMethodCodec</a> on
 * the Dart side. These parts of the Flutter SDK are evolved synchronously.
 *
 * <p>Values supported as methods arguments and result payloads are those supported by {@link
 * JSONMessageCodec}.
 */
export default class JSONMethodCodec implements MethodCodec {
  static INSTANCE = new JSONMethodCodec();

  encodeMethodCall(methodCall: MethodCall): ArrayBuffer {
    try {
      const map = {
        "method": methodCall.method, "args": methodCall.args
      }
      return JSONMessageCodec.INSTANCE.encodeMessage(map);
    } catch (e) {
      throw new Error("Invalid JSON");
    }
  }

  decodeMethodCall(message: ArrayBuffer): MethodCall {
    try {
      const json = JSONMessageCodec.INSTANCE.decodeMessage(message);
      if (ToolUtils.isObj(json)) {
        const method = json["method"];
        const args = json["args"];
        if (typeof method == 'string') {
          return new MethodCall(method, args);
        }
      }
      throw new Error("Invalid method call: " + json);
    } catch (e) {
      throw new Error("Invalid JSON:" + JSON.stringify(e));
    }
  }

  encodeSuccessEnvelope(result: any): ArrayBuffer {
    return JSONMessageCodec.INSTANCE.encodeMessage([result]);
  }

  encodeErrorEnvelope(errorCode: any, errorMessage: string, errorDetails: any) {
    return JSONMessageCodec.INSTANCE.encodeMessage([errorCode, errorMessage, errorDetails]);
  }

  encodeErrorEnvelopeWithStacktrace(errorCode: string, errorMessage: string, errorDetails: any, errorStacktrace: string): ArrayBuffer {
    return JSONMessageCodec.INSTANCE.encodeMessage([errorCode, errorMessage, errorDetails, errorStacktrace])
  }

  decodeEnvelope(envelope: ArrayBuffer): any {
    try {
      const json = JSONMessageCodec.INSTANCE.decodeMessage(envelope);
      if (json instanceof Array) {
        if (json.length == 1) {
          return json[0];
        }
        if (json.length == 3) {
          const code = json[0];
          const message = json[1];
          const details = json[2];
          if (typeof code == 'string' && (message == null || typeof message == 'string')) {
            throw new FlutterException(code, message, details);
          }
        }
      }
      throw new Error("Invalid envelope: " + json);
    } catch (e) {
      throw new Error("Invalid JSON");
    }
  }
}