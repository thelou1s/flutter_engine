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

import { PlatformViewsAccessibilityDelegate } from './PlatformViewsAccessibilityDelegate';
import PlatformViewsChannel, {
  PlatformViewBufferResized,
  PlatformViewCreationRequest,
  PlatformViewResizeRequest,
  PlatformViewsHandler, PlatformViewTouch, PlatformViewBufferSize
} from '../../../ets/embedding/engine/systemchannels/PlatformViewsChannel';
import PlatformView from './PlatformView';
import { DVModel, DVModelContainer, DVModelParameters, DynamicView } from '../../view/DynamicView/dynamicView';
import display from '@ohos.display';
import { FlutterView } from '../../view/FlutterView';
import { TextureRegistry } from '../../view/TextureRegistry';
import TextInputPlugin from '../editing/TextInputPlugin';
import { PlatformOverlayView } from './PlatformOverlayView';
import { PlatformViewWrapper } from './PlatformViewWrapper';
import { FlutterOverlaySurface } from '../../embedding/engine/FlutterOverlaySurface';
import HashSet from '@ohos.util.HashSet';
import PlatformViewRegistry from './PlatformViewRegistry';
import PlatformViewRegistryImpl from './PlatformViewRegistryImpl';
import DartExecutor from '../../embedding/engine/dart/DartExecutor';
import { AccessibilityEventsDelegate } from './AccessibilityEventsDelegate';
import AccessibilityBridge from '../../view/AccessibilityBridge';
import { RootDvModeManager } from './RootDvModelManager';
import { FlutterMutatorView } from '../../embedding/engine/mutatorsstack/FlutterMutatorView';
import common from '@ohos.app.ability.common';
import Log from '../../util/Log'
import OhosTouchProcessor from '../../embedding/ohos/OhosTouchProcessor'
import PlatformViewFactory from './PlatformViewFactory'
import { ByteBuffer } from '../../util/ByteBuffer';

const TAG = "PlatformViewsController"

export default class PlatformViewsController implements PlatformViewsAccessibilityDelegate, PlatformViewsHandler {
  private registry: PlatformViewRegistryImpl;
  private context: Context | null = null;
  private flutterView: FlutterView | null = null;
  private textureRegistry: TextureRegistry | null = null;
  private textInputPlugin: TextInputPlugin | null = null;
  private platformViewsChannel: PlatformViewsChannel | null = null;
  private accessibilityEventsDelegate: AccessibilityEventsDelegate;
  private nextOverlayLayerId: number = 0;
  private usesSoftwareRendering: boolean = false;

  private platformViews: Map<number, PlatformView>;
  private overlayLayerViews: Map<number, PlatformOverlayView>;
  private viewWrappers: Map<number, PlatformViewWrapper>;
  private currentFrameUsedOverlayLayerIds: HashSet<number>;
  private currentFrameUsedPlatformViewIds: HashSet<number>;
  private rootDvModel: DVModelContainer | null = RootDvModeManager.getRootDvMode();
  private platformViewParent: Map<number, FlutterMutatorView>;

  constructor() {
    this.registry = new PlatformViewRegistryImpl();
    this.accessibilityEventsDelegate = new AccessibilityEventsDelegate();
    this.overlayLayerViews = new Map<number, PlatformOverlayView>();
    this.currentFrameUsedOverlayLayerIds = new HashSet();
    this.currentFrameUsedPlatformViewIds = new HashSet();
    this.viewWrappers = new Map();
    this.platformViews = new Map();
    this.platformViewParent = new Map();
  }


  getPlatformViewById(viewId: number): Object {
    throw new Error('Method not implemented.');
  }

  usesVirtualDisplay(id: number): boolean {
    throw new Error('Method not implemented.');
  }

  attachAccessibilityBridge(accessibilityBridge: AccessibilityBridge): void {
    throw new Error('Method not implemented.');
  }

  detachAccessibilityBridge(): void {
    throw new Error('Method not implemented.');
  }

  createForPlatformViewLayer(request: PlatformViewCreationRequest): void {
    Log.i(TAG, "Enter createForPlatformViewLayer");
    this.ensureValidRequest(request);

    let platformView: PlatformView = this.createPlatformView(request, false);

    this.configureForHybridComposition(platformView, request);
  }

  dispose(viewId: number): void {
    let platformView: PlatformView | null = this.platformViews.get(viewId) || null;
    if (platformView == null) {
      Log.e(TAG, "Disposing unknown platform view with id: " + viewId);
      return;
    }
    this.platformViews.delete(viewId);

    try {
      platformView.dispose();
    } catch (err) {
      Log.e(TAG, "Disposing platform view threw an exception", err);
    }

    let viewWrapper: PlatformViewWrapper | null = this.viewWrappers.get(viewId) || null;
    if (viewWrapper != null) {
      this.viewWrappers.delete(viewId);
    }

    let parentView: FlutterMutatorView | null = this.platformViewParent.get(viewId) || null;
    if (parentView != null) {
      this.platformViewParent.delete(viewId);
    }
  }

