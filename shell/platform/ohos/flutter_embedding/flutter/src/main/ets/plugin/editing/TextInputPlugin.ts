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

import TextInputChannel, { Configuration, TextEditState,
  TextInputType } from '../../embedding/engine/systemchannels/TextInputChannel';
import inputMethod from '@ohos.inputMethod';
import Log from '../../util/Log';
import { EditingStateWatcher, ListenableEditingState } from './ListenableEditingState';
import { TextEditingDelta } from './TextEditingDelta';

export default class TextInputPlugin implements EditingStateWatcher{
  private static TAG = "TextInputPlugin";
  private textInputChannel: TextInputChannel;
  private textConfig: inputMethod.TextConfig;
  private inputMethodController: inputMethod.InputMethodController;
  private inputTarget: InputTarget;
  private configuration: Configuration;
  //TODO:private autofillConfiguration:
  private mEditable: ListenableEditingState;
  private mRestartInputPending: boolean;

  private imcFlag: boolean = false;



  constructor(textInputChannel: TextInputChannel) {
    this.textInputChannel = textInputChannel;
    this.mEditable = new ListenableEditingState();
    this.textConfig = {
      inputAttribute: {
        textInputType: 0,
        enterKeyType: 1
      }};
    this.inputMethodController = inputMethod.getController();
    this.textInputChannel.setTextInputMethodHandler({
      show:(): void => {
        this.showTextInput();
      },

      hide:(): void => {
        this.hideTextInput();
      },

      requestAutofill:(): void =>{

      },

      finishAutofillContext:(shouldSave: boolean): void =>{

      },

      setClient:(textInputClientId: number, configuration: Configuration): void => {
        Log.d(TextInputPlugin.TAG,"textInputClientId: " + textInputClientId);
        this.setTextInputClient(textInputClientId, configuration);
      },

      setPlatformViewClient:(id: number, usesVirtualDisplay: boolean): void => {

      },

      setEditableSizeAndTransform:(width: number, height: number, transform: number[]): void => {

      },

      setEditingState:(editingState: TextEditState): void => {
        Log.d(TextInputPlugin.TAG, "text:" + editingState.text +" selectionStart:" + editingState.selectionStart + " selectionEnd:"
          + editingState.selectionEnd + " composingStart:" + editingState.composingStart + " composingEnd" + editingState.composingEnd);
        this.mEditable.updateTextInputState(editingState);
      },
      clearClient:(): void =>{
        this.clearTextInputClient();
    }


    });
  }

  private async showTextInput(): Promise<void> {
    await this.attach(true);
    if(this.imcFlag != true) {
      this.listenKeyBoardEvent();
    }
    this.inputMethodController.showSoftKeyboard().then(()=> {
      Log.d(TextInputPlugin.TAG, "Succeeded in showing softKeyboard");
    }).catch((err) => {
      Log.e(TextInputPlugin.TAG, "Failed to show softKeyboard:" + JSON.stringify(err));
    });
  }

  private async hideTextInput(): Promise<void> {
    this.inputMethodController.hideSoftKeyboard().then(() => {
      Log.d(TextInputPlugin.TAG, "Succeeded in hide softKeyboard");
    }).catch((err) => {
      Log.e(TextInputPlugin.TAG, "Failed to hide softKeyboard:" + JSON.stringify(err));
    })
  }

  async attach(showKeyboard: boolean): Promise<void>  {
    try {
      await this.inputMethodController.attach(showKeyboard, this.textConfig);
    } catch (err) {
      Log.e(TextInputPlugin.TAG, "Failed to attach:" + JSON.stringify(err));
    }
  }

  listenKeyBoardEvent(): void {
    try {
      this.inputMethodController.on('insertText', (text) => {
        Log.d(TextInputPlugin.TAG, "insertText: " + text);
        this.mEditable.handleInsertTextEvent(text);
      });
    } catch (err) {
      Log.e(TextInputPlugin.TAG, "Failed to subscribe insertText:" + JSON.stringify(err));
      this.cancelListenKeyBoardEvent();
      return;
    }

    try {
      this.inputMethodController.on('deleteLeft', (length) => {
        this.mEditable.handleDeleteEvent(false, length);
      })
    } catch (err) {
      Log.e(TextInputPlugin.TAG, "Failed to subscribe deleteLeft:" + JSON.stringify(err));
      this.cancelListenKeyBoardEvent();
      return;
    }

    try {
      this.inputMethodController.on('deleteRight', (length) => {
        this.mEditable.handleDeleteEvent(true, length);
      })
    } catch (err) {
      Log.e(TextInputPlugin.TAG, "Failed to subscribe deleteRight:" + JSON.stringify(err));
      this.cancelListenKeyBoardEvent();
      return;
    }

    try {
      this.inputMethodController.on('sendFunctionKey', (functionKey) => {
        this.mEditable.handleFunctionKey(functionKey);
      })
    } catch (err) {
      Log.e(TextInputPlugin.TAG, "Failed to subscribe sendFunctionKey:" + JSON.stringify(err));
      this.cancelListenKeyBoardEvent();
      return;
    }

    try {
      this.inputMethodController.on('selectByRange', (range) => {
        this.mEditable.handleSelectByRange(range);
      })
    } catch (err) {
      Log.e(TextInputPlugin.TAG, "Failed to subscribe selectByRange:" + JSON.stringify(err));
      this.cancelListenKeyBoardEvent();
      return;
    }
    Log.d(TextInputPlugin.TAG, "listenKeyBoardEvent success");
    this.imcFlag = true;
  }

  cancelListenKeyBoardEvent(): void {
    this.inputMethodController.off('insertText');
    this.inputMethodController.off('deleteLeft');
    this.inputMethodController.off('deleteRight');
    this.inputMethodController.off('sendFunctionKey');
    this.inputMethodController.off('selectByRange');
  }

  setTextInputClient(client: number, configuration: Configuration): void {
    this.configuration = configuration;
    if(this.canShowTextInput()) {
      this.inputTarget = new InputTarget(Type.FRAMEWORK_CLIENT, client);
    } else {
      this.inputTarget = new InputTarget(Type.NO_TARGET, client);
    }
    this.mEditable.removeEditingStateListener(this);
    this.mEditable = new ListenableEditingState();

    this.mRestartInputPending = true;
    this.mEditable.addEditingStateListener(this);
  }

  canShowTextInput(): boolean {
    if(this.configuration == null || this.configuration.inputType == null) {
      return true;
    }
    return this.configuration.inputType.type != TextInputType.NONE;
  }

  setTextInputEditingState(state: TextEditState) {

  }

  didChangeEditingState(textChanged: boolean, selectionChanged: boolean, composingRegionChanged: boolean): void {
    this.textInputChannel.updateEditingState(this.inputTarget.id, this.mEditable.getStringCache(),
      this.mEditable.getSelectionStart(), this.mEditable.getSelectionEnd(),
      this.mEditable.getComposingStart(), this.mEditable.getComposingEnd())
  }

  detach(): void {
    this.inputMethodController.detach((err) => {
      if(err) {
        Log.e(TextInputPlugin.TAG, "Failed to detach: " + JSON.stringify(err));
      }
    })
  }

  clearTextInputClient(): void {
    if(this.inputTarget.type == Type.VIRTUAL_DISPLAY_PLATFORM_VIEW) {
      return;
    }
    this.mEditable.removeEditingStateListener(this);
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

export class InputTarget {
  type: Type;
  id: number;

  constructor(type: Type, id: number) {
    this.type = type;
    this.id = id;
  }

}