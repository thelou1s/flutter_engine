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
  private prevLeft: number = 0;
  private prevTop: number = 0;
  private left: number = 0;
  private top: number = 0;
  private bufferWidth: number = 0;
  private bufferHeight: number = 0;
  private touchProcessor: OhosTouchProcessor | null = null;


  private model : DVModel = createDVModelFromJson( new DVModelParam("Column", []));

  public setTouchProcessor(newTouchProcessor: OhosTouchProcessor): void {
    this.touchProcessor = newTouchProcessor;
  }

  constructor() {
  }

  public getDvModel(): DVModel {
    return this.model;
  }

  setParams: (params: DVModelParameters, key: string, element: ESObject ) => void = (params: DVModelParameters, key: string, element: ESObject): void => {
    let params2 = params as Record<string, ESObject>;
    params2[key] =element;
  }

  getParams: (params: DVModelParameters, element: string) => string | ESObject = (params: DVModelParameters, element: string): string | ESObject => {
    let params2 = params as Record<string, ESObject>;
    return params2[element];
  }

  public setLayoutParams(parameters : DVModelParameters): void {
    if (!this.model) {
      return;
    }
    if (this.model.params == null) {
      this.model.params = new DVModelParameters();
    }
    this.setParams(this.model.params, "marginLeft", this.getParams(parameters, "marginLeft"));
    this.setParams(this.model.params, "marginTop", this.getParams(parameters, "marginTop"));
    this.left =  this.getParams(parameters, "marginLeft");
    this.top = this.getParams(parameters, "marginTop");

    this.setParams(this.model.params, "width", this.getParams(parameters, "width"));
    this.setParams(this.model.params, "height", this.getParams(parameters, "height"));

    // this.model.params.marginLeft = parameters.marginLeft;
    // this.model.params.marginTop = parameters.marginTop;
    // this.left = parameters.marginLeft;
    // this.top = parameters.marginTop;;

    // this.model.params.width = parameters.width;
    // this.model.params.height = parameters.height;
  }

  public addDvModel(model: DVModel): void {
    this.model?.children.push(model);
  }
}

class DVModelParam {
  compType: string
  children: []

  constructor(compType: string, children: []) {
    this.compType = compType;
    this.children = children;
  }
};