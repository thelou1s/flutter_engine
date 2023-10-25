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

import MessageCodec from '../common/MessageCodec';
import PlatformView from './PlatformView'
import common from '@ohos.app.ability.common';

export default abstract class PlatformViewFactory {
  private createArgsCodec: MessageCodec<ESObject>;

  /** @param createArgsCodec the codec used to decode the args parameter of {@link #create}. */
  constructor(createArgsCodec: MessageCodec<ESObject>) {
    this.createArgsCodec = createArgsCodec;
  }

  /**
   * Creates a new Dynamic be embedded in the Flutter hierarchy.
   *
   * @param context the context to be used when creating the view, this is different than
   *     FlutterView's context.
   * @param viewId unique identifier for the created instance, this value is known on the Dart side.
   * @param args arguments sent from the Flutter app. The bytes for this value are decoded using the
   *     createArgsCodec argument passed to the constructor. This is null if createArgsCodec was
   *     null, or no arguments were sent from the Flutter app.
   */
  public abstract create(context: common.Context, viewId: number, args: ESObject): PlatformView;

  /** Returns the codec to be used for decoding the args parameter of {@link #create}. */
  getCreateArgsCodec(): MessageCodec<ESObject> {
    return this.createArgsCodec;
  }
}