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

import UIAbility from '@ohos.app.ability.UIAbility'
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

export interface AbilityPluginBinding {
  getAbility(): UIAbility;
  /**
   * Adds a listener that is invoked whenever the associated {@link ohos.app.ability.UIAbility}'s {@code
   * onNewWant(...)} method is invoked.
   */
  addOnNewWantListener(listener: NewWantListener): void;

  /**
   * Removes a listener that was added in {@link
   * #addOnNewWantListener(NewWantListener)}.
   */
  removeOnNewWantListener(listener: NewWantListener): void;

  /**
   * Adds a listener that is invoked whenever the associated {@link ohos.app.ability.UIAbility}'s {@code
   * windowStageEvent} method is invoked.
   */
  addOnWindowFocusChangedListener(listener: WindowFocusChangedListener): void;

  /**
   * Removes a listener that was added in {@link
   * #addOnWindowFocusChangedListener(WindowFocusChangedListener)}.
   */
  removeOnWindowFocusChangedListener(listener: WindowFocusChangedListener): void;

  /**
   * Adds a listener that is invoked when the associated {@code UIAbility} saves
   * and restores instance state.
   */
  addOnSaveStateListener(listener: OnSaveStateListener): void;

  /**
   * Removes a listener that was added in {@link
   * #addOnSaveStateListener(OnSaveStateListener)}.
   */
  removeOnSaveStateListener(listener: OnSaveStateListener): void;
}

/**
 * Delegate interface for handling new wants on behalf of the main {@link ohos.app.ability.UIAbility}.
 */
export interface NewWantListener {
  /**
   * @param intent The new want that was started for the UIAbility.
   * @return true if the new want has been handled.
   */
  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void;
}

/**
 * Delegate interface for handling window focus changes on behalf of the main {@link
 * ohos.app.ability.UIAbility}.
 */
export interface WindowFocusChangedListener {
  onWindowFocusChanged(hasFocus: boolean): void;
}

export interface OnSaveStateListener {
  /**
   * Invoked when the associated {@code UIAbility} or {@code Fragment} executes {@link
   * Activity#onSaveState(Bundle)}.
   */
  onSaveState(reason: AbilityConstant.StateType, wantParam: Record<string, Object>): AbilityConstant.OnSaveResult;
}