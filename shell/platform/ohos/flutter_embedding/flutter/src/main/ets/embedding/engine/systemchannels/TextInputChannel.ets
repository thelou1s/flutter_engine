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

import JSONMethodCodec from '../../../plugin/common/JSONMethodCodec';
import MethodCall from '../../../plugin/common/MethodCall';
import MethodChannel, { MethodCallHandler, MethodResult } from '../../../plugin/common/MethodChannel';
import TextInputPlugin from '../../../plugin/editing/TextInputPlugin';
import Log from '../../../util/Log';
import DartExecutor from '../dart/DartExecutor';
import inputMethod from '@ohos.inputMethod';
import ArrayList from '@ohos.util.ArrayList';
import { TextEditingDelta, TextEditingDeltaJson } from '../../../plugin/editing/TextEditingDelta';

const TAG = "TextInputChannel";

export default class TextInputChannel {
  private static CHANNEL_NAME = "flutter/textinput";
  public channel: MethodChannel;
  textInputMethodHandler: TextInputMethodHandler | null = null;

  constructor(dartExecutor: DartExecutor) {
    this.channel = new MethodChannel(dartExecutor, TextInputChannel.CHANNEL_NAME, JSONMethodCodec.INSTANCE);
  }

  setTextInputMethodHandler(textInputMethodHandler: TextInputMethodHandler): void {
    this.textInputMethodHandler = textInputMethodHandler;
    this.channel.setMethodCallHandler(new TextInputCallback(this.textInputMethodHandler));
  }

  requestExistingInputState(): void {
    this.channel.invokeMethod("TextInputClient.requestExistingInputState", null);
  }

  createEditingStateJSON(text: string,
                         selectionStart: number,
                         selectionEnd: number,
                         composingStart: number,
                         composingEnd: number): EditingState {
    let state: EditingState = {
      text: text,
      selectionBase: selectionStart,
      selectionExtent: selectionEnd,
      composingBase: composingStart,
      composingExtent: composingEnd
    };
    return state;
  }

  createEditingDeltaJSON(batchDeltas: ArrayList<TextEditingDelta>): EditingDelta {
    let deltas: Array<TextEditingDeltaJson> = [];
    batchDeltas.forEach((val, idx, array) => {
      deltas.push(val.toJSON());
    })

    let state: EditingDelta = {
      deltas: deltas,
    };
    return state;
  }

  /**
   * Instructs Flutter to update its text input editing state to reflect the given configuration.
   */
  updateEditingState(inputClientId: number,
                     text: string,
                     selectionStart: number,
                     selectionEnd: number,
                     composingStart: number,
                     composingEnd: number): void {
    Log.d(TAG, "updateEditingState:"
      + "Text: " + text + " Selection start: " + selectionStart + " Selection end: "
      + selectionEnd + " Composing start: " + composingStart + " Composing end: " + composingEnd);
    const state: ESObject = this.createEditingStateJSON(text, selectionStart, selectionEnd, composingStart, composingEnd);
    this.channel.invokeMethod('TextInputClient.updateEditingState', [inputClientId, state]);
  }

  updateEditingStateWithDeltas(inputClientId: number, batchDeltas: ArrayList<TextEditingDelta>): void {
    Log.d(TAG, "updateEditingStateWithDeltas:" + "batchDeltas length: " + batchDeltas.length);
    const state: ESObject = this.createEditingDeltaJSON(batchDeltas);
    this.channel.invokeMethod('TextInputClient.updateEditingStateWithDeltas', [inputClientId, state]);
  }

  newline(inputClientId: number): void {
    Log.d(TAG, "Sending 'newline' message.");
    this.channel.invokeMethod("TextInputClient.performAction", [inputClientId, "TextInputAction.newline"]);
  }

  go(inputClientId: number): void {
    Log.d(TAG, "Sending 'go' message.");
    this.channel.invokeMethod("TextInputClient.performAction", [inputClientId, "TextInputAction.go"]);
  }

