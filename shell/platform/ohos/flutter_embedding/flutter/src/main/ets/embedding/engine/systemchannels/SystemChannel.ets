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
import JSONMessageCodec from '../../../plugin/common/JSONMessageCodec';
import Log from '../../../util/Log';
import DartExecutor from '../dart/DartExecutor';
const TAG: string = "SystemChannel";

/**
 * fill in javadoc for SystemChannel.
 */
export default class SystemChannel {
  public channel: BasicMessageChannel<object>;

  constructor(dartExecutor: DartExecutor) {
    this.channel = new BasicMessageChannel(dartExecutor, "flutter/system", JSONMessageCodec.INSTANCE);
  }

  public sendMemoryPressureWarning(): void {
    Log.i(TAG, "Sending memory pressure warning to Flutter");
    let message: any = {
      "type":"memoryPressure"
    };
    this.channel.send(message);
  }
}