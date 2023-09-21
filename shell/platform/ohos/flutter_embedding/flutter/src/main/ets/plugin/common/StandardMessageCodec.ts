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

import { ByteBuffer } from '../../util/ByteBuffer';
import StringUtils from '../../util/StringUtils';
import MessageCodec from './MessageCodec';

/**
 * MessageCodec using the Flutter standard binary encoding.
 *
 * <p>This codec is guaranteed to be compatible with the corresponding <a
 * href="https://api.flutter.dev/flutter/services/StandardMessageCodec-class.html">StandardMessageCodec</a>
 * on the Dart side. These parts of the Flutter SDK are evolved synchronously.
 *
 * <p>Supported messages are acyclic values of these forms:
 *
 * <ul>
 *   <li>null
 *   <li>Booleans
 *   <li>number
 *   <li>BigIntegers (see below)
 *   <li>Int8Array, Int32Array, Float32Array, Float64Array
 *   <li>Strings
 *   <li>Array[]
 *   <li>Lists of supported values
 *   <li>Maps with supported keys and values
 * </ul>
 *
 * <p>On the Dart side, these values are represented as follows:
 *
 * <ul>
 *   <li>null: null
 *   <li>Boolean: bool
 *   <li>Byte, Short, Integer, Long: int
 *   <li>Float, Double: double
 *   <li>String: String
 *   <li>byte[]: Uint8List
 *   <li>int[]: Int32List
 *   <li>long[]: Int64List
 *   <li>float[]: Float32List
 *   <li>double[]: Float64List
 *   <li>List: List
 *   <li>Map: Map
 * </ul>
 *
 * <p>BigIntegers are represented in Dart as strings with the hexadecimal representation of the
 * integer's value.
 *
 * <p>To extend the codec, overwrite the writeValue and readValueOfType methods.
 */
export default class StandardMessageCodec implements MessageCodec<any> {
    private static TAG = "StandardMessageCodec#";
    static INSTANCE = new StandardMessageCodec();

    encodeMessage(message: any): ArrayBuffer {
        if (message == null) {
            return null;
        }
        const stream = ByteBuffer.from(new ArrayBuffer(1024))
        this.writeValue(stream, message);
        return stream.buffer
    }

    decodeMessage(message: ArrayBuffer): any {
        const buffer = ByteBuffer.from(message)
        return this.readValue(buffer)
    }

    private static NULL = 0;
    private static TRUE = 1;
    private static FALSE = 2;
    private static INT32 = 3;
    private static INT64 = 4;
    private static BIGINT = 5;
    private static FLOAT64 = 6;
    private static STRING = 7;
    private static UINT8_ARRAY = 8;
    private static INT32_ARRAY = 9;
    private static INT64_ARRAY = 10;
    private static FLOAT64_ARRAY = 11;
    private static LIST = 12;
    private static MAP = 13;
    private static FLOAT32_ARRAY = 14;


    writeValue(stream: ByteBuffer, value: any): any {
        if (value == null || value == undefined) {
            stream.writeInt8(StandardMessageCodec.NULL)
        } else if (typeof value === "boolean") {
            stream.writeInt8(value ? StandardMessageCodec.TRUE : StandardMessageCodec.FALSE)
        } else if (typeof value === "number") {
            if (Number.isInteger(value)) { //整型
                if (-0x7fffffff - 1 <= value && value <= 0x7fffffff) {
                    stream.writeInt8(StandardMessageCodec.INT32)
                    stream.writeInt32(value, true)
                } else {
                    stream.writeInt8(StandardMessageCodec.INT64)
                    stream.writeInt64(value, true)
                }
            } else { //浮点型
                stream.writeInt8(StandardMessageCodec.FLOAT64)
                this.writeAlignment(stream, 8);
                stream.writeFloat64(value, true)
            }
        } else if (typeof value === "string") {
            stream.writeInt8(StandardMessageCodec.STRING)
            let stringBuff = StringUtils.stringToArrayBuffer(value)
            this.writeBytes(stream, new Uint8Array(stringBuff))
        } else if (value instanceof Uint8Array) {
            stream.writeInt8(StandardMessageCodec.UINT8_ARRAY)
            this.writeBytes(stream, value)
        } else if (value instanceof Int32Array) {
            stream.writeInt8(StandardMessageCodec.INT32_ARRAY)
            this.writeSize(stream, value.length);
            this.writeAlignment(stream, 4);
            value.forEach(item => stream.writeInt32(item, true))
        } else if (value instanceof Float32Array) {
            stream.writeInt8(StandardMessageCodec.FLOAT32_ARRAY)
            this.writeSize(stream, value.length);
            this.writeAlignment(stream, 4);
            value.forEach(item => stream.writeFloat32(item, true))
        } else if (value instanceof Float64Array) {
            stream.writeInt8(StandardMessageCodec.FLOAT64_ARRAY)
            this.writeSize(stream, value.length);
            this.writeAlignment(stream, 8);
            value.forEach(item => stream.writeFloat64(item, true))
        } else if (value instanceof Array) {
            stream.writeInt8(StandardMessageCodec.LIST)
            this.writeSize(stream, value.length);
            value.forEach(item => this.writeValue(stream, item))
        } else if (value instanceof Map) {
            stream.writeInt8(StandardMessageCodec.MAP)
            this.writeSize(stream, value.size);
            value.forEach((value, key) => {
                this.writeValue(stream, key);
                this.writeValue(stream, value);
            })
        } else if (typeof value == 'object') {
            this.writeValue(stream, new Map(Object.entries(value)))
        }
        return stream
    }

