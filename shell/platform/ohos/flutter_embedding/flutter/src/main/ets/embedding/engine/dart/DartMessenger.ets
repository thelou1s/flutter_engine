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

import Log from '../../../util/Log'
import { BinaryMessageHandler, BinaryMessenger, BinaryReply, TaskQueue, TaskQueueOptions } from '../../../plugin/common/BinaryMessenger';
import FlutterNapi from '../FlutterNapi';
import { PlatformMessageHandler } from './PlatformMessageHandler';
import { TraceSection } from '../../../util/TraceSection';

/**
 * Message conduit for 2-way communication between Android and Dart.
 *
 * <p>See {@link BinaryMessenger}, which sends messages from Android to Dart
 *
 * <p>See {@link PlatformMessageHandler}, which handles messages to Android from Dart
 */

const TAG = "DartMessenger";

export class DartMessenger implements BinaryMessenger, PlatformMessageHandler {

  flutterNapi: FlutterNapi;

  /**
   * Maps a channel name to an object that contains the task queue and the handler associated with
   * the channel.
   *
   * <p>Reads and writes to this map must lock {@code handlersLock}.
   */
  messageHandlers: Map<String, HandlerInfo> = new Map();

  /**
   * Maps a channel name to an object that holds information about the incoming Dart message.
   *
   * <p>Reads and writes to this map must lock {@code handlersLock}.
   */
  bufferedMessages: Map<String, BufferedMessageInfo[]> = new Map();

  handlersLock: Object = new Object();
  enableBufferingIncomingMessagesFlag: boolean = false;

  pendingReplies: Map<number, BinaryReply> = new Map();
  nextReplyId: number = 1;
  taskQueueFactory: TaskQueueFactory;
  createdTaskQueues: Map<TaskQueue, DartMessengerTaskQueue> = new Map();

  constructor(flutterNapi: FlutterNapi) {
    this.flutterNapi = flutterNapi;
    this.taskQueueFactory = new DefaultTaskQueueFactory();
  }
  makeBackgroundTaskQueue(options: TaskQueueOptions): TaskQueue {
    let taskQueue: DartMessengerTaskQueue = this.taskQueueFactory.makeBackgroundTaskQueue(options);
    let token: TaskQueueToken = new TaskQueueToken();
    this.createdTaskQueues.set(token, taskQueue);
    return token;
  }


  setMessageHandler(channel: String, handler: BinaryMessageHandler | null, taskQueue?: TaskQueue): void {
    if (handler == null) {
      Log.d(TAG, "Removing handler for channel '" + channel + "'");
      this.messageHandlers.delete(channel);
      return;
    }
    let dartMessengerTaskQueue: DartMessengerTaskQueue | null = null;
    if( taskQueue != null) {
      dartMessengerTaskQueue = this.createdTaskQueues.get(taskQueue) ?? null;
      if(dartMessengerTaskQueue == null) {
        throw new Error(
            "Unrecognized TaskQueue, use BinaryMessenger to create your TaskQueue (ex makeBackgroundTaskQueue)."
          );
      }
    }
    Log.d(TAG, "Setting handler for channel '" + channel + "'");

    this.messageHandlers.set(channel, new HandlerInfo(handler, dartMessengerTaskQueue));
    this.bufferedMessages.delete(channel);
  }


  enableBufferingIncomingMessages(): void {
    this.enableBufferingIncomingMessagesFlag = true;
  }

  disableBufferingIncomingMessages(): void {
    this.enableBufferingIncomingMessagesFlag = false;
    this.bufferedMessages = new Map();
  }

  send(channel: String, message: ArrayBuffer, callback?: BinaryReply): void {
    Log.d(TAG, "Sending message over channel '" + channel + "'");
    TraceSection.begin("DartMessenger#send on " + channel);
    try {
      Log.d(TAG, "Sending message with callback over channel '" + channel + "'");
      let replyId: number = this.nextReplyId++;
      if (callback != null) {
        this.pendingReplies.set(replyId, callback);
      }
      if (message == null) {
        this.flutterNapi.dispatchEmptyPlatformMessage(channel, replyId);
      } else {
        this.flutterNapi.dispatchPlatformMessage(channel, message, message.byteLength, replyId);
      }
    } finally {
      TraceSection.end("DartMessenger#send on " + channel);
    }
  }

  async asyncInvokeHandler(handlerInfo: HandlerInfo | null, message: ArrayBuffer, replyId: number): Promise<void> {
    // Called from any thread.
    if (handlerInfo != null) {
      try {
        Log.d(TAG, "Deferring to registered handler to process message.");
        handlerInfo.handler.onMessage(message, new Reply(this.flutterNapi, replyId));
      } catch (ex) {
        Log.e(TAG, "Uncaught exception in binary message listener", ex);
        this.flutterNapi.invokePlatformMessageEmptyResponseCallback(replyId);
      }
    } else {
      Log.d(TAG, "No registered handler for message. Responding to Dart with empty reply message.");
      this.flutterNapi.invokePlatformMessageEmptyResponseCallback(replyId);
    }
  }

