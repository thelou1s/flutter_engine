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

import BasicMessageChannel, { MessageHandler, Reply } from '../../../plugin/common/BasicMessageChannel';
import JSONMessageCodec from '../../../plugin/common/JSONMessageCodec';
import DartExecutor from '../dart/DartExecutor';
import Log from '../../../util/Log';

const TAG = "TestChannel"

export default class TestChannel {
  private channel: BasicMessageChannel<String>

  constructor(dartExecutor: DartExecutor) {
    this.channel = new BasicMessageChannel<String>(dartExecutor, "flutter/test", JSONMessageCodec.INSTANCE);
    let callback = new MessageCallback();
    this.channel.setMessageHandler(callback);
  }
}

class MessageCallback implements MessageHandler<string> {
  onMessage(message: string, reply: Reply<string>) {
    Log.d(TAG, "receive msg = " + message);
    reply.reply("收到消息啦：" + message);
  }
}