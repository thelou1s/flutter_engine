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
import StringUtils from '../../util/StringUtils';

import MessageCodec from './MessageCodec';
import MethodCodec from './MethodCodec';
import StringCodec from './StringCodec';
import TreeMap from '@ohos.util.TreeMap';
import HashMap from '@ohos.util.HashMap';
import LightWeightMap from '@ohos.util.LightWeightMap';
import PlainArray from '@ohos.util.PlainArray';  
import List from '@ohos.util.List';
import LinkedList from '@ohos.util.LinkedList';  

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
      return StringUtils.stringToArrayBuffer("");
    }
    return StringCodec.INSTANCE.encodeMessage(JSON.stringify(this.toBaseData(message)));
  }

  decodeMessage(message: ArrayBuffer | null): ESObject {
    if (message == null) {
      return StringUtils.stringToArrayBuffer("");
    }
    try {
      const jsonStr = StringCodec.INSTANCE.decodeMessage(message);
      return JSON.parse(jsonStr);
    } catch (e) {
      throw new Error("Invalid JSON");
    }
  }

  toBaseData(message: ESObject): ESObject {
    if (message == null || message == undefined) {
        return "";
    } else if (message instanceof List || message instanceof LinkedList) {
        return message.convertToArray();
    } else if (message instanceof Map || message instanceof HashMap || message instanceof TreeMap
        || message instanceof LightWeightMap || message instanceof PlainArray) {
        let messageObj: ESObject = {};
        message.forEach((value: ESObject, key: ESObject) => {
          messageObj[this.toBaseData(key)] = this.toBaseData(value);
        });
        return messageObj;
    } else {
        return message;
    }
  }
}