  invokeHandler(handlerInfo: HandlerInfo | null, message: ArrayBuffer, replyId: number): void {
    // Called from any thread.
    if (handlerInfo != null) {
      try {
        Log.d(TAG, "Deferring to registered handler to process message.");
        handlerInfo.handler.onMessage(message, new Reply(this.flutterNapi, replyId));
      } catch (ex) {
        Log.e(TAG, "Uncaught exception in binary message listener", ex);
        this.flutterNapi.invokePlatformMessageEmptyResponseCallback(replyId);
      }
    } else {
      Log.d(TAG, "No registered handler for message. Responding to Dart with empty reply message.");
      this.flutterNapi.invokePlatformMessageEmptyResponseCallback(replyId);
    }
  }

  handleMessageFromDart(channel: String, message: ArrayBuffer, replyId: number, messageData: number): void {
      // Called from any thread.
      Log.d(TAG, "Received message from Dart over channel '" + channel + "'");

      let handlerInfo: HandlerInfo | null  = this.messageHandlers.get(channel) ?? null;
      let messageDeferred: boolean;

      messageDeferred = (this.enableBufferingIncomingMessagesFlag && handlerInfo == null);
      if (messageDeferred) {
        if (!this.bufferedMessages.has(channel)) {
          this.bufferedMessages.set(channel, []);
        }
      let buffer: BufferedMessageInfo[] = this.bufferedMessages.get(channel) ?? [];
      buffer.push(new BufferedMessageInfo(message, replyId, messageData));
    }
    if (!messageDeferred) {
      //ArkTS 没有线程池,任务队列使用异步实现
      if(handlerInfo?.taskQueue != null) {
          this.asyncInvokeHandler(handlerInfo, message, replyId);
        } else {
          this.invokeHandler(handlerInfo, message, replyId);  
      }
    }
  }

  handlePlatformMessageResponse(replyId: number, reply: ArrayBuffer): void {
    Log.d(TAG, "Received message reply from Dart.");
    let callback: BinaryReply | null = this.pendingReplies.get(replyId) ?? null;
    this.pendingReplies.delete(replyId);
    if (callback != null) {
      try {
        Log.d(TAG, "Invoking registered callback for reply from Dart.");
        callback.reply(reply);
      } catch (e) {
        Log.e(TAG, "Uncaught exception in binary message reply handler", e);
      }
    }
  }

  /**
   * Returns the number of pending channel callback replies.
   *
   * <p>When sending messages to the Flutter application using {@link BinaryMessenger#send(String,
   * ByteBuffer, io.flutter.plugin.common.BinaryMessenger.BinaryReply)}, developers can optionally
   * specify a reply callback if they expect a reply from the Flutter application.
   *
   * <p>This method tracks all the pending callbacks that are waiting for response, and is supposed
   * to be called from the main thread (as other methods). Calling from a different thread could
   * possibly capture an indeterministic internal state, so don't do it.
   */
  getPendingChannelResponseCount(): number {
    return this.pendingReplies.size;
  }
}






/**
 * Holds information about a platform handler, such as the task queue that processes messages from
 * Dart.
 */
class HandlerInfo {
  handler: BinaryMessageHandler;
  taskQueue: DartMessengerTaskQueue | null;
  constructor(handler: BinaryMessageHandler, taskQueue?:DartMessengerTaskQueue | null) {
    this.handler = handler;
    this.taskQueue = taskQueue ?? null;
  }
}

/**
 * Holds information that allows to dispatch a Dart message to a platform handler when it becomes
 * available.
 */
class BufferedMessageInfo {
  message: ArrayBuffer;
  replyId: number;
  messageData: number;

  constructor(message: ArrayBuffer,
  replyId: number,
  messageData: number) {
    this.message = message;
    this.replyId = replyId;
    this.messageData = messageData;
  }
}





class Reply implements BinaryReply {
  flutterNapi: FlutterNapi;
  replyId: number;
  done: boolean = false;

  constructor(flutterNapi: FlutterNapi, replyId: number) {
    this.flutterNapi = flutterNapi;
    this.replyId = replyId;
  }

  reply(reply: ArrayBuffer | null) {
    if (this.done) {
      throw new Error("Reply already submitted");
    }
    if (reply == null) {
      this.flutterNapi.invokePlatformMessageEmptyResponseCallback(this.replyId);
    } else {
      this.flutterNapi.invokePlatformMessageResponseCallback(this.replyId, reply, reply.byteLength);
    }
  }
}

interface DartMessengerTaskQueue {
  dispatch(): void;
}

interface TaskQueueFactory {
    makeBackgroundTaskQueue(options: TaskQueueOptions): DartMessengerTaskQueue;
}

class ConcurrentTaskQueue implements DartMessengerTaskQueue {
    dispatch(): void {}
}

class DefaultTaskQueueFactory implements TaskQueueFactory {
    makeBackgroundTaskQueue(options: TaskQueueOptions): DartMessengerTaskQueue {
        return new ConcurrentTaskQueue();
    }
}

class TaskQueueToken implements TaskQueue {}