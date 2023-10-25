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

import BasicMessageChannel from '../../../plugin/common/BasicMessageChannel';
import { BinaryMessenger } from '../../../plugin/common/BinaryMessenger';
import { Reply } from '../../../plugin/common/BasicMessageChannel';
import { Action, Key, KeyEvent } from '@ohos.multimodalInput.keyEvent';
import Log from '../../../util/Log';
import JSONMessageCodec from '../../../plugin/common/JSONMessageCodec';

export default class KeyEventChannel {
  private static TAG = "KeyEventChannel";
  private static CHANNEL_NAME = "flutter/keyevent";
  private channel : BasicMessageChannel<Map<String, Object>>;

  constructor(binaryMessenger: BinaryMessenger) {
    this.channel = new BasicMessageChannel<Map<String, Object>>(binaryMessenger, KeyEventChannel.CHANNEL_NAME, JSONMessageCodec.INSTANCE);
  }

  sendFlutterKeyEvent(keyEvent: FlutterKeyEvent,
                      isKeyUp: boolean,
                      responseHandler: EventResponseHandler): void {
    this.channel.send(this.encodeKeyEvent(keyEvent, isKeyUp),
      (message:Map<String, Object>) => {
        let isEventHandled = false;
        try {
          if (message != null) {
            isEventHandled = message.get("handled") as boolean;
          }
        } catch (e) {
          Log.e(KeyEventChannel.TAG, "Unable to unpack JSON message: " + e);
        }
        responseHandler.onFrameworkResponse(isEventHandled);
      }
    );
  }

  encodeKeyEvent(keyEvent: FlutterKeyEvent, isKeyUp: boolean): Map<String,Object> {
    let  message: Map<String, Object> = new Map();
    message.set("type", isKeyUp ?  "keyup" : "keydown");
    message.set("keymap", "ohos");
    message.set("codePoint", keyEvent.event.unicodeChar);
    message.set("keyCode", keyEvent.event.key.code);
    message.set("deviceId", keyEvent.event.key.deviceId);
    message.set("character", keyEvent.event.key.code.toString());
    message.set("repeatCount", 1);
    return message;
  }


}

export  interface EventResponseHandler {
  onFrameworkResponse(isEventHandled: boolean): void;
}

export class FlutterKeyEvent {
  event: KeyEvent;

  constructor( ohosKeyEvent: KeyEvent) {
    this.event = ohosKeyEvent;
  }
}