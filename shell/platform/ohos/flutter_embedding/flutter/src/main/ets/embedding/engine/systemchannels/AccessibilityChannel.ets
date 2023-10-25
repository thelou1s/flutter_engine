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

import Log from '../../../util/Log';
import DartExecutor from '../dart/DartExecutor';
import BasicMessageChannel, { MessageHandler, Reply} from '../../../plugin/common/BasicMessageChannel';
import HashMap from '@ohos.util.HashMap';
import FlutterNapi, {AccessibilityDelegate} from '../FlutterNapi';
import { Action } from '../../../view/AccessibilityBridge'
import StandardMessageCodec from '../../../plugin/common/StandardMessageCodec';

/**
* 辅助功能channel
*/
export default class AccessibilityChannel implements MessageHandler<object>{
    private static TAG = "AccessibilityChannel";
    private static CHANNEL_NAME = "flutter/accessibility";
    private channel: BasicMessageChannel<object>;
    private flutterNapi: FlutterNapi;
    private handler: AccessibilityMessageHandler;
    private nextReplyId: number = 1;

    onMessage(message: object, reply: Reply<object>): void {
        if (this.handler == null) {
            Log.i(AccessibilityChannel.TAG, "NULL");
            reply.reply(null);
            return;
        }
        let annotatedEvent: HashMap<string, ESObject> = message as HashMap<string, ESObject>;
        let type: string = annotatedEvent.get("type") as string;
        let data: HashMap<string, ESObject> = annotatedEvent.get("data") as HashMap<string, ESObject>;

        Log.i(AccessibilityChannel.TAG, "Received " + type + " message.");
        switch (type) {
            case "announce": {
                Log.i(AccessibilityChannel.TAG, "Announce");
                let announceMessage: string = data.get("message");
                if (announceMessage != null) {
                    this.handler.announce(announceMessage);
                }
                break;
            }
            case "tap": {
              Log.i(AccessibilityChannel.TAG, "Tag");
              let nodeId: number = annotatedEvent.get("nodeId");
                if (nodeId != null) {
                  this.handler.onTap(nodeId);
                }
                break;
            }
            case "longPress": {
                Log.i(AccessibilityChannel.TAG, "LongPress");
                let nodeId: number = annotatedEvent.get("nodeId");
                if (nodeId != null) {
                    this.handler.onLongPress(nodeId);
                }
                break;
            }
            case "tooltip": {
                Log.i(AccessibilityChannel.TAG, "ToolTip");
                let tooltipMessage: string = data.get("message");
                if (tooltipMessage != null) {
                    this.handler.onTooltip(tooltipMessage);
                }
                break;
            }
        }
        reply.reply(null);
    }

    constructor(dartExecutor: DartExecutor, flutterNapi: FlutterNapi) {
        Log.i(AccessibilityChannel.TAG, "Channel entered");
        this.channel = new BasicMessageChannel<object>(dartExecutor, AccessibilityChannel.CHANNEL_NAME, StandardMessageCodec.INSTANCE);
        this.channel.setMessageHandler(this);
        this.flutterNapi = flutterNapi;
    }

    onOhosAccessibilityEnabled(): void {
        let replyId: number = this.nextReplyId++;
        this.flutterNapi.setSemanticsEnabled(true, replyId);
    }

    onOhosAccessibilityFeatures(accessibilityFeatureFlags: number): void {
        let replyId: number = this.nextReplyId++;
        this.flutterNapi.setAccessibilityFeatures(accessibilityFeatureFlags, replyId);
    }

    dispatchSemanticsAction(virtualViewId: number, action: Action): void {
        let replyId: number = this.nextReplyId++;
        this.flutterNapi.dispatchSemanticsAction(virtualViewId, action, replyId);
    }

    setAccessibilityMessageHandler(handler: AccessibilityMessageHandler): void {
      this.handler = handler;
      let replyId: number = this.nextReplyId++;
      this.flutterNapi.setAccessibilityDelegate(handler, replyId);
    }

}

interface AccessibilityMessageHandler extends AccessibilityDelegate {
    announce(message: string): void;
    onTap(nodeId: number): void;
    onLongPress(nodeId: number): void;
    onTooltip(nodeId: string): void;
}