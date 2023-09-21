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

export default interface ExclusiveAppComponent<T> {
  /**
   * Called when another App Component is about to become attached to the {@link
   * io.flutter.embedding.engine.FlutterEngine} this App Component is currently attached to.
   *
   * <p>This App Component's connections to the {@link io.flutter.embedding.engine.FlutterEngine}
   * are still valid at the moment of this call.
   */
  detachFromFlutterEngine(): void;

  /**
   * Retrieve the App Component behind this exclusive App Component.
   *
   * @return The app component.
   */
  getAppComponent(): T;
}