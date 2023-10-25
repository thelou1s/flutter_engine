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

import AccessibilityBridge from '../../view/AccessibilityBridge';

export interface PlatformViewsAccessibilityDelegate {
  /**
   * Returns the root of the view hierarchy for the platform view with the requested id, or null if
   * there is no corresponding view.
   */
  getPlatformViewById(viewId: number): Object;

  /** Returns true if the platform view uses virtual displays. */
  usesVirtualDisplay(id: number): boolean;

  /**
   * Attaches an accessibility bridge for this platform views accessibility delegate.
   *
   * <p>Accessibility events originating in platform views belonging to this delegate will be
   * delegated to this accessibility bridge.
   */
  attachAccessibilityBridge(accessibilityBridge: AccessibilityBridge): void;

  /**
   * Detaches the current accessibility bridge.
   *
   * <p>Any accessibility events sent by platform views belonging to this delegate will be ignored
   * until a new accessibility bridge is attached.
   */
  detachAccessibilityBridge(): void;
}