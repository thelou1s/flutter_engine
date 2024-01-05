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
  DVModelChildren,
  DVModelContainer,
  DVModelEvents,
  DVModelParameters } from '../../view/DynamicView/dynamicView';
import Log from '../../util/Log';

export class RootDvModeManager {
  private static model: DVModel = new DVModel("Stack", new DVModelParameters(), new DVModelEvents(), new DVModelChildren(), null);

  private static container : DVModelContainer = new DVModelContainer(RootDvModeManager.model);

  public static getRootDvMode(): DVModelContainer {
    return RootDvModeManager.container;
  }

  public static addDvModel(model: DVModel): void {
    RootDvModeManager.container.model.children.push(model);
    Log.i("flutter RootDvModeManager", 'DVModel: %{public}s', JSON.stringify(RootDvModeManager.container.model.children) ?? '');
  }
}
