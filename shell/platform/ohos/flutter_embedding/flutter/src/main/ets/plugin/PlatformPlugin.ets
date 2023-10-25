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
import PlatformChannel, {
  AppSwitcherDescription,
  Brightness,
  ClipboardContentFormat,
  HapticFeedbackType,
  PlatformMessageHandler,
  SoundType,
  SystemChromeStyle,
  SystemUiMode,
  SystemUiOverlay
} from '../embedding/engine/systemchannels/PlatformChannel';
import pasteboard from '@ohos.pasteboard';
import Log from '../util/Log';
import vibrator from '@ohos.vibrator';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';

/**
 * ohos实现platform plugin
 */
export default class PlatformPlugin {
  private static TAG = "PlatformPlugin";
  private callback = new PlatformPluginCallback();

  constructor(platformChannel: PlatformChannel, context: common.Context, platformPluginDelegate?: PlatformPluginDelegate) {
    this.callback.platformChannel = platformChannel;
    this.callback.context = context;
    this.callback.applicationContext = context.getApplicationContext();
    this.callback.platform = this;

    try {
      window.getLastWindow(context, (err, data) => {
        if (err.code) {
          Log.e(PlatformPlugin.TAG, "Failed to obtain the top window. Cause: " + JSON.stringify(err));
          return;
        }
        this.callback.windowClass = data;
      });
    } catch (err) {
      Log.e(PlatformPlugin.TAG, "Failed to obtain the top window. Cause: " + JSON.stringify(err));
    }
    this.callback.platformPluginDelegate = platformPluginDelegate;
    this.callback.platformChannel.setPlatformMessageHandler(this.callback);
  }


  updateSystemUiOverlays(): void {
    this.callback.windowClass.setWindowSystemBarEnable(this.callback.showBarOrNavigation);
    if (this.callback.currentTheme != null) {
      this.callback.setSystemChromeSystemUIOverlayStyle(this.callback.currentTheme);
    }
  }

  setUIAbilityContext(context: common.UIAbilityContext): void {
    this.callback.uiAbilityContext = context;
  }

  setSystemChromeChangeListener(): void {
    if (this.callback.callbackId == null && this.callback.applicationContext != null) {
      let that = this;
      this.callback.callbackId = this.callback.applicationContext.on('environment', {
        onConfigurationUpdated(config) {
          Log.d(PlatformPlugin.TAG, "onConfigurationUpdated: " + that.callback.showBarOrNavigation);
          that.callback.platformChannel.systemChromeChanged(that.callback.showBarOrNavigation.includes('status'));
        },
        onMemoryLevel(level) {
        }
      })
    }
  }
}

export interface PlatformPluginDelegate {
  popSystemNavigator(): boolean;
}

class PlatformPluginCallback implements PlatformMessageHandler {
  private static TAG = "PlatformPluginCallback";
  platform: PlatformPlugin;
  windowClass: window.Window = null;
  platformChannel: PlatformChannel;
  platformPluginDelegate: PlatformPluginDelegate;
  context: common.Context;
  showBarOrNavigation: ('status' | 'navigation')[] = ['status', 'navigation'];
  uiAbilityContext: common.UIAbilityContext = null;
  callbackId: number = null;
  applicationContext: common.ApplicationContext = null;
  currentTheme: SystemChromeStyle = null;

  playSystemSound(soundType: SoundType) {
  }

  vibrateHapticFeedback(feedbackType: HapticFeedbackType) {
    switch (feedbackType) {
      case HapticFeedbackType.STANDARD:
        vibrator.startVibration({ type: 'time', duration: 100 },
          { id: 0, usage: 'touch' });
        break;
      case HapticFeedbackType.LIGHT_IMPACT:
        vibrator.startVibration({ type: 'time', duration: 100 },
          { id: 0, usage: 'notification' }).then();
        break;
      case HapticFeedbackType.MEDIUM_IMPACT:
        vibrator.startVibration({ type: 'time', duration: 100 },
          { id: 0, usage: 'ring' });
        break;
      case HapticFeedbackType.HEAVY_IMPACT:
        vibrator.startVibration({ type: 'time', duration: 100 },
          { id: 0, usage: 'alarm' });
        break;
      case HapticFeedbackType.SELECTION_CLICK:
        vibrator.startVibration({ type: 'time', duration: 100 },
          { id: 0, usage: 'physicalFeedback' });
        break;
    }
  }

  setPreferredOrientations(ohosOrientation: number) {
    Log.d(PlatformPluginCallback.TAG, "ohosOrientation: " + ohosOrientation);
    this.windowClass.setPreferredOrientation(ohosOrientation);
  }

  setApplicationSwitcherDescription(description: AppSwitcherDescription) {
    //   representation described in the given {@code description}.
  }

  showSystemOverlays(overlays: SystemUiOverlay[]) {
    this.setSystemChromeEnabledSystemUIOverlays(overlays);
  }

  showSystemUiMode(mode: SystemUiMode) {
    this.setSystemChromeEnabledSystemUIMode(mode);
  }

  setSystemUiChangeListener() {
    this.platform.setSystemChromeChangeListener();
  }

  restoreSystemUiOverlays() {
    this.platform.updateSystemUiOverlays();
  }

