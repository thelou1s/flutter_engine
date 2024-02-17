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
import { FlutterView } from '../view/FlutterView';
import common from '@ohos.app.ability.common';
import PlatformViewController from '../plugin/platform/PlatformViewsController'

export default class FlutterPluginRegistry {
  private mPlatformViewsController: PlatformViewController;
  private mFlutterView: FlutterView | null = null;
  private mContext: common.Context | null = null;

  constructor() {
    this.mPlatformViewsController = new PlatformViewController();
    this.mFlutterView = null;
    this.mContext = null;
  }

  attach(flutterView: FlutterView, context: common.Context): void {
    this.mFlutterView = flutterView;
    this.mContext = context;
  }

  detach(): void {
    this.mPlatformViewsController.detach();
    this.mPlatformViewsController.onDetachedFromNapi();
    this.mFlutterView = null;
    this.mContext = null;
  }

  destroy(): void {
    this.mPlatformViewsController.onDetachedFromNapi();
  }

  onPreEngineRestart(): void{
    this.mPlatformViewsController.onPreEngineRestart();
  }
}