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

import OhosTouchProcessor from '../../embedding/ohos/OhosTouchProcessor';
import { DVModel, DVModelParameters } from '../../view/DynamicView/dynamicView';
import { createDVModelFromJson } from '../../view/DynamicView/dynamicViewJson';
import { RootDvModeManager } from './RootDvModelManager';
import matrix4 from '@ohos.matrix4'
import Log from '../../util/Log';

const TAG: string = "PlatformViewWrapper";
export class PlatformViewWrapper {
  private prevLeft: number;
  private prevTop: number;
  private left: number;
  private top: number;
  private bufferWidth: number;
  private bufferHeight: number;
  private touchProcessor: OhosTouchProcessor;

  private onTouch = (touchEvent) => {
    switch (touchEvent.type) {
      case TouchType.Down:
        this.prevLeft = this.left;
        this.prevTop = this.top;
        this.model.params["translateX"] = this.left;
        this.model.params["translateY"] = this.top;
        break;
      case TouchType.Move:
        this.model.params["translateX"] = this.prevLeft;
        this.model.params["translateY"] = this.prevTop;
        this.prevLeft = this.left;
        this.prevTop = this.top;
        break;
      case TouchType.Up:
      case TouchType.Cancel:
      default:
        break;
    }
  }

  private model : DVModel = createDVModelFromJson(
    {
      compType: "Column",
      children: [],
      attributes: {backgroundColor: Color.Red},
      events: {onTouch : this.onTouch}
    }
  );

  public setTouchProcessor(newTouchProcessor: OhosTouchProcessor): void {
    this.touchProcessor = newTouchProcessor;
  }

  constructor() {
  }

  public getDvModel(): DVModel {
    return this.model;
  }

  public setLayoutParams(parameters : DVModelParameters): void {
    if (this.model.params == null) {
      this.model.params = new DVModelParameters();
    }
    this.model.params['marginLeft'] = parameters['marginLeft'];
    this.model.params['marginTop'] = parameters['marginTop'];
    this.left = parameters['marginLeft'];
    this.top = parameters['marginTop'];
  }

  public addDvModel(model: DVModel): void {
    this.model.children.push(model);
  }
}