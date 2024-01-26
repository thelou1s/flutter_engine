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

import { BuilderParams, DVModelParameters } from '../view/DynamicView/dynamicView';

@Component
struct XComponentStruct {
  private context:ESObject;
  dvModelParams: DVModelParameters = new DVModelParameters();

  build() {
    XComponent({ id: (this.dvModelParams as Record<string, ESObject>)["xComponentId"], type: XComponentType.TEXTURE, libraryname: 'flutter'})
      .onLoad((context) => {
        this.context = context;
      })
      .onDestroy(() => {
      })
  }
}

@Builder export function BuildXComponentStruct(buildParams: BuilderParams) {
  XComponentStruct({dvModelParams: buildParams.params});
}