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

import PlatformViewFactory from './PlatformViewFactory'

/**
 * Registry for platform view factories.
 *
 * <p>Plugins can register factories for specific view types.
 */
export default interface PlatformViewRegistry {
  /**
   * Registers a factory for a platform view.
   *
   * @param viewTypeId unique identifier for the platform view's type.
   * @param factory factory for creating platform views of the specified type.
   * @return true if succeeded, false if a factory is already registered for viewTypeId.
   */
  registerViewFactory(viewTypeId: string, factory: PlatformViewFactory): boolean;
}