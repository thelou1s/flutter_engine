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

import resourceManager from '@ohos.resourceManager';
import FlutterInjector from '../../../FlutterInjector';
import { BinaryMessageHandler, BinaryReply, TaskQueue, TaskQueueOptions } from '../../../plugin/common/BinaryMessenger';
import { BinaryMessenger } from '../../../plugin/common/BinaryMessenger';
import StringCodec from '../../../plugin/common/StringCodec';
import Log from '../../../util/Log';
import { TraceSection } from '../../../util/TraceSection';
import { FlutterCallbackInformation } from '../../../view/FlutterCallbackInformation';
import FlutterNapi from '../FlutterNapi';
import { DartMessenger } from './DartMessenger';


const TAG = "DartExecutor";

/**
 * dart代码执行器
 */
export default class DartExecutor extends BinaryMessenger {
  flutterNapi: FlutterNapi;
  assetManager: resourceManager.ResourceManager;
  private dartMessenger: DartMessenger;
  private binaryMessenger: BinaryMessenger;
  private isApplicationRunning: boolean;
  private isolateServiceId: String = null;
  private isolateServiceIdListener: IsolateServiceIdListener = null;

  private isolateChannelMessageHandler: BinaryMessageHandler =
    new IsolateChannelMessageHandler(this.isolateServiceId, this.isolateServiceIdListener);

  constructor(flutterNapi: FlutterNapi, assetManager: resourceManager.ResourceManager) {
    super();
    this.flutterNapi = flutterNapi;
    this.assetManager = assetManager;
    this.dartMessenger = new DartMessenger(flutterNapi);
    this.dartMessenger.setMessageHandler("flutter/isolate", this.isolateChannelMessageHandler);
    this.binaryMessenger = new DefaultBinaryMessenger(this.dartMessenger);
    // The JNI might already be attached if coming from a spawned engine. If so, correctly report
    // that this DartExecutor is already running.
    if (flutterNapi.isAttached()) {
      this.isApplicationRunning = true;
    }
  }


  /**
   * Invoked when the {@link io.flutter.embedding.engine.FlutterEngine} that owns this {@link
   * DartExecutor} attaches to JNI.
   *
   * <p>When attached to JNI, this {@link DartExecutor} begins handling 2-way communication to/from
   * the Dart execution context. This communication is facilitate via 2 APIs:
   *
   * <ul>
   *   <li>{@link BinaryMessenger}, which sends messages to Dart
   *   <li>{@link PlatformMessageHandler}, which receives messages from Dart
   * </ul>
   */
  onAttachedToNAPI(): void {
    Log.d(TAG, "Attached to NAPI. Registering the platform message handler for this Dart execution context.");
    this.flutterNapi.setPlatformMessageHandler(this.dartMessenger);
  }

  /**
   * Invoked when the {@link io.flutter.embedding.engine.FlutterEngine} that owns this {@link
   * DartExecutor} detaches from JNI.
   *
   * <p>When detached from JNI, this {@link DartExecutor} stops handling 2-way communication to/from
   * the Dart execution context.
   */
  onDetachedFromNAPI(): void {
    Log.d(TAG, "Detached from NAPI. De-registering the platform message handler for this Dart execution context.");
    this.flutterNapi.setPlatformMessageHandler(null);
  }

  /**
   * Is this {@link DartExecutor} currently executing Dart code?
   *
   * @return true if Dart code is being executed, false otherwise
   */
  isExecutingDart(): boolean {
    return this.isApplicationRunning;
  }

  /**
   * Starts executing Dart code based on the given {@code dartEntrypoint} and the {@code
   * dartEntrypointArgs}.
   *
   * <p>See {@link DartEntrypoint} for configuration options.
   *
   * @param dartEntrypoint specifies which Dart function to run, and where to find it
   * @param dartEntrypointArgs Arguments passed as a list of string to Dart's entrypoint function.
   */
  executeDartEntrypoint(dartEntrypoint: DartEntrypoint, dartEntrypointArgs?: string[]): void {
    if (this.isApplicationRunning) {
      Log.w(TAG, "Attempted to run a DartExecutor that is already running.");
      return;
    }

    TraceSection.begin("DartExecutor#executeDartEntrypoint");
    try {
      Log.d(TAG, "Executing Dart entrypoint: " + dartEntrypoint);
      this.flutterNapi.runBundleAndSnapshotFromLibrary(
        dartEntrypoint.pathToBundle,
        dartEntrypoint.dartEntrypointFunctionName,
        dartEntrypoint.dartEntrypointLibrary,
        this.assetManager,
        dartEntrypointArgs);

      this.isApplicationRunning = true;
    } finally {
      TraceSection.end("DartExecutor#executeDartEntrypoint");
    }
  }

