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

import MethodCall from './MethodCall';
/**
 * A codec for method calls and enveloped results.
 *
 * <p>Method calls are encoded as binary messages with enough structure that the codec can extract a
 * method name String and an arguments Object. These data items are used to populate a {@link
 * MethodCall}.
 *
 * <p>All operations throw {@link IllegalArgumentException}, if conversion fails.
 */
export default interface MethodCodec {
  /**
   * Encodes a message call into binary.
   *
   * @param methodCall a {@link MethodCall}.
   * @return a {@link ByteBuffer} containing the encoding between position 0 and the current
   *     position.
   */
  encodeMethodCall(methodCall: MethodCall): ArrayBuffer;

  /**
   * Decodes a message call from binary.
   *
   * @param methodCall the binary encoding of the method call as a {@link ByteBuffer}.
   * @return a {@link MethodCall} representation of the bytes between the given buffer's current
   *     position and its limit.
   */
  decodeMethodCall(methodCall: ArrayBuffer): MethodCall;

  /**
   * Encodes a successful result into a binary envelope message.
   *
   * @param result The result value, possibly null.
   * @return a {@link ByteBuffer} containing the encoding between position 0 and the current
   *     position.
   */
  encodeSuccessEnvelope(result: ESObject): ArrayBuffer;

  /**
   * Encodes an error result into a binary envelope message.
   *
   * @param errorCode An error code String.
   * @param errorMessage An error message String, possibly null.
   * @param errorDetails Error details, possibly null. Consider supporting {@link Throwable} in your
   *     codec. This is the most common value passed to this field.
   * @return a {@link ByteBuffer} containing the encoding between position 0 and the current
   *     position.
   */
  encodeErrorEnvelope(errorCode: string, errorMessage: string, errorDetails: ESObject): ArrayBuffer;

  /**
   * Encodes an error result into a binary envelope message with the native stacktrace.
   *
   * @param errorCode An error code String.
   * @param errorMessage An error message String, possibly null.
   * @param errorDetails Error details, possibly null. Consider supporting {@link Throwable} in your
   *     codec. This is the most common value passed to this field.
   * @param errorStacktrace Platform stacktrace for the error. possibly null.
   * @return a {@link ByteBuffer} containing the encoding between position 0 and the current
   *     position.
   */
  encodeErrorEnvelopeWithStacktrace(errorCode: string, errorMessage: string, errorDetails: ESObject, errorStacktrace: string): ArrayBuffer

  /**
   * Decodes a result envelope from binary.
   *
   * @param envelope the binary encoding of a result envelope as a {@link ByteBuffer}.
   * @return the enveloped result Object.
   * @throws FlutterException if the envelope was an error envelope.
   */
  decodeEnvelope(envelope: ArrayBuffer): ESObject
}