  search(inputClientId: number): void {
    Log.d(TAG, "Sending 'search' message.");
    this.channel.invokeMethod("TextInputClient.performAction", [inputClientId, "TextInputAction.search"]);
  }

  send(inputClientId: number): void {
    Log.d(TAG, "Sending 'send' message.");
    this.channel.invokeMethod("TextInputClient.performAction", [inputClientId, "TextInputAction.send"]);
  }

  done(inputClientId: number): void {
    Log.d(TAG, "Sending 'done' message.");
    this.channel.invokeMethod("TextInputClient.performAction", [inputClientId, "TextInputAction.done"]);
  }

  next(inputClientId: number): void {
    Log.d(TAG, "Sending 'next' message.");
    this.channel.invokeMethod("TextInputClient.performAction", [inputClientId, "TextInputAction.next"]);
  }

  previous(inputClientId: number): void {
    Log.d(TAG, "Sending 'previous' message.");
    this.channel.invokeMethod("TextInputClient.performAction", [inputClientId, "TextInputAction.previous"]);
  }

  unspecifiedAction(inputClientId: number): void {
    Log.d(TAG, "Sending 'unspecifiedAction' message.");
    this.channel.invokeMethod("TextInputClient.performAction", [inputClientId, "TextInputAction.unspecified"]);
  }

  commitContent(inputClientId: number): void {
    Log.d(TAG, "Sending 'commitContent' message.");
    this.channel.invokeMethod("TextInputClient.performAction", [inputClientId, "TextInputAction.commitContent"]);
  }

  onConnectionClosed(inputClientId: number): void {
    Log.d(TAG, "Sending 'onConnectionClosed' message.");
  }

  performPrivateCommand(inputClientId: number, action: string, data: ESObject) {

  }
}

interface EditingState {
  text: string;
  selectionBase: number;
  selectionExtent: number;
  composingBase: number;
  composingExtent: number;
}


interface EditingDelta {
  deltas: Array<TextEditingDeltaJson>;
}


export interface TextInputMethodHandler {
  show(): void;

  hide(): void;

  requestAutofill(): void;

  finishAutofillContext(shouldSave: boolean): void;

  setClient(textInputClientId: number, configuration: Configuration | null): void;

  setPlatformViewClient(id: number, usesVirtualDisplay: boolean): void;

  setEditableSizeAndTransform(width: number, height: number, transform: number[]): void;

  setEditingState(editingState: TextEditState): void;

  clearClient(): void;

}

export class Configuration {
  obscureText: boolean = false;
  autocorrect: boolean = false;
  autofill: boolean = false;
  enableSuggestions: boolean = false;
  enableIMEPersonalizedLearning: boolean = false;
  enableDeltaModel: boolean = false;
  textCapitalization: TextCapitalization | null = null;
  inputType: InputType | null = null;
  inputAction: Number = 0;
  actionLabel: String = "";
  contentCommitMimeTypes: String[] = [];
  fields: Configuration[] = [];

  constructor(obscureText: boolean,
              autocorrect: boolean,
              enableSuggestions: boolean,
              enableIMEPersonalizedLearning: boolean,
              enableDeltaModel: boolean,
              textCapitalization: TextCapitalization,
              inputType: InputType,
              inputAction: Number,
              actionLabel: String,
              autofill: boolean,
              contentListString: [],
              fields: Configuration[]
  ) {
    this.obscureText = obscureText;
    this.autocorrect = autocorrect;
    this.enableSuggestions = enableSuggestions;
    this.enableIMEPersonalizedLearning = enableIMEPersonalizedLearning;
    this.textCapitalization = textCapitalization
    this.enableDeltaModel = enableDeltaModel;
    this.inputType = inputType;
    this.inputAction = inputAction;
    this.actionLabel = actionLabel;
    this.autofill = autofill;
    this.contentCommitMimeTypes = contentListString;
    this.fields = fields

  }

