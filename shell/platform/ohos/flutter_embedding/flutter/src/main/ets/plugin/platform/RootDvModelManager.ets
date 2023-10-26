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

import { DVModel,
  DVModelContainer,
  DVModelParameters } from '../../view/DynamicView/dynamicView';
import { createDVModelFromJson } from '../../view/DynamicView/dynamicViewJson';

@Component
struct XComponentStruct {
  private context:ESObject;

  build() {
    XComponent({ id: 'flutterXComponent', type: 'texture', libraryname: 'flutter' })
      .onLoad((context) => {
        this.context = context;
      })
      .onDestroy(() => {
      })
  }
}
interface  $$type{
  param: DVModelParameters
}
@Builder function BuildXComponentStruct($$: $$type) {
  XComponentStruct();
}

class  DVModelJson{
  compType: string
  children:Array<ESObject>
  attributes:ESObject

  constructor(compType:string , children:Array<ESObject> , attributes:ESObject) {
    this.compType = compType
    this.children = children
    this.attributes = attributes
  }
}
export class RootDvModeManager {
  private static xComponentModel:ESObject =
    {
      compType: "xComponent",
      build: BuildXComponentStruct
    };

  private static model: DVModel = createDVModelFromJson(new DVModelJson("Stack", [RootDvModeManager.xComponentModel], {alignContent: Alignment.TopStart},)

  );

  private static container : DVModelContainer = new DVModelContainer(RootDvModeManager.model);

  public static getRootDvMode(): DVModelContainer {
    return RootDvModeManager.container;
  }

  public static addDvModel(model: DVModel): void {
    RootDvModeManager.container.model.children.push(model);
  }
}
