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

import Log from '../../util/Log';

export class TextEditingDelta {
  private static TAG = "TextEditingDelta";
  private oldText: string;
  private deltaText: string;
  private deltaStart: number;
  private deltaEnd: number;
  private newSelectionStart: number;
  private newSelectionEnd: number;
  private newComposingStart: number;
  private newComposingEnd: number;

  constructor(oldEditable: string,
              selectionStart: number,
              selectionEnd: number,
              composingStart: number,
              composingEnd: number,
              replacementDestinationStart?: number,
              replacementDestinationEnd?: number,
              replacementSource?: string,) {
    this.newSelectionStart = selectionStart;
    this.newSelectionEnd = selectionEnd;
    this.newComposingStart = composingStart;
    this.newComposingEnd = composingEnd;
    if(replacementDestinationStart === undefined ||
      replacementDestinationEnd === undefined ||
      replacementSource === undefined) {
      this.setDeltas(oldEditable, "", -1, -1);
    } else  {
      this.setDeltas(
        oldEditable,
        replacementSource,
        replacementDestinationStart,
        replacementDestinationEnd);
    }

  }

  setDeltas(oldText: string, newText: string, newStart: number, newExtent: number): void {
    this.oldText = oldText;
    this.deltaText = newText;
    this.deltaStart = newStart;
    this.deltaEnd = newExtent;
  }

  toJSON(): any {
    let delta;
    try {
      delta.oldText = this.oldText;
      delta.deltaText = this.deltaText;
      delta.deltaStart = this.deltaStart;
      delta.deltaEnd = this.deltaEnd;
      delta.selectionBase = this.newSelectionStart;
      delta.selectionExtent = this.newSelectionEnd;
      delta.composingBase = this.newComposingStart;
      delta.composingExtent = this.newComposingEnd;
    } catch (err) {
      Log.e(TextEditingDelta.TAG,"unable to create JSONObject: " + JSON.stringify(err));
    }


  }
}
