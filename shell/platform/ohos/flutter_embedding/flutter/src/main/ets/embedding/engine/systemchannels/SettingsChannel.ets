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

export enum PlatformBrightness {
  LIGHT = "light",
  DARK = "dark"
}

const TAG = "SettingsChannel";
const TEXT_SCALE_FACTOR = "textScaleFactor";
const NATIVE_SPELL_CHECK_SERVICE_DEFINED = "nativeSpellCheckServiceDefined";
const BRIEFLY_SHOW_PASSWORD = "brieflyShowPassword";
const ALWAYS_USE_24_HOUR_FORMAT = "alwaysUse24HourFormat";
const PLATFORM_BRIGHTNESS = "platformBrightness";
export default class SettingsChannel {
  private static CHANNEL_NAME = "flutter/settings";

  private channel: BasicMessageChannel<Object>;

  constructor(dartExecutor: DartExecutor) {
    this.channel = new BasicMessageChannel<Object>(dartExecutor, SettingsChannel.CHANNEL_NAME, JSONMessageCodec.INSTANCE);
  }

  startMessage(): MessageBuilder {
    return new MessageBuilder(this.channel);
  }
}

class MessageBuilder {
  private channel: BasicMessageChannel<Object>;
  private settingsMessage: SettingsMessage = new SettingsMessage();
  constructor(channel: BasicMessageChannel<Object>) {
    this.channel = channel;
  }

  setTextScaleFactor(textScaleFactor: Number): MessageBuilder {
    this.settingsMessage.setTextScaleFactor(textScaleFactor);
    return this;
  }

  setNativeSpellCheckServiceDefined(nativeSpellCheckServiceDefined: boolean): MessageBuilder {
    this.settingsMessage.setNativeSpellCheckServiceDefined(nativeSpellCheckServiceDefined);
    return this;
  }

  setBrieflyShowPassword(brieflyShowPassword: boolean): MessageBuilder {
    this.settingsMessage.setBrieflyShowPassword(brieflyShowPassword);
    return this;
  }

  setAlwaysUse24HourFormat(alwaysUse24HourFormat: boolean): MessageBuilder {
    this.settingsMessage.setAlwaysUse24HourFormat(alwaysUse24HourFormat);
    return this;
  }

  setPlatformBrightness(platformBrightness: PlatformBrightness): MessageBuilder {
    this.settingsMessage.setPlatformBrightness(platformBrightness);
    return this;
  }

  send(): void {
    Log.i(TAG, "Sending message: \n"
      + TEXT_SCALE_FACTOR + " : "
      + this.settingsMessage.getTextScaleFactor()
      + ", " + NATIVE_SPELL_CHECK_SERVICE_DEFINED + " : "
      + this.settingsMessage.getNativeSpellCheckServiceDefined()
      + ", " + BRIEFLY_SHOW_PASSWORD + " : "
      + this.settingsMessage.getBrieflyShowPassword()
      + ", " + ALWAYS_USE_24_HOUR_FORMAT + " : "
      + this.settingsMessage.getAlwaysUse24HourFormat()
      + ", " + PLATFORM_BRIGHTNESS + " : "
      + this.settingsMessage.getPlatformBrightness());
    this.channel.send(this.settingsMessage)
  }
}

class SettingsMessage {
  private textScaleFactor: Number = 1.0;
  private nativeSpellCheckServiceDefined: boolean = false;
  private brieflyShowPassword: boolean = false;
  private alwaysUse24HourFormat: boolean = false;
  private platformBrightness: PlatformBrightness = PlatformBrightness.LIGHT;

  setTextScaleFactor(textScaleFactor: Number): void {
    this.textScaleFactor = textScaleFactor;
  }

  setNativeSpellCheckServiceDefined(nativeSpellCheckServiceDefined: boolean): void {
    this.nativeSpellCheckServiceDefined = nativeSpellCheckServiceDefined;
  }

  setBrieflyShowPassword(brieflyShowPassword: boolean): void {
    this.brieflyShowPassword = brieflyShowPassword;
  }

  setAlwaysUse24HourFormat(alwaysUse24HourFormat: boolean): void {
    this.alwaysUse24HourFormat = alwaysUse24HourFormat;
  }

  setPlatformBrightness(platformBrightness: PlatformBrightness): void {
    this.platformBrightness = platformBrightness;
  }

  getTextScaleFactor(): Number {
    return this.textScaleFactor;
  }

  getNativeSpellCheckServiceDefined(): boolean {
    return this.nativeSpellCheckServiceDefined;
  }

  getBrieflyShowPassword(): boolean {
    return this.brieflyShowPassword;
  }

  getAlwaysUse24HourFormat(): boolean {
    return this.alwaysUse24HourFormat;
  }

  getPlatformBrightness(): PlatformBrightness {
    return this.platformBrightness;
  }
}