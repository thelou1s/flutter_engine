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

import HashMap from '@ohos.util.HashMap';
import PlatformViewFactory from './PlatformViewFactory'
import PlatformViewRegistry from './PlatformViewRegistry'

export default class PlatformViewRegistryImpl implements PlatformViewRegistry {
  // Maps a platform view type id to its factory.
  private viewFactories: HashMap<String, PlatformViewFactory>;

  constructor() {
    this.viewFactories = new HashMap();
  }

  registerViewFactory(viewTypeId: string, factory: PlatformViewFactory): boolean {
    if (this.viewFactories.hasKey(viewTypeId)) {
      return false;
    }

    this.viewFactories.set(viewTypeId, factory);
    return true;
  }

  getFactory(viewTypeId: string): PlatformViewFactory {
    return this.viewFactories.get(viewTypeId);
  }
}