  setSystemUiOverlayStyle(systemUiOverlayStyle: SystemChromeStyle) {
    Log.d(PlatformPluginCallback.TAG, "systemUiOverlayStyle:" + JSON.stringify(systemUiOverlayStyle));
    this.setSystemChromeSystemUIOverlayStyle(systemUiOverlayStyle);
  }

  popSystemNavigator() {
    if (this.platformPluginDelegate != null && this.platformPluginDelegate.popSystemNavigator()) {
      return;
    }
    if (this.uiAbilityContext != null) {
      this.uiAbilityContext.terminateSelf();
    }
  }

  getClipboardData(format: ClipboardContentFormat): string {
    // todo
    return "";
  }

  setClipboardData(text: string) {
    let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    let clipboard = pasteboard.getSystemPasteboard();
    clipboard.setData(pasteData);
  }

  clipboardHasStrings(): boolean {
    return false;
  }

  setSystemChromeEnabledSystemUIMode(mode: SystemUiMode): void {
    Log.d(PlatformPluginCallback.TAG, "mode: " + mode);
    let uiConfig: ('status' | 'navigation')[] = [];
    if (mode == SystemUiMode.LEAN_BACK) {
      //全屏显示，通过点击显示器上的任何位置都可以显示状态和导航栏
      this.windowClass.setWindowLayoutFullScreen(false);

    } else if (mode == SystemUiMode.IMMERSIVE) {
      //全屏显示，通过在显示器边缘的滑动手势可以显示状态和导航栏,应用程序不会接收到此手势
      this.windowClass.setWindowLayoutFullScreen(true);

    } else if (mode == SystemUiMode.IMMERSIVE_STICKY) {
      //全屏显示，通过在显示器边缘的滑动手势可以显示状态和导航栏,此手势由应用程序接收
      this.windowClass.setWindowLayoutFullScreen(true);

    } else if (mode == SystemUiMode.EDGE_TO_EDGE) {
      //全屏显示，在应用程序上呈现状态和导航元素
      this.windowClass.setWindowLayoutFullScreen(false);
      uiConfig = ['status', 'navigation'];

    } else {
      return;
    }
    this.showBarOrNavigation = uiConfig;
    this.platform.updateSystemUiOverlays();
  }

  setSystemChromeSystemUIOverlayStyle(systemChromeStyle: SystemChromeStyle): void {
    let isStatusBarLightIconValue: boolean = false;
    let statusBarColorValue: string = null;
    let statusBarContentColorValue: string = null;
    let navigationBarColorValue: string = null;
    let isNavigationBarLightIconValue: boolean = false;
    let navigationBarContentColorValue: string = null;
    if (systemChromeStyle.statusBarIconBrightness != null) {
      switch (systemChromeStyle.statusBarIconBrightness) {
        case Brightness.DARK:
          isStatusBarLightIconValue = false;
          break;
        case Brightness.LIGHT:
          isStatusBarLightIconValue = true;
          break;
      }
    }

    if (systemChromeStyle.statusBarColor != null) {
      statusBarColorValue = "#" + systemChromeStyle.statusBarColor.toString(16);
    }

    if (systemChromeStyle.systemStatusBarContrastEnforced != null) {

    }

    if (systemChromeStyle.systemNavigationBarIconBrightness != null) {
      switch (systemChromeStyle.systemNavigationBarIconBrightness) {
        case Brightness.DARK:
          isNavigationBarLightIconValue = true;
          break;
        case Brightness.LIGHT:
          isNavigationBarLightIconValue = false;
      }
    }

    if (systemChromeStyle.systemNavigationBarColor != null) {
      navigationBarColorValue = "#" + systemChromeStyle.systemNavigationBarColor.toString(16);
    }

    if (systemChromeStyle.systemNavigationBarContrastEnforced != null) {

    }
    this.currentTheme = systemChromeStyle;
    let systemBarProperties = new SystemBarProperties();
    systemBarProperties.statusBarColor = statusBarColorValue;
    systemBarProperties.isStatusBarLightIcon = isStatusBarLightIconValue;
    systemBarProperties.statusBarContentColor = statusBarContentColorValue;
    systemBarProperties.navigationBarColor = navigationBarColorValue;
    systemBarProperties.isNavigationBarLightIcon = isNavigationBarLightIconValue;
    systemBarProperties.navigationBarContentColor = navigationBarContentColorValue;
    Log.d(PlatformPluginCallback.TAG, "systemBarProperties: " + JSON.stringify(systemBarProperties));
    this.windowClass.setWindowSystemBarProperties(systemBarProperties);
  }

  setSystemChromeEnabledSystemUIOverlays(overlays: SystemUiOverlay[]): void {
    let uiConfig: ('status' | 'navigation')[] = [];
    if (overlays.length == 0) {

    }
    for (let index = 0; index < overlays.length; ++index) {
      let overlayToShow = overlays[index];
      switch (overlayToShow) {
        case SystemUiOverlay.TOP_OVERLAYS:
          uiConfig.push('status'); //hide navigation
          break;
        case SystemUiOverlay.BOTTOM_OVERLAYS:
          uiConfig.push('navigation'); //hide bar
          break;
      }
    }
    this.showBarOrNavigation = uiConfig;
    this.platform.updateSystemUiOverlays();
  }
}

class SystemBarProperties {
  statusBarColor?: string;

  isStatusBarLightIcon?: boolean;

  statusBarContentColor?: string;

  navigationBarColor?: string;

  isNavigationBarLightIcon?: boolean;

  navigationBarContentColor?: string;
}