  static getTextCapitalizationFromValue(encodedName: string): TextCapitalization {
    let textKeys = ["CHARACTERS", "WORDS", "SENTENCES", "NONE"];
    for (let textKey of textKeys) {
      if (TextCapitalization[textKey] === encodedName) {
        return textKey as TextCapitalization;
      }
    }
    throw new Error("No such TextCapitalization: " + encodedName);
  }

  private static inputActionFromTextInputAction(inputActionName: string): number {
    switch (inputActionName) {
      case "TextInputAction.previous":
        return inputMethod.EnterKeyType.PREVIOUS
      case "TextInputAction.unspecified":
        return inputMethod.EnterKeyType.UNSPECIFIED
      case "TextInputAction.none":
        return inputMethod.EnterKeyType.NONE
      case "TextInputAction.go":
        return inputMethod.EnterKeyType.GO
      case "TextInputAction.search":
        return inputMethod.EnterKeyType.SEARCH
      case "TextInputAction.send":
        return inputMethod.EnterKeyType.SEND
      case "TextInputAction.next":
        return inputMethod.EnterKeyType.NEXT
      default:
      // Present default key if bad input type is given.
        return inputMethod.EnterKeyType.UNSPECIFIED

    }
  }

  static fromJson(json: ESObject) {
    const inputActionName: string = json.inputAction;
    if (!inputActionName) {
      throw new Error("Configuration JSON missing 'inputAction' property.");
    }

    let fields: Array<ESObject> = new Array();
    if (json.fields !== null && json.fields !== undefined) {
      fields = json.fields.map((field: ESObject): ESObject => Configuration.fromJson(field));
    }

    const inputAction: number = Configuration.inputActionFromTextInputAction(inputActionName);

    // Build list of content commit mime types from the data in the JSON list.
    const contentList: Array<ESObject> = [];
    if (json.contentCommitMimeTypes !== null && json.contentCommitMimeTypes !== undefined) {
      json.contentCommitMimeTypes.forEach((type: ESObject) => {
        contentList.push(type);
      });
    }
    return new Configuration(
      json.obscureText ?? false,
      json.autocorrect ?? true,
      json.enableSuggestions ?? false,
      json.enableIMEPersonalizedLearning ?? false,
      json.enableDeltaModel ?? false,
      Configuration.getTextCapitalizationFromValue(json.textCapitalization),
      InputType.fromJson(json.inputType),
      inputAction,
      json.actionLabel ?? null,
      json.autofill ?? null,
      contentList as ESObject,
      fields
    );
  }
}

enum TextCapitalization {
  CHARACTERS = "TextCapitalization.characters",
  WORDS = "TextCapitalization.words",
  SENTENCES = "TextCapitalization.sentences",
  NONE = "TextCapitalization.none",
}

export enum TextInputType {
  TEXT = "TextInputType.text",
  DATETIME = "TextInputType.datetime",
  NAME = "TextInputType.name",
  POSTAL_ADDRESS = "TextInputType.address",
  NUMBER = "TextInputType.number",
  PHONE = "TextInputType.phone",
  MULTILINE = "TextInputType.multiline",
  EMAIL_ADDRESS = "TextInputType.emailAddress",
  URL = "TextInputType.url",
  VISIBLE_PASSWORD = "TextInputType.visiblePassword",
  NONE = "TextInputType.none",
}

export class InputType {
  type: TextInputType;
  isSigned: boolean;
  isDecimal: boolean;

  constructor(type: TextInputType, isSigned: boolean, isDecimal: boolean) {
    this.type = type;
    this.isSigned = isSigned;
    this.isDecimal = isDecimal;
  }

  static fromJson(json: ESObject): InputType {
    return new InputType(InputType.getTextInputTypeFromValue(json.name as string),
      json.signed as boolean, json.decimal as boolean)
  }