    writeAlignment(stream: ByteBuffer, alignment: number) {
        var mod = stream.byteOffset % alignment;
        if (mod != 0) {
            for (let i = 0; i < alignment - mod; i++) {
                stream.writeInt8(0);
            }
        }
    }

    writeSize(stream: ByteBuffer, value: number) {
        if (value < 254) {
            stream.writeInt8(value);
        } else if (value <= 0xffff) {
            stream.writeInt8(254);
            stream.writeInt16(value, true);
        } else {
            stream.writeInt8(255);
            stream.writeInt32(value, true);
        }
    }

    writeBytes(stream: ByteBuffer, bytes: Uint8Array) {
        this.writeSize(stream, bytes.length)
        bytes.forEach(item => stream.writeInt8(item))
    }

    readSize(buffer: ByteBuffer) {
        let value = buffer.readInt8() & 0xff;
        if (value < 254) {
            return value;
        } else if (value == 254) {
            return buffer.readInt16(true);
        } else {
            return buffer.readInt32(true);
        }
    }

    readAlignment(buffer: ByteBuffer, alignment: number) {
        let mod = buffer.byteOffset % alignment;
        if (mod != 0) {
            buffer.skip(alignment - mod);
        }
    }

    readValue(buffer: ByteBuffer): any {
        let type = buffer.readInt8()
        return this.readValueOfType(type, buffer);
    }

    readBytes(buffer: ByteBuffer): Uint8Array {
        let length = this.readSize(buffer);
        let bytes = new Uint8Array(length)
        for (let i = 0; i < length; i++) {
            bytes[i] = buffer.readUint8()
        }
        return bytes;
    }

    readValueOfType(type: number, buffer: ByteBuffer): any {
        var result
        switch (type) {
            case StandardMessageCodec.NULL:
                result = null;
                break;
            case StandardMessageCodec.TRUE:
                result = true;
                break;
            case StandardMessageCodec.FALSE:
                result = false;
                break;
            case StandardMessageCodec.INT32:
                result = buffer.readInt32(true);
                break;
            case StandardMessageCodec.INT64:
                result = buffer.readInt64(true);
                break;
            case StandardMessageCodec.BIGINT:
                result = buffer.readBigInt64(true)
            case StandardMessageCodec.FLOAT64:
                this.readAlignment(buffer, 8);
                result = buffer.readFloat64(true)
                break;
            case StandardMessageCodec.STRING: {
                let bytes = this.readBytes(buffer);
                result = StringUtils.arrayBufferToString(bytes.buffer);
                break;
            }
            case StandardMessageCodec.UINT8_ARRAY: {
                result = this.readBytes(buffer);
                break;
            }
            case StandardMessageCodec.INT32_ARRAY: {
                let length = this.readSize(buffer);
                let array = new Int32Array(length)
                this.readAlignment(buffer, 4);
                for (let i = 0; i < length; i++) {
                    array[i] = buffer.readInt32(true)
                }
                result = array;
                break;
            }
            case StandardMessageCodec.INT64_ARRAY: { //这里是都城array 还是 bigint待定
                let length = this.readSize(buffer);
                let array = new Array(length)
                this.readAlignment(buffer, 8);
                for (let i = 0; i < length; i++) {
                    array[i] = buffer.readInt64(true)
                }
                result = array;
                break;
            }
            case StandardMessageCodec.FLOAT64_ARRAY: {
                let length = this.readSize(buffer);
                let array = new Float64Array(length)
                this.readAlignment(buffer, 8);
                for (let i = 0; i < length; i++) {
                    array[i] = buffer.readFloat64(true)
                }
                result = array;
                break;
            }
            case StandardMessageCodec.LIST: {
                let length = this.readSize(buffer);
                let array = new Array(length)
                for (let i = 0; i < length; i++) {
                    array[i] = this.readValue(buffer)
                }
                result = array;
                break;
            }
            case StandardMessageCodec.MAP: {
                let size = this.readSize(buffer);
                let map = new Map()
                for (let i = 0; i < size; i++) {
                    map.set(this.readValue(buffer), this.readValue(buffer));
                }
                result = map;
                break;
            }
            case StandardMessageCodec.FLOAT32_ARRAY: {
                let length = this.readSize(buffer);
                let array = new Float32Array(length);
                this.readAlignment(buffer, 4);
                for (let i = 0; i < length; i++) {
                    array[i] = buffer.readFloat32(true)
                }
                result = array;
                break;
            }
            default:
                throw new Error("Message corrupted");
        }
        return result;
    }
}