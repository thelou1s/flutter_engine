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

import TextInputChannel, {
  Configuration,
  TextEditState,
  TextInputMethodHandler,
  TextInputType
} from '../../embedding/engine/systemchannels/TextInputChannel';
import inputMethod from '@ohos.inputMethod';
import Log from '../../util/Log';
import { EditingStateWatcher, ListenableEditingState } from './ListenableEditingState';

export default class TextInputPlugin implements EditingStateWatcher {
  private static TAG = "TextInputPlugin";
  private textInputChannel: TextInputChannel;
  private mTextInputHandler: TextInputMethodHandlerImpl;

  constructor(textInputChannel: TextInputChannel) {
    this.textInputChannel = textInputChannel;
    this.mTextInputHandler = new TextInputMethodHandlerImpl(this);
    this.textInputChannel.setTextInputMethodHandler(this.mTextInputHandler);
  }

  public clearTextInputClient() {
    this.textInputChannel.textInputMethodHandler?.clearClient();
  }

  setTextInputEditingState(state: TextEditState) {

  }

  didChangeEditingState(textChanged: boolean, selectionChanged: boolean, composingRegionChanged: boolean): void {
    let editable = this.mTextInputHandler.mEditable;
    let inputTarget = this.mTextInputHandler.inputTarget;
    let configuration = this.mTextInputHandler.configuration;
    if (configuration!= null && configuration.enableDeltaModel) {
      this.textInputChannel.updateEditingStateWithDeltas(inputTarget.id,editable.extractBatchTextEditingDeltas());
      editable.clearBatchDeltas();
    } else {
      this.textInputChannel.updateEditingState(inputTarget.id, editable.getStringCache(),
        editable.getSelectionStart(), editable.getSelectionEnd(),
        editable.getComposingStart(), editable.getComposingEnd())
    }

  }

  detach(): void {
    this.mTextInputHandler.inputMethodController.detach((err) => {
      if (err) {
        Log.e(TextInputPlugin.TAG, "Failed to detach: " + JSON.stringify(err));
      }
    })
  }
}

class TextInputMethodHandlerImpl implements TextInputMethodHandler {
  private static TAG = "TextInputMethodHandlerImpl";
  private textConfig: inputMethod.TextConfig;
  inputMethodController: inputMethod.InputMethodController;
  inputTarget: InputTarget;
  public configuration: Configuration | null = null;
  mEditable: ListenableEditingState;
  private mRestartInputPending: boolean = false;
  private plugin: EditingStateWatcher | ESObject;
  private keyboardStatus: inputMethod.KeyboardStatus = KeyboardStatus.NONE;
  private imcFlag: boolean = false;

  constructor(plugin: TextInputPlugin | ESObject) {
    this.textConfig = {
      inputAttribute: {
        textInputType: 0,
        enterKeyType: 1
      } };
    this.plugin = plugin;
    this.mEditable = new ListenableEditingState(null, 0);
    this.inputMethodController = inputMethod.getController();
    this.inputTarget = new InputTarget(Type.NO_TARGET, 0);
  }

  show(): void {
    if (this.keyboardStatus == KeyboardStatus.SHOW) {
      return;
    }
    this.showTextInput();
    this.keyboardStatus = KeyboardStatus.SHOW;
  }

  hide(): void {
    this.hideTextInput();
    this.keyboardStatus = KeyboardStatus.HIDE;
  }

  requestAutofill(): void {

  }

  finishAutofillContext(shouldSave: boolean): void {

  }

  setClient(textInputClientId: number, configuration: Configuration | null): void {
    Log.d(TextInputMethodHandlerImpl.TAG, "textInputClientId: " + textInputClientId);
    this.setTextInputClient(textInputClientId, configuration);
  }

  setPlatformViewClient(id: number, usesVirtualDisplay: boolean): void {

  }

  setEditableSizeAndTransform(width: number, height: number, transform: number[]): void {

  }

  setEditingState(editingState: TextEditState): void {
    Log.d(TextInputMethodHandlerImpl.TAG, "text:" + editingState.text + " selectionStart:" + editingState.selectionStart + " selectionEnd:"
      + editingState.selectionEnd + " composingStart:" + editingState.composingStart + " composingEnd" + editingState.composingEnd);
    this.mEditable.updateTextInputState(editingState);
  }

  clearClient(): void {
    this.clearTextInputClient();
  }

  private async showTextInput(): Promise<void> {
    await this.attach(true);
    if (this.imcFlag != true) {
      this.listenKeyBoardEvent();
    }
    this.inputMethodController.showTextInput().then(() => {
      Log.d(TextInputMethodHandlerImpl.TAG, "Succeeded in showing softKeyboard");
    }).catch((err: ESObject) => {
      Log.e(TextInputMethodHandlerImpl.TAG, "Failed to show softKeyboard:" + JSON.stringify(err));
    });
  }

  private async hideTextInput(): Promise<void> {
    this.inputMethodController.hideTextInput().then(() => {
      Log.d(TextInputMethodHandlerImpl.TAG, "Succeeded in hide softKeyboard");
    }).catch((err: ESObject) => {
      Log.e(TextInputMethodHandlerImpl.TAG, "Failed to hide softKeyboard:" + JSON.stringify(err));
    })
  }