  /**
   * Starts executing Dart code based on the given {@code dartCallback}.
   *
   * <p>See {@link DartCallback} for configuration options.
   *
   * @param dartCallback specifies which Dart callback to run, and where to find it
   */
  executeDartCallback(dartCallback: DartCallback): void {
    if (this.isApplicationRunning) {
      Log.w(TAG, "Attempted to run a DartExecutor that is already running.");
      return;
    }

    TraceSection.begin("DartExecutor#executeDartCallback");
    try {
      Log.d(TAG, "Executing Dart callback: " + dartCallback);
      this.flutterNapi.runBundleAndSnapshotFromLibrary(
        dartCallback.pathToBundle,
        dartCallback.callbackHandle.callbackName,
        dartCallback.callbackHandle.callbackLibraryPath,
        dartCallback.resourceManager,
        null);

      this.isApplicationRunning = true;
    } finally {
      TraceSection.end("DartExecutor#executeDartCallback");
    }
  }

  /**
   * Returns a {@link BinaryMessenger} that can be used to send messages to, and receive messages
   * from, Dart code that this {@code DartExecutor} is executing.
   */

  getBinaryMessenger(): BinaryMessenger {
    return this.binaryMessenger;
  }

  makeBackgroundTaskQueue(options: TaskQueueOptions): TaskQueue {
    return this.getBinaryMessenger().makeBackgroundTaskQueue(options);
  }


  send(channel: String, message: ArrayBuffer, callback?: BinaryReply): void {
    this.getBinaryMessenger().send(channel, message, callback);
  }

  setMessageHandler(channel: String, handler: BinaryMessageHandler, taskQueue?: TaskQueue): void {
    this.getBinaryMessenger().setMessageHandler(channel, handler, taskQueue);
  }

  enableBufferingIncomingMessages(): void {
    this.getBinaryMessenger().enableBufferingIncomingMessages();
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
   *
   * <p>Currently, it's mainly useful for a testing framework like Espresso to determine whether all
   * the async channel callbacks are handled and the app is idle.
   */
  getPendingChannelResponseCount(): number {
    return this.dartMessenger.getPendingChannelResponseCount();
  }

  /**
   * Returns an identifier for this executor's primary isolate. This identifier can be used in
   * queries to the Dart service protocol.
   */

  getIsolateServiceId(): String {
    return this.isolateServiceId;
  }



  /**
   * Set a listener that will be notified when an isolate identifier is available for this
   * executor's primary isolate.
   */
  setIsolateServiceIdListener(listener: IsolateServiceIdListener): void {
    this.isolateServiceIdListener = listener;
    if (this.isolateServiceIdListener != null && this.isolateServiceId != null) {
      this.isolateServiceIdListener.onIsolateServiceIdAvailable(this.isolateServiceId);
    }
  }

  /**
   * Notify the Dart VM of a low memory event, or that the application is in a state such that now
   * is an appropriate time to free resources, such as going to the background.
   *
   * <p>This does not notify a Flutter application about memory pressure. For that, use the {@link
   * io.flutter.embedding.engine.systemchannels.SystemChannel#sendMemoryPressureWarning}.
   *
   * <p>Calling this method may cause jank or latency in the application. Avoid calling it during
   * critical periods like application startup or periods of animation.
   */
  notifyLowMemoryWarning(): void {
    if (this.flutterNapi.isAttached()) {
      this.flutterNapi.notifyLowMemoryWarning();
    }
  }

  disableBufferingIncomingMessages(): void {
    this.getBinaryMessenger().enableBufferingIncomingMessages();
  }
}


/**
 * Configuration options that specify which Dart entrypoint function is executed and where to find
 * that entrypoint and other assets required for Dart execution.
 */
export class DartEntrypoint {
  /** The path within the AssetManager where the app will look for assets. */
  pathToBundle: string;

  /** The library or file location that contains the Dart entrypoint function. */
  dartEntrypointLibrary: string;

