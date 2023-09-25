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

import ArrayList from '@ohos.util.ArrayList';
import { DVModel, DVModelParameters } from '../../../view/DynamicView/dynamicView';
import { createDVModelFromJson } from '../../../view/DynamicView/dynamicViewJson';
import OhosTouchProcessor from '../../ohos/OhosTouchProcessor';
import { FlutterMutator, FlutterMutatorsStack } from './FlutterMutatorsStack'

export class FlutterMutatorView {
  private mutatorsStack: FlutterMutatorsStack;
  private screenDensity: number;
  private left: number;
  private top: number;
  private prevLeft: number;
  private prevTop: number;
  private ohosTouchProcessor: OhosTouchProcessor;
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
  private model: DVModel = createDVModelFromJson(
    {
      compType: "Column",
      children: [],
      attributes: { backgroundColor: Color.Red },
      events: { onTouch: this.onTouch }
    }
  );

  setOnDescendantFocusChangeListener(onFocus: () => void, onBlur: () => void) {
    this.model.events["onFocus"] = onFocus;
    this.model.events["onBlur"] = onBlur;
  }

  public setLayoutParams(parameters: DVModelParameters): void {
    if (this.model.params == null) {
      this.model.params = new DVModelParameters();
    }
    this.model.params['marginLeft'] = parameters['marginLeft'];
    this.model.params['marginTop'] = parameters['marginTop'];
    this.model.params['width'] = parameters['width'];
    this.model.params['height'] = parameters['height'];
    this.left = parameters['marginLeft'];
    this.top = parameters['marginTop'];
  }

  public addDvModel(model: DVModel): void {
    this.model.children.push(model);
  }

  public readyToDisplay(mutatorsStack: FlutterMutatorsStack, left: number, top: number, width: number, height: number) {
    this.mutatorsStack = mutatorsStack;
    this.left = left;
    this.top = top;
    let parameters = new DVModelParameters();
    parameters['marginLeft'] = left;
    parameters['marginTop'] = top;
    parameters['width'] = width;
    parameters['height'] = height;
    this.setLayoutParams(parameters);
    this.dealMutators();
  }

  private dealMutators() {
    let paths = this.mutatorsStack.getFinalClippingPaths();
    let rects = this.mutatorsStack.getFinalClippingRects();
    let matrix = this.mutatorsStack.getFinalMatrix();
    if (!paths.isEmpty()) {
      let path = paths.getLast();
      this.model.params["pathWidth"] = path.width;
      this.model.params["pathHeight"] = path.height;
      this.model.params["pathCommands"] = path.commands;
    }
    if (!rects.isEmpty()) {
      let rect = rects.getLast();
      this.model.params["rectWidth"] = rect.width;
      this.model.params["rectHeight"] = rect.height;
      this.model.params["rectRadius"] = rect.radius;
    }
    this.model.params["matrix"] = matrix;
  }

  public getDvModel(): DVModel {
    return this.model;
  }
}