  async attach(showKeyboard: boolean): Promise<void> {
    try {
      await this.inputMethodController.attach(showKeyboard, this.textConfig);
    } catch (err) {
      Log.e(TextInputMethodHandlerImpl.TAG, "Failed to attach:" + JSON.stringify(err));
    }
  }

  setTextInputClient(client: number, configuration: Configuration | null): void {
    const INPUT_TYPE_NAME = ['NONE', 'TEXT', 'MULTILINE', 'NUMBER', 'PHONE', 'DATETIME', 'EMAIL_ADDRESS', 'URL', 'VISIBLE_PASSWORD']
    if (configuration) {
      this.configuration = configuration;
      if (configuration.inputType) {
        this.textConfig.inputAttribute.textInputType = INPUT_TYPE_NAME.indexOf(configuration.inputType.type)
        this.textConfig.inputAttribute.enterKeyType = configuration.inputAction as ESObject;
      }
    }
    if (this.canShowTextInput()) {
      this.inputTarget = new InputTarget(Type.FRAMEWORK_CLIENT, client);
    } else {
      this.inputTarget = new InputTarget(Type.NO_TARGET, client);
    }
    this.mEditable.removeEditingStateListener(this.plugin);

    this.mEditable = new ListenableEditingState(this.plugin.textInputChannel, this.inputTarget.id);

    this.mRestartInputPending = true;
    this.mEditable.addEditingStateListener(this.plugin);
  }

  canShowTextInput(): boolean {
    if (this.configuration == null || this.configuration.inputType == null) {
      return true;
    }
    return this.configuration.inputType.type != TextInputType.NONE;
  }

  listenKeyBoardEvent(): void {
    try {
      this.inputMethodController.on('insertText', (text) => {
        Log.d(TextInputMethodHandlerImpl.TAG, "insertText: " + text);
        this.mEditable.handleInsertTextEvent(text);
      });
    } catch (err) {
      Log.e(TextInputMethodHandlerImpl.TAG, "Failed to subscribe insertText:" + JSON.stringify(err));
      this.cancelListenKeyBoardEvent();
      return;
    }

    try {
      this.inputMethodController.on('deleteLeft', (length) => {
        this.mEditable.handleDeleteEvent(false, length);
      })
    } catch (err) {
      Log.e(TextInputMethodHandlerImpl.TAG, "Failed to subscribe deleteLeft:" + JSON.stringify(err));
      this.cancelListenKeyBoardEvent();
      return;
    }

    try {
      this.inputMethodController.on('deleteRight', (length) => {
        this.mEditable.handleDeleteEvent(true, length);
      })
    } catch (err) {
      Log.e(TextInputMethodHandlerImpl.TAG, "Failed to subscribe deleteRight:" + JSON.stringify(err));
      this.cancelListenKeyBoardEvent();
      return;
    }

    try {
      this.inputMethodController.on('sendFunctionKey', (functionKey) => {
        this.mEditable.handleFunctionKey(functionKey);
      })
    } catch (err) {
      Log.e(TextInputMethodHandlerImpl.TAG, "Failed to subscribe sendFunctionKey:" + JSON.stringify(err));
      this.cancelListenKeyBoardEvent();
      return;
    }

    try {
      this.inputMethodController.on('sendKeyboardStatus', (state) => {
        if (state == KeyboardStatus.HIDE) {
          this.keyboardStatus = KeyboardStatus.HIDE;
          this.plugin.textInputChannel.onConnectionClosed(this.inputTarget.id);
        }
      })
    } catch (err) {
      Log.e(TextInputMethodHandlerImpl.TAG, "Failed to subscribe sendKeyboardStatus:" + JSON.stringify(err));
      this.cancelListenKeyBoardEvent();
      return;
    }

    try {
      this.inputMethodController.on('selectByRange', (range: inputMethod.Range) => {
        this.mEditable.handleSelectByRange(range);
      })
    } catch (err) {
      Log.e(TextInputMethodHandlerImpl.TAG, "Failed to subscribe selectByRange:" + JSON.stringify(err));
      this.cancelListenKeyBoardEvent();
      return;
    }
    Log.d(TextInputMethodHandlerImpl.TAG, "listenKeyBoardEvent success");
    this.imcFlag = true;
  }

  cancelListenKeyBoardEvent(): void {
    this.inputMethodController.off('insertText');
    this.inputMethodController.off('deleteLeft');
    this.inputMethodController.off('deleteRight');
    this.inputMethodController.off('sendFunctionKey');
    this.inputMethodController.off('selectByRange');
  }

  public clearTextInputClient(): void {
    if (this.inputTarget.type == Type.VIRTUAL_DISPLAY_PLATFORM_VIEW) {
      return;
    }
    this.mEditable.removeEditingStateListener(this.plugin);
    this.configuration = null;
    this.inputTarget = new InputTarget(Type.NO_TARGET, 0);
  }
}

enum Type {
  NO_TARGET,
  // InputConnection is managed by the TextInputPlugin, and events are forwarded to the Flutter
  // framework.
  FRAMEWORK_CLIENT,
  // InputConnection is managed by a platform view that is presented on a virtual display.
  VIRTUAL_DISPLAY_PLATFORM_VIEW,
  PHYSICAL_DISPLAY_PLATFORM_VIEW,
}

enum KeyboardStatus {
  NONE = 0,
  HIDE = 1,
  SHOW = 2,
}


export class InputTarget {
  type: Type;
  id: number;

  constructor(type: Type, id: number) {
    this.type = type;
    this.id = id;
  }
}