  static getTextInputTypeFromValue(encodedName: string): TextInputType {
    let textKeys = ["TEXT", "DATETIME", "NAME", "POSTAL_ADDRESS", "NUMBER", "PHONE", "MULTILINE", "EMAIL_ADDRESS", "URL", "VISIBLE_PASSWORD", "NONE",];
    for (let textKey of textKeys) {
      if (TextInputType[textKey] === encodedName) {
        return textKey as TextInputType;
      }
    }
    throw new Error("No such TextInputType: " + encodedName);
  }
}

export class TextEditState {
  private static TAG = "TextEditState";
  text: string;
  selectionStart: number;
  selectionEnd: number;
  composingStart: number;
  composingEnd: number;

  constructor(text: string,
              selectionStart: number,
              selectionEnd: number,
              composingStart: number,
              composingEnd: number) {
    if ((selectionStart != -1 || selectionEnd != -1)
      && (selectionStart < 0 || selectionEnd < 0)) {
      throw new Error("invalid selection: (" + selectionStart + ", " + selectionEnd + ")");
    }

    if ((composingStart != -1 || composingEnd != -1)
      && (composingStart < 0 || composingStart > composingEnd)) {
      throw new Error("invalid composing range: (" + composingStart + ", " + composingEnd + ")");
    }

    if (composingEnd > text.length) {
      throw new Error("invalid composing start: " + composingStart);
    }

    if (selectionStart > text.length) {
      throw new Error("invalid selection start: " + selectionStart);
    }

    if (selectionEnd > text.length) {
      throw new Error("invalid selection end: " + selectionEnd);
    }

    this.text = text;
    this.selectionStart = selectionStart;
    this.selectionEnd = selectionEnd;
    this.composingStart = composingStart;
    this.composingEnd = composingEnd;
  }

  hasSelection(): boolean {
    // When selectionStart == -1, it's guaranteed that selectionEnd will also
    // be -1.
    return this.selectionStart >= 0;
  }

  hasComposing(): boolean {
    return this.composingStart >= 0 && this.composingEnd > this.composingStart;
  }

  static fromJson(textEditState: ESObject): TextEditState {
    return new TextEditState(
      textEditState.text,
      textEditState.selectionBase,
      textEditState.selectionExtent,
      textEditState.composingBase,
      textEditState.composingExtent
    )
  }
}

class TextInputCallback implements MethodCallHandler {
  textInputMethodHandler: TextInputMethodHandler;

  constructor(handler: TextInputMethodHandler) {
    this.textInputMethodHandler = handler;
  }

  onMethodCall(call: MethodCall, result: MethodResult) {
    if (this.textInputMethodHandler == null) {
      return;
    }
    let method: string = call.method;
    let args: ESObject = call.args;
    Log.d(TAG, "Received '" + method + "' message.");
    switch (method) {
      case "TextInput.show":
        this.textInputMethodHandler.show();
        Log.d(TAG, "textInputMethodHandler.show()");
        result.success(null);
        break;
      case "TextInput.hide":
        this.textInputMethodHandler.hide();
        result.success(null);
        break;
      case "TextInput.setClient":
        const textInputClientId: number = args[0] as number;
        const jsonConfiguration: string = args[1];
        const config: Configuration | null = Configuration.fromJson(jsonConfiguration);

        this.textInputMethodHandler.setClient(textInputClientId, config);
        result.success(null);
        break;
      case "TextInput.requestAutofill":
      //TODO: requestAutofill
        result.notImplemented();
        break;
      case "TextInput.setPlatformViewClient":
      //TODO:
        result.notImplemented();
        break;
      case "TextInput.setEditingState":
        this.textInputMethodHandler.setEditingState(TextEditState.fromJson(args));
        result.success(null);
        break;
      case "TextInput.setEditableSizeAndTransform":
      //TODO:
        result.notImplemented();
        break;
      case "TextInput.clearClient":
        this.textInputMethodHandler.clearClient();
        result.success(null);
        break;
      case "TextInput.sendAppPrivateCommand":
      //TODO:
        result.notImplemented();
        break;
      case "TextInput.finishAutofillContext":
      //TODO:
        result.notImplemented();
        break;
      default:
        result.notImplemented();
        break;
    }
  }
}
