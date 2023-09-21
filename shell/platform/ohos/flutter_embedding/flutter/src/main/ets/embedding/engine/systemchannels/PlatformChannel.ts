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

import JSONMethodCodec from '../../../plugin/common/JSONMethodCodec';
import MethodCall from '../../../plugin/common/MethodCall';
import MethodChannel, { MethodResult } from '../../../plugin/common/MethodChannel';
import Log from '../../../util/Log';
import DartExecutor from '../dart/DartExecutor';
import pasteboard from '@ohos.pasteboard';
import bundleManager from '@ohos.bundle.bundleManager';
import window from '@ohos.window';

export default class PlatformChannel {
  private static TAG = "PlatformChannel";
  private static CHANNEL_NAME = "flutter/platform";
  channel: MethodChannel;
  platformMessageHandler: PlatformMessageHandler;

  constructor(dartExecutor: DartExecutor) {
    this.channel = new MethodChannel(dartExecutor, PlatformChannel.CHANNEL_NAME, JSONMethodCodec.INSTANCE);
    this.channel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult): void => {
        if (this.platformMessageHandler == null) {
          Log.w(PlatformChannel.TAG,"platformMessageHandler is null");
          return;
        }

        let method: string = call.method;
        let args: any = call.args;
        Log.d(PlatformChannel.TAG, "Received '" + method + "' message.");
        try {
          switch (method) {
            case "SystemSound.play":
              //TODO:
              break;
            case "HapticFeedback.vibrate":
              try {
                Log.d(PlatformChannel.TAG, "HapticFeedback: "+args as string);
                let feedbackType: HapticFeedbackType = this.getFeedbackTypeFromValue(args as string);
                this.platformMessageHandler.vibrateHapticFeedback(feedbackType);
                result.success(null);
              } catch(e) {
                Log.e(PlatformChannel.TAG, "HapticFeedback.vibrate error:" + JSON.stringify(e));
              }
              break;
            case "SystemChrome.setPreferredOrientations":
              Log.d(PlatformChannel.TAG, "setPreferredOrientations: "+JSON.stringify(args));
              try {
                let ohosOrientation = this.decodeOrientations(args as string[]);
                this.platformMessageHandler.setPreferredOrientations(ohosOrientation);
                result.success(null);
              } catch (err) {
                Log.e(PlatformChannel.TAG, "setPreferredOrientations err:" + JSON.stringify(err));
                result.error("error", JSON.stringify(err), null);
              }

              break;
            case "SystemChrome.setApplicationSwitcherDescription":
              Log.d(PlatformChannel.TAG, "setApplicationSwitcherDescription: "+JSON.stringify(args));
              break;
            case "SystemChrome.setEnabledSystemUIOverlays":
              try {
                let overlays: SystemUiOverlay[] = this.decodeSystemUiOverlays(args);
                Log.d(PlatformChannel.TAG,"overlays: " + overlays);
                this.platformMessageHandler.showSystemOverlays(overlays);
                result.success(null);
              } catch (err) {
                Log.e(PlatformChannel.TAG, "setEnabledSystemUIOverlays err:" + JSON.stringify(err));
                result.error("error", JSON.stringify(err), null);
              }
              break;
            case "SystemChrome.setEnabledSystemUIMode":
              try{
                Log.d(PlatformChannel.TAG,"setEnabledSystemUIMode args:" + args as string);
                let mode: SystemUiMode = this.decodeSystemUiMode(args as string)
                this.platformMessageHandler.showSystemUiMode(mode);
              } catch (err) {
                Log.e(PlatformChannel.TAG, "setEnabledSystemUIMode err:" + JSON.stringify(err));
                result.error("error", JSON.stringify(err), null);
              }
              break;
            case "SystemChrome.setSystemUIChangeListener":
              this.platformMessageHandler.setSystemUiChangeListener();
              result.success(null);
              break;
            case "SystemChrome.restoreSystemUIOverlays":
              this.platformMessageHandler.restoreSystemUiOverlays();
              result.success(null);
              break;
            case "SystemChrome.setSystemUIOverlayStyle":
              try {
                Log.d(PlatformChannel.TAG, "setSystemUIOverlayStyle asrgs: " + JSON.stringify(args));
                let systemChromeStyle: SystemChromeStyle = this.decodeSystemChromeStyle(args);
                this.platformMessageHandler.setSystemUiOverlayStyle(systemChromeStyle);
                result.success(null);
              } catch (err) {
                Log.e(PlatformChannel.TAG, "setSystemUIOverlayStyle err:" + JSON.stringify(err));
                result.error("error", JSON.stringify(err), null);
              }
              break;
            case "SystemNavigator.pop":
              this.platformMessageHandler.popSystemNavigator();
              result.success(null);
              break;
            case "Clipboard.getData":
              let contentFormatName: string = args as string;
              let clipboardFormat: ClipboardContentFormat = null;
              if(contentFormatName != null) {
                try{
                  clipboardFormat = this.getClipboardContentFormatFromValue(contentFormatName);
                } catch (err) {
                  Log.d(PlatformChannel.TAG, "No such clipboard content format: " + contentFormatName);
                  result.error("error", "No such clipboard content format: " + contentFormatName, null);
                }
              }

              let pasteBoard = pasteboard.getSystemPasteboard();
              pasteBoard.getData().then((pasteData) => {
                let text = pasteData.getPrimaryText();
                let response = {text: ""};
                response.text = text;
                result.success(response);
              }).catch((err) => {
                Log.e(PlatformChannel.TAG,"Failed to get PasteData. Cause: " + JSON.stringify(err));
              });
              break;
            case "Clipboard.setData":
              let clipboardContent = args.text;
              this.platformMessageHandler.setClipboardData(clipboardContent);
              result.success(null);
              break;
            case "Clipboard.hasStrings":
              let hasStrings: boolean = false;
              let response = {value: false};
              let systemPasteboard = pasteboard.getSystemPasteboard();
              systemPasteboard.hasData().then((hasData) => {
                if(!hasData) {
                  response.value = hasData;
                  result.success(response);
                }
              }).catch((err) => {
                  Log.e(PlatformChannel.TAG, "systemPasteboard.hasData err: " + JSON.stringify(err));
              })
              systemPasteboard.getData().then((pasteData) => {
                hasStrings = pasteData.hasType(pasteboard.MIMETYPE_TEXT_PLAIN);
                response.value = hasStrings;
                result.success(response);
              }).catch((err) => {
                Log.e(PlatformChannel.TAG, "getData err: " + JSON.stringify(err));
              })
              break;
            default:
              result.notImplemented();
              break;
          }
        } catch (e) {
          result.error("error", JSON.stringify(e), null);
          }
        }
      });
  }

  setPlatformMessageHandler(platformMessageHandler: PlatformMessageHandler): void {
    this.platformMessageHandler = platformMessageHandler;
  }

  systemChromeChanged(overlaysAreVisible: boolean): void {
    Log.d(PlatformChannel.TAG, "Sending 'systemUIChange' message.");
    this.channel.invokeMethod("SystemChrome.systemUIChange", [overlaysAreVisible]);
  }

  decodeOrientations(encodedOrientations: string[]): number {
    let requestedOrientation = 0x00;
    let firstRequestedOrientation = 0x00;
    for(let index = 0; index< encodedOrientations.length; index += 1) {
      let encodedOrientation = encodedOrientations[index];
      Log.d(PlatformChannel.TAG,"encodedOrientation[" + index + "]: "+encodedOrientation);
      let orientation = this.getDeviceOrientationFromValue(encodedOrientation);
      switch (orientation) {
        case DeviceOrientation.PORTRAIT_UP:
          requestedOrientation |= 0x01;
          break;
        case DeviceOrientation.PORTRAIT_DOWN:
          requestedOrientation |= 0x04;
          break;
        case DeviceOrientation.LANDSCAPE_LEFT:
          requestedOrientation |= 0x02;
          break;
        case DeviceOrientation.LANDSCAPE_RIGHT:
          requestedOrientation |= 0x08;
          break;
      }
      if (firstRequestedOrientation == 0x00) {
        firstRequestedOrientation = requestedOrientation;
      }
    }

    switch (requestedOrientation) {
      case 0x00:
        return window.Orientation.UNSPECIFIED;
      case 0x01:
        return window.Orientation.PORTRAIT;
      case 0x02:
        return window.Orientation.LANDSCAPE;
      case 0x03:
      case 0x04:
        return window.Orientation.PORTRAIT_INVERTED;
      case 0x05:
        return window.Orientation.AUTO_ROTATION_PORTRAIT;
      case 0x06:
      case 0x07:
      case 0x08:
        return window.Orientation.LANDSCAPE_INVERTED;
      case 0x09:
      case 0x0a:
        return window.Orientation.AUTO_ROTATION_LANDSCAPE;
      case 0x0b:
        return window.Orientation.LOCKED;
      case 0x0c:
      case 0x0d:
      case 0x0e:
            switch (firstRequestedOrientation) {
              case 0x01:
                return bundleManager.DisplayOrientation.PORTRAIT;
              case 0x02:
                return bundleManager.DisplayOrientation.LANDSCAPE;
              case 0x04:
                return bundleManager.DisplayOrientation.PORTRAIT_INVERTED;
              case 0x08:
                return bundleManager.DisplayOrientation.LANDSCAPE_INVERTED;
            }
      case 0x0f:
    }
    return bundleManager.DisplayOrientation.PORTRAIT;
  }

  getFeedbackTypeFromValue(encodedName: string): HapticFeedbackType {
    if(encodedName == null) {
      return HapticFeedbackType.STANDARD;
    }
    for (const feedbackType in HapticFeedbackType) {
      if (
        (HapticFeedbackType[feedbackType] == encodedName) ||
          (HapticFeedbackType[feedbackType] == null && encodedName == null)
      ) {
        return HapticFeedbackType[feedbackType];
      }
    }
    Log.e(PlatformChannel.TAG,"No such HapticFeedbackType:" + encodedName);
  }

  getClipboardContentFormatFromValue(encodedName: string): ClipboardContentFormat {
    for (const format in ClipboardContentFormat) {
      if (ClipboardContentFormat[format] === encodedName) {
        return ClipboardContentFormat[format];
      }
    }
  }
  getSystemUiOverlayFromValue(encodedName: string): SystemUiOverlay {
    for (const overlay in SystemUiOverlay) {
      if (SystemUiOverlay[overlay] === encodedName) {
        return SystemUiOverlay[overlay];
      }
    }
    throw new Error("No such SystemUiOverlay: " + encodedName);
  }

  private decodeSystemUiOverlays(encodedSystemUiOverlay: any): SystemUiOverlay[] {
    let overlays: SystemUiOverlay[] = [];
    for(let i = 0; i < encodedSystemUiOverlay.length; i++) {
      const encodedOverlay = encodedSystemUiOverlay[i];
      const overlay = this.getSystemUiOverlayFromValue(encodedOverlay);
      switch (overlay) {
        case SystemUiOverlay.TOP_OVERLAYS:
          overlays.push(SystemUiOverlay.TOP_OVERLAYS);
          break;
        case SystemUiOverlay.BOTTOM_OVERLAYS:
          overlays.push(SystemUiOverlay.BOTTOM_OVERLAYS);
          break;
      }
    }
    return overlays;
  }

  getSystemUiModeFromValue(encodedName: string): SystemUiMode {
    for (const mode in SystemUiMode) {
      if (SystemUiMode[mode] === encodedName) {
        return SystemUiMode[mode];
      }
    }
    throw new Error("No such SystemUiOverlay: " + encodedName);
  }
  getBrightnessFromValue(encodedName: string): Brightness {
    for (const brightness in Brightness) {
      if (Brightness[brightness] === encodedName) {
        return Brightness[brightness];
      }
    }
    throw new Error("No such Brightness: " + encodedName);
  }
  getDeviceOrientationFromValue(encodedName: string): DeviceOrientation {
    for (const orientation in DeviceOrientation) {
      if (DeviceOrientation[orientation] === encodedName) {
        return DeviceOrientation[orientation];
      }
    }
    throw new Error("No such DeviceOrientation: " + encodedName);
  }

  private decodeSystemUiMode(encodedSystemUiMode: string): SystemUiMode {
    let mode: SystemUiMode = this.getSystemUiModeFromValue(encodedSystemUiMode);
    switch (mode) {
      case SystemUiMode.LEAN_BACK:
        return SystemUiMode.LEAN_BACK;
      case SystemUiMode.IMMERSIVE:
        return SystemUiMode.IMMERSIVE;
      case SystemUiMode.IMMERSIVE_STICKY:
        return SystemUiMode.IMMERSIVE_STICKY;
      case SystemUiMode.EDGE_TO_EDGE:
        return SystemUiMode.EDGE_TO_EDGE;
    }
    return SystemUiMode.EDGE_TO_EDGE;

  }

  private decodeSystemChromeStyle(encodedStyle: any): SystemChromeStyle {
    let statusBarColor: number = null;
    let statusBarIconBrightness: Brightness = null;
    let systemStatusBarContrastEnforced: boolean = null;
    let systemNavigationBarColor: number = null;
    let systemNavigationBarIconBrightness: Brightness = null;
    let systemNavigationBarDividerColor: number = null;
    let systemNavigationBarContrastEnforced: boolean = null;
    if(encodedStyle.statusBarColor != null) {
      statusBarColor = encodedStyle.statusBarColor as number;
    }
    if(encodedStyle.statusBarIconBrightness != null) {
      statusBarIconBrightness =
        this.getBrightnessFromValue(encodedStyle.statusBarIconBrightness as string);
    }
    if(encodedStyle.systemStatusBarContrastEnforced != null) {
      systemStatusBarContrastEnforced = encodedStyle.systemStatusBarContrastEnforced as boolean;
    }
    if(encodedStyle.systemNavigationBarColor != null) {
      systemNavigationBarColor = encodedStyle.systemNavigationBarColor as number;
    }
    if(encodedStyle.systemNavigationBarIconBrightness != null) {
      systemNavigationBarIconBrightness =
        this.getBrightnessFromValue(encodedStyle.systemNavigationBarIconBrightness as string);
    }
    if(encodedStyle.systemNavigationBarDividerColor != null) {
      systemNavigationBarDividerColor = encodedStyle.systemNavigationBarDividerColor as number;
    }
    if(encodedStyle.systemNavigationBarContrastEnforced != null) {
      systemNavigationBarContrastEnforced = encodedStyle.systemNavigationBarContrastEnforced as boolean;
    }
    return new SystemChromeStyle(
      statusBarColor,
      statusBarIconBrightness,
      systemStatusBarContrastEnforced,
      systemNavigationBarColor,
      systemNavigationBarIconBrightness,
      systemNavigationBarDividerColor,
      systemNavigationBarContrastEnforced
    );
  }

}
export enum HapticFeedbackType {
  STANDARD = "STANDARD",
  LIGHT_IMPACT = "HapticFeedbackType.lightImpact",
  MEDIUM_IMPACT = "HapticFeedbackType.mediumImpact",
  HEAVY_IMPACT = "HapticFeedbackType.heavyImpact",
  SELECTION_CLICK = "HapticFeedbackType.selectionClick"
}

