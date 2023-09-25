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

import { FlutterPlugin } from './FlutterPlugin';

export default interface PluginRegistry {
  /**
   * Attaches the given {@code plugin} to the {@link io.flutter.embedding.engine.FlutterEngine}
   * associated with this {@code PluginRegistry}.
   */
  add(plugin: FlutterPlugin): void;

  /**
   * Attaches the given {@code plugins} to the {@link io.flutter.embedding.engine.FlutterEngine}
   * associated with this {@code PluginRegistry}.
   */
  addList(plugins: Set<FlutterPlugin>): void;

  /**
   * Returns true if a plugin of the given type is currently attached to the {@link
   * io.flutter.embedding.engine.FlutterEngine} associated with this {@code PluginRegistry}.
   */
  //Class<? extends FlutterPlugin>
  has(pluginClassName: string): boolean;

  /**
   * Returns the instance of a plugin that is currently attached to the {@link
   * io.flutter.embedding.engine.FlutterEngine} associated with this {@code PluginRegistry}, which
   * matches the given {@code pluginClass}.
   *
   * <p>If no matching plugin is found, {@code null} is returned.
   */
  //Class<? extends FlutterPlugin>
  get(pluginClassName: string): FlutterPlugin;

  /**
   * Detaches the plugin of the given type from the {@link
   * io.flutter.embedding.engine.FlutterEngine} associated with this {@code PluginRegistry}.
   *
   * <p>If no such plugin exists, this method does nothing.
   */
  //Class<? extends FlutterPlugin>
  remove(pluginClassName: string): void;

  /**
   * Detaches the plugins of the given types from the {@link
   * io.flutter.embedding.engine.FlutterEngine} associated with this {@code PluginRegistry}.
   *
   * <p>If no such plugins exist, this method does nothing.
   */
  //Class<? extends FlutterPlugin>
  removeList(pluginClassNames: Set<string>): void;

  /**
   * Detaches all plugins that are currently attached to the {@link
   * io.flutter.embedding.engine.FlutterEngine} associated with this {@code PluginRegistry}.
   *
   * <p>If no plugins are currently attached, this method does nothing.
   */
  removeAll(): void;
}