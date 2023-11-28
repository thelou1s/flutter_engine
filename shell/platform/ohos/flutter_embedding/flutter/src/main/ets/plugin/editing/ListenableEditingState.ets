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

import { TextEditState } from '../../embedding/engine/systemchannels/TextInputChannel';
import Log from '../../util/Log';
import inputMethod from '@ohos.inputMethod';
import ArrayList from '@ohos.util.ArrayList';
import { TextEditingDelta } from './TextEditingDelta';
import TextInputChannel from '../../embedding/engine/systemchannels/TextInputChannel';
const TAG =  "ListenableEditingState";
export class ListenableEditingState {

  private TextInputChannel: TextInputChannel|null = null ;
  private client: number = 0
  //Cache used to storage software keyboard input action
  private mStringCache: string;
  private mSelectionStartCache: number = 0;
  private mSelectionEndCache: number = 0;
  private mComposingStartCache: number = 0;
  private mComposingEndCache: number = 0;
  //used to compare with Cache

  private mListeners: ArrayList<EditingStateWatcher> = new ArrayList<EditingStateWatcher>();
  private mPendingListeners: ArrayList<EditingStateWatcher> = new ArrayList<EditingStateWatcher>();
  private  mBatchTextEditingDeltas: ArrayList<TextEditingDelta> = new ArrayList<TextEditingDelta>();
  private mChangeNotificationDepth: number = 0;
  private mBatchEditNestDepth: number = 0;

  private mTextWhenBeginBatchEdit: string;
  private mSelectionStartWhenBeginBatchEdit: number = 0;
  private mSelectionEndWhenBeginBatchEdit: number = 0;
  private mComposingStartWhenBeginBatchEdit: number = 0;
  private mComposingEndWhenBeginBatchEdit: number = 0;


  constructor(TextInputChannel:TextInputChannel,client:number) {
    this.TextInputChannel = TextInputChannel;
    this.client = client
    this.mStringCache = "";
    this.mTextWhenBeginBatchEdit = "";
    this.mSelectionStartCache = 0;
    this.mSelectionEndCache = 0;
    this.mComposingStartCache = -1;
    this.mComposingEndCache = -1;
  }


  getSelectionStart(): number {
    return this.mSelectionStartCache;
  }

  getSelectionEnd(): number {
    return this.mSelectionEndCache;
  }

  getComposingStart(): number {
    return this.mComposingStartCache;
  }

  getComposingEnd(): number {
    return this.mComposingEndCache;
  }

  getStringCache(): string {
    return this.mStringCache;
  }

  setSelectionStart(newSelectionStart: number): void {
    this.mSelectionStartCache = newSelectionStart;
  }

  setSelectionEnd(newSelectionEnd: number): void {
    this.mSelectionEndCache = newSelectionEnd;
  }

  setComposingStart(newComposingStart: number): void {
    this.mComposingStartCache = newComposingStart;
  }

  setComposingEnd(newComposingEnd: number): void {
    this.mComposingEndCache = newComposingEnd;
  }

  setStringCache(newStringCache: string): void {
    this.mStringCache = newStringCache;
  }

  notifyListener(listener: EditingStateWatcher,
                 textChanged: boolean,
                 selectionChanged: boolean,
                 composingChanged: boolean): void {
    this.mChangeNotificationDepth++;
    listener.didChangeEditingState(textChanged, selectionChanged, composingChanged);
    this.mChangeNotificationDepth--;
  }

  notifyListenersIfNeeded(textChanged: boolean, selectionChanged: boolean, composingChanged: boolean) {
    if (textChanged || selectionChanged || composingChanged) {
      for(const listener of this.mListeners) {
        this.notifyListener(listener, textChanged, selectionChanged, composingChanged);
      }

    }
  }

  handleInsertTextEvent(text: string): void {
    if(this.mStringCache.length == this.mSelectionStartCache) {
      //Insert text one by one
      this.mStringCache += text;
      this.setSelectionStart(this.mStringCache.length);
      this.setSelectionEnd(this.mStringCache.length);

    } else if(this.mStringCache.length > this.mSelectionStartCache) {
      //Insert text in the middle of string
      let tempStr: string = this.mStringCache.substring(0, this.mSelectionStartCache) + text + this.mStringCache.substring(this.mSelectionStartCache);
      this.mStringCache = tempStr;
      this.mSelectionStartCache += text.length;
      this.mSelectionEndCache = this.mSelectionStartCache;
    }
    if(this.mListeners == null) {
      Log.e(TAG, "mListeners is null");
      return;
    }
    this.notifyListenersIfNeeded(true, true, false);
  }

  updateTextInputState(state: TextEditState): void {
    this.beginBatchEdit();
    this.setStringCache(state.text);
    if(state.hasSelection()) {
      this.setSelectionStart(state.selectionStart);
      this.setSelectionEnd(state.selectionEnd);
    } else {
      this.setSelectionStart(0);
      this.setSelectionEnd(0);
    }
    this.endBatchEdit();
  }