export interface PlatformMessageHandler {
  playSystemSound(soundType: SoundType): void;

  vibrateHapticFeedback(feedbackType: HapticFeedbackType): void;

  setPreferredOrientations(ohosOrientation: number): void;

  setApplicationSwitcherDescription(description: AppSwitcherDescription): void;

  showSystemOverlays(overlays: SystemUiOverlay[]): void;

  showSystemUiMode(mode: SystemUiMode): void;

  setSystemUiChangeListener(): void;

  restoreSystemUiOverlays(): void;

  setSystemUiOverlayStyle(systemUiOverlayStyle: SystemChromeStyle): void;

  popSystemNavigator(): void;

  getClipboardData(format: ClipboardContentFormat): string;

  setClipboardData(text: string): void;

  clipboardHasStrings(): boolean;

}

export enum ClipboardContentFormat {
  PLAIN_TEXT = "text/plain",
}

export enum SoundType {
  CLICK = "SystemSoundType.click",
  ALERT = "SystemSoundType.alert",
}

export class AppSwitcherDescription {
  public readonly color: number;
  public readonly label: string;

  constructor(color: number, label: string) {
    this.color = color;
    this.label = label;
  }
}

export enum SystemUiOverlay {
  TOP_OVERLAYS = "SystemUiOverlay.top",
  BOTTOM_OVERLAYS = "SystemUiOverlay.bottom",
}