  setParams: (params: DVModelParameters, key: string, element: ESObject ) => void = (params: DVModelParameters, key: string, element: ESObject): void => {
    let params2 = params as Record<string, ESObject>;
    params2[key] =element;
  }

  resize(request: PlatformViewResizeRequest, onComplete: PlatformViewBufferResized): void {
    let physicalWidth: number = this.toPhysicalPixels(request.newLogicalWidth);
    let physicalHeight: number = this.toPhysicalPixels(request.newLogicalHeight);
    let viewId: number = request.viewId;
    Log.i(TAG, `Resize viewId ${viewId}, pw:${physicalWidth}, ph:${physicalHeight},lw:${request.newLogicalWidth}, lh:${request.newLogicalHeight}`);

    let platformView: PlatformView | null = this.platformViews.get(viewId) || null;
    let viewWrapper: PlatformViewWrapper | null = this.viewWrappers.get(viewId) || null;
    if (platformView == null || viewWrapper == null) {
      Log.e(TAG, "Resizing unknown platform view with id: " + viewId);
      return;
    }

    let viewWrapperLayoutParams: DVModelParameters | undefined = viewWrapper.getDvModel()?.getLayoutParams();
    if (physicalWidth && viewWrapperLayoutParams) {
      this.setParams(viewWrapperLayoutParams, "width", physicalWidth);
      // viewWrapperLayoutParams.width = physicalWidth;
    }

    if (physicalHeight && viewWrapperLayoutParams) {
      this.setParams(viewWrapperLayoutParams, "height", physicalHeight);
      // viewWrapperLayoutParams.height = physicalHeight;
    }

    let embeddedView: DVModel = platformView.getView();
    if (embeddedView != null) {
      let embeddedViewLayoutParams = embeddedView.getLayoutParams();
      if (physicalWidth) {
        this.setParams(embeddedViewLayoutParams, "width", physicalWidth);
        // embeddedViewLayoutParams.width = physicalWidth;
      }

      if (physicalHeight) {
        this.setParams(embeddedViewLayoutParams, "height", physicalHeight);
        // embeddedViewLayoutParams.height = physicalHeight;
      }
    }

    onComplete.run(new PlatformViewBufferSize(request.newLogicalWidth, request.newLogicalHeight));
  }

  offset(viewId: number, top: number, left: number): void {
    Log.i(TAG, `Offset is id${viewId}, t:${top}, l:${left}`);
    let viewWrapper: PlatformViewWrapper | null = this.viewWrappers.get(viewId) || null;
    if (viewWrapper == null) {
      Log.e(TAG, "Setting offset for an unknown platform view with id: " + viewId);
      return;
    }

    let physicalTop = this.toPhysicalPixels(top);
    let physicalLeft = this.toPhysicalPixels(left);
    let params = viewWrapper.getDvModel()!.params;
    this.setParams(params!, "marginTop", physicalTop);
    this.setParams(params!, "marginLeft", physicalLeft);
    viewWrapper.setLayoutParams(params!);
  }

  onTouch(touch: PlatformViewTouch): void {
    let viewId: number = touch.viewId;
    let density: number = display.getDefaultDisplaySync().densityDPI;

    let platformView: PlatformView | null = this.platformViews.get(viewId) ?? null;
    if (platformView == null) {
      Log.e(TAG, "Sending touch to an unknown platform view with id: " + viewId);
      return;
    }
    let dvModel: DVModel = platformView.getView();
    if (dvModel == null) {
      Log.e(TAG, "Sending touch to a null dv model with id: " + viewId);
    }
    Log.e(TAG, "Sending touch to a dv model with id: " + viewId.toString());
    sendEventByKey(viewId.toString(), 10, "");
  }

  setDirection(viewId: number, direction: number): void {
    if (!this.validateDirection(direction)) {
      throw new Error("Trying to set unknown direction value: "
        + direction
        + "(view id: "
        + viewId
        + ")");
    }

    const platformView = this.platformViews.get(viewId);
    if (platformView == null) {
      Log.e(TAG, "Setting direction to an unknown view with id: " + viewId);
      return;
    }
    const embeddedView = platformView.getView();
    if (embeddedView == null) {
      Log.e(TAG, "Setting direction to a null view with id: " + viewId);
      return;
    }
    this.setParams(embeddedView.params, "direction", direction);
    // embeddedView.params.direction = direction;
  }