  beginBatchEdit(): void {
    this.mBatchEditNestDepth++;
    if(this.mChangeNotificationDepth > 0) {
      Log.e(TAG, "editing state should not be changed in a listener callback");
    }
    if(this.mBatchEditNestDepth == 1 && !this.mListeners.isEmpty()) {
      this.mTextWhenBeginBatchEdit = this.getStringCache();
      this.mSelectionStartWhenBeginBatchEdit = this.getSelectionStart();
      this.mSelectionEndWhenBeginBatchEdit = this.getSelectionEnd();
      this.mComposingStartWhenBeginBatchEdit = this.getComposingStart();
      this.mComposingEndWhenBeginBatchEdit = this.getComposingEnd();
    }
  }

  endBatchEdit(): void {
    if (this.mBatchEditNestDepth == 0) {
      Log.e(TAG, "endBatchEdit called without a matching beginBatchEdit");
      return;
    }
    if(this.mBatchEditNestDepth == 1) {
      Log.d(TAG,"mBatchEditNestDepth == 1");
      for(const listener of this.mPendingListeners) {
        this.notifyListener(listener, true, true, true);
      }

      if(!this.mListeners.isEmpty()) {
        Log.d(TAG, "didFinishBatchEdit with " + this.mListeners.length + " listener(s)");
        const textChanged = !(this.mStringCache == this.mTextWhenBeginBatchEdit);
        const selectionChanged = this.mSelectionStartWhenBeginBatchEdit != this.getSelectionStart()
          || this.mSelectionEndWhenBeginBatchEdit != this.getSelectionEnd();
        const composingRegionChanged = this.mComposingStartWhenBeginBatchEdit != this.getComposingStart()
          || this.mComposingEndWhenBeginBatchEdit != this.getComposingEnd();
        Log.d(TAG,"textChanged: " + textChanged + " selectionChanged: " + selectionChanged +
          " composingRegionChanged: " + composingRegionChanged);
        this.notifyListenersIfNeeded(textChanged, selectionChanged, composingRegionChanged);
      }
    }
    for(const listener of this.mPendingListeners) {
      this.mListeners.add(listener);
    }
    this.mPendingListeners.clear();
    this.mBatchEditNestDepth--;

  }

  addEditingStateListener(listener: EditingStateWatcher): void {
    if(this.mChangeNotificationDepth > 0) {
      Log.e(TAG, "adding a listener " + JSON.stringify(listener) + " in a listener callback");
    }
    if(this.mBatchEditNestDepth > 0) {
      Log.d(TAG, "a listener was added to EditingState while a batch edit was in progress");
      this.mPendingListeners.add(listener);
    } else {
      this.mListeners.add(listener);
    }
  }

  removeEditingStateListener(listener: EditingStateWatcher): void {
    if(this.mChangeNotificationDepth > 0) {
      Log.e(TAG, "removing a listener " + JSON.stringify(listener) + " in a listener callback");
    }
    this.mListeners.remove(listener);
    if(this.mBatchEditNestDepth > 0) {
      this.mPendingListeners.remove(listener);
    }
  }

  handleDeleteEvent(leftOrRight: boolean, length: number): void {
    if(leftOrRight == false) {
      //delete left
      if(this.mSelectionStartCache  == 0) {
        return;
      }
      this.mSelectionStartCache -= length;
      let tempStr: string = this.mStringCache.slice(0, this.mSelectionStartCache) + this.mStringCache.slice(this.mSelectionStartCache + length);
      this.mStringCache = tempStr;
      this.mSelectionEndCache = this.mSelectionStartCache;
    } else if(leftOrRight == true) {
      //delete right
      if(this.mSelectionStartCache == this.mStringCache.length) {
        return;
      }
      this.mSelectionEndCache += length;
      let tempStr: string = this.mStringCache.slice(0,this.mSelectionStartCache) + this.mStringCache.slice(this.mSelectionEndCache);
      this.mStringCache = tempStr;
      this.mSelectionStartCache = this.mSelectionEndCache;
    }
    this.notifyListenersIfNeeded(true, true, false);
  }

  handleFunctionKey(functionKey: inputMethod.FunctionKey): void {
    switch (functionKey.enterKeyType) {
      case inputMethod.EnterKeyType.PREVIOUS:
        this.TextInputChannel.previous(this.client);
        break;
      case inputMethod.EnterKeyType.UNSPECIFIED:
        this.TextInputChannel.unspecifiedAction(this.client);
        break;
      case inputMethod.EnterKeyType.NONE:
        this.TextInputChannel.done(this.client)
        break;
      case inputMethod.EnterKeyType.GO:
        this.TextInputChannel.go(this.client);
        break;
      case inputMethod.EnterKeyType.SEARCH:
        this.TextInputChannel.search(this.client);
        break;
      case inputMethod.EnterKeyType.SEND:
        this.TextInputChannel.send(this.client);
        break;
      case inputMethod.EnterKeyType.NEXT:
        this.TextInputChannel.next(this.client);
        break;
      case inputMethod.EnterKeyType.DONE:
        this.TextInputChannel.done(this.client)
        break;
    }
  }

  handleSelectByRange(range: inputMethod.Range): void {
    Log.d(TAG, "handleSelectByRange start: " + range.start +" end: " + range.end);
  }



}

export interface EditingStateWatcher {
  // Changing the editing state in a didChangeEditingState callback may cause unexpected
  // behavior.
  didChangeEditingState(textChanged: boolean, selectionChanged: boolean, composingRegionChanged: boolean);
}