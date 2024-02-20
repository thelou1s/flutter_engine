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

/**
 * A {@link MessageCodec} using unencoded binary messages, represented as {@link ByteBuffer}s.
 *
 * <p>This codec is guaranteed to be compatible with the corresponding <a
 * href="https://api.flutter.dev/flutter/services/BinaryCodec-class.html">BinaryCodec</a> on the
 * Dart side. These parts of the Flutter SDK are evolved synchronously.
 *
 * <p>On the Dart side, messages are represented using {@code ByteData}.
 */

export default class BinaryCodec implements MessageCodec<ArrayBuffer> {
  private returnsDirectByteBufferFromDecoding: boolean = false;
  static readonly INSTANCE_DIRECT = new BinaryCodec(true);

  constructor(returnsDirectByteBufferFromDecoding: boolean) {
    this.returnsDirectByteBufferFromDecoding = returnsDirectByteBufferFromDecoding;
  }

  encodeMessage(message: ArrayBuffer): ArrayBuffer {
    return message
  }

  decodeMessage(message: ArrayBuffer | null): ArrayBuffer {
    if (message == null) {
      return new ArrayBuffer(0);
    } else if (this.returnsDirectByteBufferFromDecoding) {
      return message;
    } else {
      return message.slice(0, message.byteLength);
    }
  }
}