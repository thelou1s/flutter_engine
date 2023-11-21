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

import common from '@ohos.app.ability.common';
import resourceManager from '@ohos.resourceManager';
import FlutterNapi from '../../../ets/embedding/engine/FlutterNapi';
import image from '@ohos.multimedia.image';

/**
 * 设置刷新率
 */
export const nativeUpdateRefreshRate: (
  ate: number
) => void;

/**
 * 初始化dart vm和flutter engine
 */
export const nativeInit: (
  context: common.Context,
  args: Array<string>,
  bundlePath: string,
  appStoragePath: string,
  engineCachesPath: string,
  initTimeMillis: number
) => void;


/**
 * 加载dart工程构建产物
 */
export const nativeRunBundleAndSnapshotFromLibrary: (
  bundlePath: string,
  entrypointFunctionName: string,
  pathToEntrypointFunction: string,
  assetManager: resourceManager.ResourceManager,
  entrypointArgs: Array<string>
) => void;

/**
 * 初始化SkFontMgr::RefDefault()，skia引擎文字管理初始化
 */
export const nativePrefetchDefaultFontManager: () => void;

/**
 * 返回是否支持软件绘制
 */
export const nativeGetIsSoftwareRenderingEnabled: () => boolean;

/**
 * attach flutterNapi实例给到 native engine，这个支持rkts到flutter平台的无关引擎之间的通信。
 * attach只需要执行一次
 */
export const nativeAttach: (flutterNapi: FlutterNapi) => number;

/**
 * 从当前的flutterNapi复制一个新的实例
 */
export const nativeSpawn: (
  nativeSpawningShellId: number,
  entrypointFunctionName: string,
  pathToEntrypointFunction: string,
  initialRoute: string,
  entrypointArgs: Array<string>
) => number;

/**
 * Detaches flutterNapi和engine之间的关联
 * 这个方法执行前提是flutterNapi已经和engine关联
 */
export const nativeDestroy: (
  nativeShellHolderId: number
) => void;

// 不需要实现，未使用到
// export const nativeImageHeaderCallback: (
//   imageGeneratorPointer: number,
//   width: number,
//   height: number
// ) => void;

/**
 * 不需要实现，c++层已有nativeSurface回调
 */
// export const nativeSurfaceCreated: (
//   nativeShellHolderId: number
// ) => void;


/**
 * 不需要实现，c++层已有nativeSurface回调
 */
// export const nativeSurfaceWindowChanged: (
//   nativeShellHolderId: number
// ) => void;


/**
 * 不需要实现，c++层已有nativeSurface回调
 */
// export const nativeSurfaceChanged: (
//   nativeShellHolderId: number,
//   width: number,
//   height: number
// ) => void;

/**
 * 不需要实现，c++层已有nativeSurface回调
 */
// export const nativeSurfaceDestroyed: (
//   nativeShellHolderId: number
// ) => void;

/**
 * 把物理屏幕参数通知到native
 */
export const nativeSetViewportMetrics: (
  nativeShellHolderId: number,
  devicePixelRatio: number,
  physicalWidth: number,
  physicalHeight: number,
  physicalPaddingTop: number,
  physicalPaddingRight: number,
  physicalPaddingBottom: number,
  physicalPaddingLeft: number,
  physicalViewInsetTop: number,
  physicalViewInsetRight: number,
  physicalViewInsetBottom: number,
  physicalViewInsetLeft: number,
  systemGestureInsetTop: number,
  systemGestureInsetRight: number,
  systemGestureInsetBottom: number,
  systemGestureInsetLeft: number,
  physicalTouchSlop: number,
  displayFeaturesBounds: Array<number>,
  displayFeaturesType: Array<number>,
  displayFeaturesState: Array<number>
) => void;

/**
 * 设置能力参数
 */
export const nativeSetAccessibilityFeatures: (
  nativeShellHolderId: number,
  flags: number
) => void;

/**
 * 清除某个messageData
 */
export const nativeCleanupMessageData: (
  messageData: number
) => void;

/**
 * 发送一个空的PlatformMessage
 */
export const nativeDispatchEmptyPlatformMessage: (
  nativeShellHolderId: number,
  channel: string,
  responseId: number
) => void;

/**
 * 发送一个PlatformMessage
 */
export const nativeDispatchPlatformMessage: (
  nativeShellHolderId: number,
  channel: string,
  message: ArrayBuffer,
  position: number,
  responseId: number
) => void;

/**
 * 空的PlatformMessage响应回调
 */
export const nativeInvokePlatformMessageEmptyResponseCallback: (
  nativeShellHolderId: number,
  responseId: number
) => void;

/**
 * PlatformMessage响应回调
 */
export const nativeInvokePlatformMessageResponseCallback: (
  nativeShellHolderId: number,
  responseId: number,
  message: ArrayBuffer,
  position: number
) => void;


/**
 * load一个合法的.so文件到dart vm
 */
export const nativeLoadDartDeferredLibrary: (
  nativeShellHolderId: number,
  loadingUnitId: number,
  searchPaths: Array<string>
) => void;

/**
 * 设置ResourceManager和assetBundlePath到engine
 */
export const nativeUpdateOhosAssetManager: (
  nativeShellHolderId: number,
  resourceManager: resourceManager.ResourceManager,
  assetBundlePath: string
) => void;

/**
 * 加载动态库，或者dart库失败时的通知
 */
export const nativeDeferredComponentInstallFailure: (
  loadingUnitId: number,
  error: string,
  isTransient: boolean
) => void;

/**
 * 从engine获取当前绘制pixelMap
 */
export const nativeGetPixelMap: () => image.PixelMap;

/**
 * 应用低内存警告
 */
export const nativeNotifyLowMemoryWarning: (
  nativeShellHolderId: number
) => void;

// ----- Start FlutterTextUtils Methods ----
/**
 * 下面的方法，从键盘输入中判断当前字符是否是emoji，实现优先级低
 */
export const nativeFlutterTextUtilsIsEmoji: (
  codePoint: number
) => boolean;

export const nativeFlutterTextUtilsIsEmojiModifier: (
  codePoint: number
) => boolean;

export const nativeFlutterTextUtilsIsEmojiModifierBase: (
  codePoint: number
) => boolean;

export const nativeFlutterTextUtilsIsVariationSelector: (
  codePoint: number
) => boolean;

export const nativeFlutterTextUtilsIsRegionalIndicator: (
  codePoint: number
) => boolean;