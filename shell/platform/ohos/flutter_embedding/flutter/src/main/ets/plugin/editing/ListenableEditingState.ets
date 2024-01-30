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

const TAG = "ListenableEditingState";

export class ListenableEditingState {
  private TextInputChannel: TextInputChannel | null = null;
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


  constructor(TextInputChannel:TextInputChannel | null,client:number) {
    this.TextInputChannel = TextInputChannel;
    this.client = client
    this.mStringCache = "";
    this.mTextWhenBeginBatchEdit = "";
    this.mSelectionStartCache = 0;
    this.mSelectionEndCache = 0;
    this.mComposingStartCache = -1;
    this.mComposingEndCache = -1;
  }

  extractBatchTextEditingDeltas(): ArrayList<TextEditingDelta> {
    let currentBatchDeltas = new ArrayList<TextEditingDelta>();
    this.mBatchTextEditingDeltas.forEach((data) => {
      currentBatchDeltas.add(data);
    })
    this.mBatchTextEditingDeltas.clear();
    return currentBatchDeltas;
  }

  clearBatchDeltas(): void {
    this.mBatchTextEditingDeltas.clear();
  }

  replace(start: number, end: number, tb: String, tbStart: number, tbEnd: number): void {
    const placeIndex = this.mSelectionStartCache < this.mSelectionEndCache ? this.mSelectionStartCache : this.mSelectionEndCache;

    this.mBatchTextEditingDeltas.add(
      new TextEditingDelta(
        this.mStringCache.toString(),
        placeIndex + tbEnd,
        placeIndex + tbEnd,
        this.getComposingStart(),
        this.getComposingEnd(),
        start,
        end + tbStart,
        tb.toString()
      ));
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
    let start = this.mSelectionStartCache < this.mSelectionEndCache ? this.mSelectionStartCache : this.mSelectionEndCache;
    let end = this.mSelectionStartCache > this.mSelectionEndCache ? this.mSelectionStartCache : this.mSelectionEndCache;
    const length = text.length;
    this.replace(start, end, text, 0, length);

    if (this.mStringCache.length == this.mSelectionStartCache) {
      //Insert text one by one
      let tempStr: string = this.mStringCache.substring(0, start) + text + this.mStringCache.substring(end);
      this.mStringCache = tempStr;
      this.setSelectionStart(this.mStringCache.length);
      this.setSelectionEnd(this.mStringCache.length);

    } else if (this.mStringCache.length > this.mSelectionStartCache) {
      //Insert text in the middle of string
      let tempStr: string = this.mStringCache.substring(0, start) + text + this.mStringCache.substring(end);
      this.mStringCache = tempStr;
      this.mSelectionStartCache = start + text.length;
      this.mSelectionEndCache = this.mSelectionStartCache;
    }
    if (this.mListeners == null) {
      Log.e(TAG, "mListeners is null");
      return;
    }
    this.notifyListenersIfNeeded(true, true, false);
  }

  updateTextInputState(state: TextEditState): void {
    this.beginBatchEdit();
    this.setStringCache(state.text);
    if (state.hasSelection()) {
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
    let start = this.mSelectionStartCache < this.mSelectionEndCache ? this.mSelectionStartCache : this.mSelectionEndCache;
    let end = this.mSelectionStartCache > this.mSelectionEndCache ? this.mSelectionStartCache : this.mSelectionEndCache;

    if (leftOrRight == false) {
      //delete left
      if (start == 0 && end == 0) {
        return;
      }
      const startData = start == end ? start - 1 : start;
      const tbEnd = start == end ? -1 : 0;
      this.replace(startData, end, "", 0, tbEnd);
      this.mSelectionStartCache = startData;
      let tempStr: string = this.mStringCache.slice(0, startData) + this.mStringCache.slice(end);
      this.mStringCache = tempStr;
      this.mSelectionEndCache = this.mSelectionStartCache;
    } else if (leftOrRight == true) {
      //delete right
      if (start == this.mStringCache.length) {
        return;
      }
      const tbStart = start == end ? 1 : 0;
      this.replace(start, end, "", tbStart, 0);
      this.mSelectionEndCache = start;
      let tempStr: string = this.mStringCache.slice(0, start) + (end + 1 >= this.mStringCache.length ? "" : this.mStringCache.slice(end + 1));
      this.mStringCache = tempStr;
      this.mSelectionStartCache = this.mSelectionEndCache;
    }
    this.notifyListenersIfNeeded(true, true, false);
  }

  handleFunctionKey(functionKey: inputMethod.FunctionKey): void {
    if(!this.TextInputChannel)
    {
      return
    }
    switch (functionKey.enterKeyType) {
      case inputMethod.EnterKeyType.PREVIOUS:
        this.TextInputChannel.previous(this.client);
        break;
      case inputMethod.EnterKeyType.UNSPECIFIED:
        this.TextInputChannel.unspecifiedAction(this.client);
        break;
      case inputMethod.EnterKeyType.NONE:
        this.TextInputChannel.newline(this.client);
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
        this.TextInputChannel.done(this.client);
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
  didChangeEditingState(textChanged: boolean, selectionChanged: boolean, composingRegionChanged: boolean): void;
}