export enum SystemUiMode {
  LEAN_BACK = "SystemUiMode.leanBack",
  IMMERSIVE = "SystemUiMode.immersive",
  IMMERSIVE_STICKY = "SystemUiMode.immersiveSticky",
  EDGE_TO_EDGE = "SystemUiMode.edgeToEdge",
}

export enum Brightness {
  LIGHT = "Brightness.light",
  DARK = "Brightness.dark",
}

export class SystemChromeStyle {
  public readonly statusBarColor: number | null;
  public readonly statusBarIconBrightness: Brightness | null;
  public readonly systemStatusBarContrastEnforced: boolean | null;
  public readonly systemNavigationBarColor: number | null;
  public readonly systemNavigationBarIconBrightness: Brightness | null;
  public readonly systemNavigationBarDividerColor: number | null;
  public readonly systemNavigationBarContrastEnforced: boolean | null;

  constructor(statusBarColor: number | null,
              statusBarIconBrightness: Brightness | null,
              systemStatusBarContrastEnforced: boolean | null,
              systemNavigationBarColor: number | null,
              systemNavigationBarIconBrightness: Brightness | null,
              systemNavigationBarDividerColor: number | null,
              systemNavigationBarContrastEnforced: boolean | null) {
    this.statusBarColor = statusBarColor;
    this.statusBarIconBrightness = statusBarIconBrightness;
    this.systemStatusBarContrastEnforced = systemStatusBarContrastEnforced;
    this.systemNavigationBarColor = systemNavigationBarColor;
    this.systemNavigationBarIconBrightness = systemNavigationBarIconBrightness;
    this.systemNavigationBarDividerColor = systemNavigationBarDividerColor;
    this.systemNavigationBarContrastEnforced = systemNavigationBarContrastEnforced;
  }
}

enum DeviceOrientation {
  PORTRAIT_UP = "DeviceOrientation.portraitUp",
  PORTRAIT_DOWN = "DeviceOrientation.portraitDown",
  LANDSCAPE_LEFT = "DeviceOrientation.landscapeLeft",
  LANDSCAPE_RIGHT = "DeviceOrientation.landscapeRight",
}