  validateDirection(direction:number):boolean {
    return direction == Direction.Ltr || direction == Direction.Rtl || direction == Direction.Auto;
  }

  clearFocus(viewId: number): void {
    const platformView = this.platformViews.get(viewId);
    if (platformView == null) {
      Log.e(TAG, "Setting direction to an unknown view with id: " + viewId);
      return;
    }
    const embeddedView = platformView.getView();
    if (embeddedView == null) {
      Log.e(TAG, "Setting direction to a null view with id: " + viewId);
      return;
    }
    focusControl.requestFocus("flutterXComponent");
  }
  synchronizeToNativeViewHierarchy(yes: boolean): void {
    throw new Error('Method not implemented.');
  }

  public createForTextureLayer(request: PlatformViewCreationRequest): number {
    Log.i(TAG, "Enter createForTextureLayer");
    this.ensureValidRequest(request);

    let viewId: number = request.viewId;
    if (this.viewWrappers.get(request.viewId) != null) {
      throw new Error(
        "Trying to create an already created platform view, view id: " + viewId);
    }

    let platformView: PlatformView = this.createPlatformView(request, true);
    let dynamicView: DVModel = platformView.getView();
    return this.configureForTextureLayerComposition(platformView, request);
  }

  private ensureValidRequest(request: PlatformViewCreationRequest): void {
    if (!this.validateDirection(request.direction)) {
      throw new Error("Trying to create a view with unknown direction value: "
        + request.direction
        + "(view id: "
        + request.viewId
        + ")")
    }
  }

  private createPlatformView(request: PlatformViewCreationRequest, wrapContext: boolean): PlatformView {
    Log.i(TAG, "Enter createPlatformView");
    const viewFactory: PlatformViewFactory = this.registry.getFactory(request.viewType);
    if (viewFactory == null) {
      throw new Error("Trying to create a platform view of unregistered type: " + request.viewType)
    }

    let createParams: ESObject = null;
    if (request.params != null) {
      let byteParas : ByteBuffer = request.params as ByteBuffer;
      createParams = viewFactory.getCreateArgsCodec().decodeMessage(byteParas.buffer);
    }

    if (this.context == null) {
      throw new Error('PlatformView#context is null.');
    }
    let platformView = viewFactory.create(this.context, request.viewId, createParams);

    let embeddedView: DVModel =  platformView.getView();
    if (embeddedView == null) {
      throw new Error("PlatformView#getView() returned null, but an dynamic view reference was expected.");
    }

    this.setParams(embeddedView.params, "direction", request.direction);
    // embeddedView.params.direction = request.direction;

    this.platformViews.set(request.viewId, platformView);
    return platformView;
  }

  // Configures the view for Hybrid Composition mode.
  private configureForHybridComposition(platformView: PlatformView, request: PlatformViewCreationRequest): void {
    Log.i(TAG, "Using hybrid composition for platform view: " + request.viewId);
  }

  private configureForTextureLayerComposition(platformView: PlatformView, request: PlatformViewCreationRequest): number {
    Log.i(TAG, "Hosting view in view hierarchy for platform view: " + request.viewId);

    let viewWrapper: PlatformViewWrapper = new PlatformViewWrapper();
    let textureId: number = 0;

    let physicalTop: number = this.toPhysicalPixels(request.logicalTop);
    let physicalLeft: number = this.toPhysicalPixels(request.logicalLeft);

    Log.i(TAG, `View pW:${request.logicalWidth}, pH:${request.logicalHeight}, pT:${physicalTop}, pL:${physicalLeft}`);

    let param: DVModelParameters = new DVModelParameters();

    this.setParams(param, "marginLeft", physicalLeft);
    this.setParams(param, "marginTop", physicalTop);
    // param.marginLeft = physicalLeft;
    // param.marginTop = physicalTop;

    let model = platformView.getView();
    if (request.logicalWidth != null) {
      let physicalWidth: number = this.toPhysicalPixels(request.logicalWidth);
      this.setParams(model.params, "width", physicalWidth);
      this.setParams(param, "width", physicalWidth);
      // model.params.width = physicalWidth;
      // param.width = physicalWidth;
    }

    if (request.logicalHeight != null) {
      let physicalHeight: number = this.toPhysicalPixels(request.logicalHeight);
      this.setParams(model.params, "height", physicalHeight);
      this.setParams(param, "height", physicalHeight);
      // model.params.height = physicalHeight;
      // param.height = physicalHeight;
    }

    viewWrapper.setLayoutParams(param);
    viewWrapper.addDvModel(model);

    RootDvModeManager.addDvModel(viewWrapper.getDvModel()!);
    this.viewWrappers.set(request.viewId, viewWrapper);
    Log.i(TAG, "Create platform view success");

    return textureId;
  }

