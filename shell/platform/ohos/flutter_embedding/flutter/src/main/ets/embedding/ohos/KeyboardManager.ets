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
import FlutterEngine from '../engine/FlutterEngine';
import KeyEventChannel, { FlutterKeyEvent } from '../engine/systemchannels/KeyEventChannel';

export default class KeyboardManager {
  private keyEventChannel: KeyEventChannel | null = null

  constructor(engine: FlutterEngine) {
    this.keyEventChannel = new KeyEventChannel(engine.dartExecutor)
  }

  handleKeyEvent(event: KeyEvent) {
    this.keyEventChannel?.sendFlutterKeyEvent(new FlutterKeyEvent(event), event.type == KeyType.Up, {
      onFrameworkResponse: (isEventHandled: boolean): void => {

      }
    })
  }
}