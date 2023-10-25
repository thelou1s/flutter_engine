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
import { PlatformViewWrapper } from '../../plugin/platform/PlatformViewWrapper';
import { RootDvModeManager } from '../../plugin/platform/RootDvModelManager';
import { DVModel,
  DVModelChildren,
  DVModelContainer,
  DVModelEvents,
  DVModelParameters, DynamicView } from '../../view/DynamicView/dynamicView';
import { createDVModelFromJson } from '../../view/DynamicView/dynamicViewJson';

/**
 * 基础page组件，承载XComponent组件
 */
@Component
export struct FlutterPage {
  @State message: string = 'Hello World';

  @State rootDvModel: DVModelContainer = RootDvModeManager.getRootDvMode();

  build() {
    DynamicView({
      model: this.rootDvModel.model as DVModel,
      params: this.rootDvModel.model.params as DVModelParameters,
      events: this.rootDvModel.model.events as DVModelEvents,
      children: this.rootDvModel.model.children as DVModelChildren,
      customBuilder: this.rootDvModel.model.builder as ($$: Record<"params",DVModelParameters >) => void
      //customBuilder: this.rootDvModel.model.builder as ($$: { params: DVModelParameters }) => void
    })
  }
}