  public attach(context: Context, textureRegistry: TextureRegistry | null, dartExecutor: DartExecutor): void {
    if (this.context != null) {

    }
    this.context = context;
    this.textureRegistry = textureRegistry;
    this.platformViewsChannel = new PlatformViewsChannel(dartExecutor);
    this.platformViewsChannel.setPlatformViewsHandler(this);
  }

  public detach(): void {
    if (this.platformViewsChannel != null) {
      this.platformViewsChannel.setPlatformViewsHandler(null);
    }
    this.destroyOverlaySurfaces();
    this.platformViewsChannel = null;
    this.context = null;
    this.textureRegistry = null;
  }

  public attachToView() {
    for (let wrapper of this.viewWrappers.values()) {
      this.rootDvModel?.model.children.push(wrapper.getDvModel()!);
    }
    for (let mutator of this.platformViewParent.values()) {
      this.rootDvModel?.model.children.push(mutator.getDvModel()!);
    }
    for (let platformView of this.platformViews.values()) {
      platformView.onFlutterViewAttached(this.rootDvModel!.model);
    }
  }

  public detachFromView(): void {
    for (let index = 0; index < this.viewWrappers.size; index++) {
      this.rootDvModel?.model.children.pop();
    }
    for (let index = 0; index < this.platformViewParent.size; index++) {
      this.rootDvModel?.model.children.pop();
    }
    this.destroyOverlaySurfaces();
    this.removeOverlaySurfaces();
    this.rootDvModel = null;

    for (let platformView of this.platformViews.values()) {
      platformView.onFlutterViewDetached();
    }
  }

  public attachTextInputPlugin(textInputPlugin: TextInputPlugin): void {
    this.textInputPlugin = textInputPlugin;
  }

  public detachTextInputPlugin(): void {
    this.textInputPlugin = null;
  }

  public getRegistry(): PlatformViewRegistry {
    return this.registry;
  }

  public onDetachedFromNapi(): void {
    this.diposeAllViews();
  }

  public onPreEngineRestart(): void {
    this.diposeAllViews();
  }

  private getDisplayDensity(): number {
    return display.getDefaultDisplaySync().densityPixels;
  }
  private toPhysicalPixels(logicalPixels: number): number {
    return Math.round(px2vp(logicalPixels * this.getDisplayDensity()));
  }

  private toLogicalPixelsByDensity(physicalPixels: number, displayDensity: number): number {
    return Math.round(physicalPixels / displayDensity);
  }

  private toLogicalPixels(physicalPixels: number): number {
    return this.toLogicalPixelsByDensity(physicalPixels, this.getDisplayDensity());
  }


  private diposeAllViews(): void {
  }

  private initializeRootImageViewIfNeeded(): void {
  }

  initializePlatformViewIfNeeded(viewId: number): void {
    let platformView: PlatformView = this.platformViews[viewId];
    if (platformView == null) {
      throw new Error("Platform view hasn't been initialized from the platform view channel.");
    }
    if (this.platformViewParent[viewId] == null) {
      return;
    }
    let dvModel: DVModel = platformView.getView();
    if (dvModel == null) {
      throw new Error("PlatformView#getView() returned null, but an ohos dv model reference was expected.");
    }
    let parentView: FlutterMutatorView = new FlutterMutatorView();
    parentView.setOnDescendantFocusChangeListener(() => {
      this.platformViewsChannel?.invokeViewFocused(viewId);
    }, () => {
      if (this.textInputPlugin != null) {
        this.textInputPlugin.clearTextInputClient();
      }
    });
  }

  public onDisplayOverlaySurface(id: number, x: number, y: number, width: number, height: number): void {
  }

  public onBeginFrame(): void {
    this.currentFrameUsedOverlayLayerIds.clear();
    this.currentFrameUsedPlatformViewIds.clear();
  }

  public onEndFrame(): void {
  }

  private finishFrame(isFrameRenderedUsingImageReaders: boolean): void {
  }

  public createOverlaySurfaceByPlatformOverlayView(imageView: PlatformOverlayView) {
    let id = this.nextOverlayLayerId++;
    this.overlayLayerViews.set(id, imageView);
    return new FlutterOverlaySurface(this.nextOverlayLayerId++);
  }

  public createOverlaySurface(): FlutterOverlaySurface {
    return new FlutterOverlaySurface(this.nextOverlayLayerId++);
  }

  private destroyOverlaySurfaces(): void {
  }

  private removeOverlaySurfaces(): void {
    if (!(this.flutterView instanceof FlutterView)) {
      return;
    }
  }
}