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

import DartExecutor from '../dart/DartExecutor';
import MethodChannel, { MethodCallHandler, MethodResult} from '../../../plugin/common/MethodChannel';
import MethodCall from '../../../plugin/common/MethodCall';
import List from '@ohos.util.List';
import JSONMethodCodec from '../../../plugin/common/JSONMethodCodec';
import intl from '@ohos.intl';
import Log from '../../../util/Log';

const TAG =  "LocalizationChannel";
export default class LocalizationChannel implements MethodCallHandler{
  private static TAG = "LocalizationChannel";
  private static CHANNEL_NAME = "flutter/localization";
  private channel: MethodChannel;
  private localizationMessageHandler: LocalizationMessageHandler;

  onMethodCall(call: MethodCall, result: MethodResult) :void {
    if (this.localizationMessageHandler == null) {
      Log.e(TAG, "localizationMessageHandler is null");
      return;
    }
    let method: string = call.method;
    switch (method) {
        case "Localization.getStringResource": {
          let key: string = call.argument("key");
          let localeString: string = null;
          if (call.hasArgument("locale")) {
            localeString  = call.argument("locale");
          }
          result.success(this.localizationMessageHandler.getStringResource(key, localeString));
          break;
        }
        default: {
            result.notImplemented();
            break;
        }
    }
  }

  constructor(dartExecutor: DartExecutor) {
    this.channel = new MethodChannel(dartExecutor, LocalizationChannel.CHANNEL_NAME, JSONMethodCodec.INSTANCE);
    this.channel.setMethodCallHandler(this);
  }

  setLocalizationMessageHandler(localizationMessageHandler: LocalizationMessageHandler): void {
    this.localizationMessageHandler = localizationMessageHandler;
  }

  sendLocales(locales: Array<string>): void {
    this.channel.invokeMethod("setLocale", locales);
  }
}

export interface LocalizationMessageHandler {
    getStringResource(key: string, local: string);
}