  /** The name of a Dart function to execute. */
  dartEntrypointFunctionName: string;

  constructor(pathToBundle: string,
              dartEntrypointLibrary: string,
              dartEntrypointFunctionName: string) {
    this.pathToBundle = pathToBundle;
    this.dartEntrypointLibrary = dartEntrypointLibrary;
    this.dartEntrypointFunctionName = dartEntrypointFunctionName;
  }

  static createDefault() {
    const flutterLoader = FlutterInjector.getInstance().getFlutterLoader();
    if (!flutterLoader.initialized) {
      throw new Error(
        "DartEntrypoints can only be created once a FlutterEngine is created.");
    }
    return new DartEntrypoint(flutterLoader.findAppBundlePath(), null, "main");
  }
}


/** Callback interface invoked when the isolate identifier becomes available. */
interface IsolateServiceIdListener {
  onIsolateServiceIdAvailable(isolateServiceId: String): void;
}


/**
 * Configuration options that specify which Dart callback function is executed and where to find
 * that callback and other assets required for Dart execution.
 */
export class DartCallback {
  /** Standard Android AssetManager, provided from some {@code Context} or {@code Resources}. */
  public resourceManager: resourceManager.ResourceManager;

  /** The path within the AssetManager where the app will look for assets. */
  public pathToBundle: string;

  /** A Dart callback that was previously registered with the Dart VM. */
  public callbackHandle: FlutterCallbackInformation;

  constructor(resourceManager: resourceManager.ResourceManager,
              pathToBundle: string,
              callbackHandle: FlutterCallbackInformation) {
    this.resourceManager = resourceManager;
    this.pathToBundle = pathToBundle;
    this.callbackHandle = callbackHandle;
  }

  toString(): String {
    return "DartCallback( bundle path: "
      + this.pathToBundle
      + ", library path: "
      + this.callbackHandle.callbackLibraryPath
      + ", function: "
      + this.callbackHandle.callbackName
      + " )";
  }
}

export class DefaultBinaryMessenger implements BinaryMessenger {
  private messenger: DartMessenger;

  constructor(messenger: DartMessenger) {
    this.messenger = messenger;
  }

  makeBackgroundTaskQueue(options: TaskQueueOptions): TaskQueue {
    return this.messenger.makeBackgroundTaskQueue(options);
  }

  /**
   * Sends the given {@code messages} from Android to Dart over the given {@code channel} and then
   * has the provided {@code callback} invoked when the Dart side responds.
   *
   * @param channel the name of the logical channel used for the message.
   * @param message the message payload, a direct-allocated {@link ByteBuffer} with the message
   *     bytes between position zero and current position, or null.
   * @param callback a callback invoked when the Dart application responds to the message
   */

  send(channel: String, message: ArrayBuffer, callback?: BinaryReply): void {
    this.messenger.send(channel, message, callback);
  }

  /**
   * Sets the given {@link io.flutter.plugin.common.BinaryMessenger.BinaryMessageHandler} as the
   * singular handler for all incoming messages received from the Dart side of this Dart execution
   * context.
   *
   * @param channel the name of the channel.
   * @param handler a {@link BinaryMessageHandler} to be invoked on incoming messages, or null.
   */
  setMessageHandler(channel: String, handler: BinaryMessageHandler, taskQueue?: TaskQueue): void {
    this.messenger.setMessageHandler(channel, handler);
  }

  enableBufferingIncomingMessages(): void {
    this.messenger.enableBufferingIncomingMessages();
  }

  disableBufferingIncomingMessages(): void {
    this.messenger.disableBufferingIncomingMessages();
  }
}

class IsolateChannelMessageHandler implements BinaryMessageHandler {
  private isolateServiceId: String;
  private isolateServiceIdListener: IsolateServiceIdListener;

  constructor(isolateServiceId: String, isolateServiceIdListener: IsolateServiceIdListener) {
    this.isolateServiceId = isolateServiceId;
    this.isolateServiceIdListener = isolateServiceIdListener;
  }

  onMessage(message: ArrayBuffer, callback: BinaryReply): void {
    this.isolateServiceId = StringCodec.INSTANCE.decodeMessage(message);
    if (this.isolateServiceIdListener != null) {
      this.isolateServiceIdListener.onIsolateServiceIdAvailable(this.isolateServiceId);
    }
  }
}