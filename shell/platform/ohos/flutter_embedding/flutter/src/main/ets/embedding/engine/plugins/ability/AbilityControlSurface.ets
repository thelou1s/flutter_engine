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

import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import UIAbility from '@ohos.app.ability.UIAbility';
import ExclusiveAppComponent from '../../../ohos/ExclusiveAppComponent';

export default interface ActivityControlSurface {
  attachToAbility(exclusiveActivity: ExclusiveAppComponent<UIAbility>): void;
  detachFromAbility(): void;
  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void;
  onWindowFocusChanged(hasFocus: boolean): void;
  onSaveState(reason: AbilityConstant.StateType, wantParam: Record<string, Object>): AbilityConstant.OnSaveResult;
}