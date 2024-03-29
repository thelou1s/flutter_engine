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

/**
 * flutterLoader，负责dart虚拟机启动和dart代码加载
 */
import FlutterShellArgs from '../FlutterShellArgs';
import FlutterNapi from '../FlutterNapi';
import Log from '../../../util/Log';
import FlutterApplicationInfo from './FlutterApplicationInfo';
import common from '@ohos.app.ability.common';
import StringUtils from '../../../util/StringUtils';
import ApplicationInfoLoader from './ApplicationInfoLoader';
import bundleManager from '@ohos.bundle.bundleManager';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import data_preferences from '@ohos.data.preferences';

const TAG = "FlutterLoader";

//flutter引擎so
const DEFAULT_LIBRARY = "libflutter.so";
//jit产物默认kenel文件
const DEFAULT_KERNEL_BLOB = "kernel_blob.bin";
//jit产物，默认快照文件
const VMSERVICE_SNAPSHOT_LIBRARY = "libvmservice_snapshot.so";
//key值
const SNAPSHOT_ASSET_PATH_KEY = "snapshot-asset-path";
//key值
const VM_SNAPSHOT_DATA_KEY = "vm-snapshot-data";
//key值
const ISOLATE_SNAPSHOT_DATA_KEY = "isolate-snapshot-data";


const AOT_SHARED_LIBRARY_NAME = "aot-shared-library-name";

const AOT_VMSERVICE_SHARED_LIBRARY_NAME = "aot-vmservice-shared-library-name";

//文件路径分隔符
const FILE_SEPARATOR = "/";

const TIMESTAMP_PREFIX = "res_timestamp-";

/**
 * 定位在hap包中的flutter资源，并且加载flutter native library.
 */
export default class FlutterLoader {
  flutterNapi: FlutterNapi;
  initResult: InitResult | null = null;
  flutterApplicationInfo: FlutterApplicationInfo | null = null;
  context: common.Context | null = null;
  initialized: boolean = false;
  //初始化开始时间戳
  initStartTimestampMillis: number = 0;

  constructor(flutterNapi: FlutterNapi) {
    this.flutterNapi = flutterNapi;
  }

  /**
   * Starts initialization of the native system.
   *
   * <p>This loads the Flutter engine's native library to enable subsequent JNI calls. This also
   * starts locating and unpacking Dart resources packaged in the app's APK.
   *
   * <p>Calling this method multiple times has no effect.
   *
   * @param applicationContext The Android application context.
   * @param settings Configuration settings.
   */
  async startInitialization(context: common.Context) {
    Log.d(TAG, "flutterLoader start init")
    this.initStartTimestampMillis = Date.now();
    this.context = context;
    this.flutterApplicationInfo = ApplicationInfoLoader.load(context);
    if (this.flutterApplicationInfo!.isDebugMode) {
      await this.copyResource(context)
    } else {
      await this.copyICU(context)
    }
    this.initResult = new InitResult(
      `${context.filesDir}/`,
      `${context.cacheDir}/`,
      `${context.filesDir}`
    )
    Log.d(TAG, "flutterLoader end init")
  }

  private async copyICU(context: common.Context) {
    let filePath = context.filesDir + FILE_SEPARATOR + this.flutterApplicationInfo!.flutterAssetsDir
    const timestamp = await this.checkTimestamp(filePath);
    if (timestamp == null) {
      Log.d(TAG, "no need copyICU")
      return;
    }
    if (this.context != null) {
      Log.d(TAG, "start copyICU")
      if (fs.accessSync(filePath)) {
        fs.rmdirSync(filePath);
      }
      fs.mkdirSync(filePath)
      let icudtlBuffer = await this.context.resourceManager.getRawFileContent(this.flutterApplicationInfo!.flutterAssetsDir + "/icudtl.dat")
      let icudtlFile = fs.openSync(filePath + FILE_SEPARATOR + "/icudtl.dat", fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
      fs.writeSync(icudtlFile.fd, icudtlBuffer.buffer)
      if (timestamp != null) {
        fs.openSync(filePath + FILE_SEPARATOR + timestamp, fs.OpenMode.READ_ONLY | fs.OpenMode.CREATE)
      }
      Log.d(TAG, "copyICU end")
    }
  }

  private async copyResource(context: common.Context) {
    let filePath = context.filesDir + FILE_SEPARATOR + this.flutterApplicationInfo!.flutterAssetsDir
    const timestamp = await this.checkTimestamp(filePath);
    if (timestamp == null) {
      Log.d(TAG, "no need copyResource")
      return;
    }
    if (this.context != null) {
      Log.d(TAG, "start copyResource")
      if (fs.accessSync(filePath + FILE_SEPARATOR + DEFAULT_KERNEL_BLOB)) {
        Log.d(TAG, "hap has changed, start delete previous file")
        fs.rmdirSync(filePath);
      }

      fs.mkdirSync(filePath)

      let icudtlBuffer = await this.context.resourceManager.getRawFileContent(this.flutterApplicationInfo!.flutterAssetsDir + "/icudtl.dat")
      let icudtlFile = fs.openSync(filePath + FILE_SEPARATOR + "/icudtl.dat", fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
      fs.writeSync(icudtlFile.fd, icudtlBuffer.buffer)

      let kernelBuffer = await this.context.resourceManager.getRawFileContent(this.flutterApplicationInfo!.flutterAssetsDir + FILE_SEPARATOR + DEFAULT_KERNEL_BLOB)
      let kernelFile = fs.openSync(filePath + FILE_SEPARATOR + DEFAULT_KERNEL_BLOB, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
      fs.writeSync(kernelFile.fd, kernelBuffer.buffer)

      let vmBuffer = await this.context.resourceManager.getRawFileContent(this.flutterApplicationInfo!.flutterAssetsDir + FILE_SEPARATOR + this.flutterApplicationInfo!.vmSnapshotData)
      let vmFile = fs.openSync(filePath + FILE_SEPARATOR + this.flutterApplicationInfo!.vmSnapshotData, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
      fs.writeSync(vmFile.fd, vmBuffer.buffer)

      let isolateBuffer = await this.context.resourceManager.getRawFileContent(this.flutterApplicationInfo!.flutterAssetsDir + FILE_SEPARATOR + this.flutterApplicationInfo!.isolateSnapshotData)
      let isolateFile = fs.openSync(filePath + FILE_SEPARATOR + this.flutterApplicationInfo!.isolateSnapshotData, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
      fs.writeSync(isolateFile.fd, isolateBuffer.buffer)

      if (timestamp != null) {
        fs.openSync(filePath + FILE_SEPARATOR + timestamp, fs.OpenMode.READ_ONLY | fs.OpenMode.CREATE)
      }
      Log.d(TAG, "copyResource end")
    } else {
      Log.d(TAG, "no copyResource")
    }
  }

  /**
   * 初始化dart虚拟机方法
   * @param flutterShellArgs
   */
  ensureInitializationComplete(shellArgs: Array<string> | null) {
    if (this.initialized) {
      return;
    }
    Log.d(TAG, "ensureInitializationComplete")
    if (shellArgs == null) {
      shellArgs = new Array<string>();
    }
    shellArgs.push(
      "--icu-native-lib-path="
        + this.flutterApplicationInfo!.nativeLibraryDir
        + FILE_SEPARATOR + DEFAULT_LIBRARY
    );

    let kernelPath: string = "";
    if (this.flutterApplicationInfo!.isDebugMode) {
      Log.d(TAG, "this.initResult!.dataDirPath=" + this.initResult!.dataDirPath)
      const snapshotAssetPath = this.initResult!.dataDirPath + FILE_SEPARATOR + this.flutterApplicationInfo!.flutterAssetsDir;
      kernelPath = snapshotAssetPath + FILE_SEPARATOR + DEFAULT_KERNEL_BLOB;
      shellArgs.push("--icu-data-file-path=" + snapshotAssetPath + "/icudtl.dat")
      shellArgs.push("--" + SNAPSHOT_ASSET_PATH_KEY + "=" + snapshotAssetPath);
      shellArgs.push("--" + VM_SNAPSHOT_DATA_KEY + "=" + this.flutterApplicationInfo!.vmSnapshotData);
      shellArgs.push(
        "--" + ISOLATE_SNAPSHOT_DATA_KEY + "=" + this.flutterApplicationInfo!.isolateSnapshotData);
    } else {
      shellArgs.push(
        "--" + AOT_SHARED_LIBRARY_NAME + "=" + this.flutterApplicationInfo!.aotSharedLibraryName);
      shellArgs.push(
        "--"
          + AOT_SHARED_LIBRARY_NAME
          + "="
          + this.flutterApplicationInfo!.nativeLibraryDir
          + FILE_SEPARATOR
          + this.flutterApplicationInfo!.aotSharedLibraryName);
      const snapshotAssetPath = this.initResult!.dataDirPath + FILE_SEPARATOR + this.flutterApplicationInfo!.flutterAssetsDir;
      shellArgs.push("--icu-data-file-path=" + snapshotAssetPath + "/icudtl.dat")
      if (this.flutterApplicationInfo!.isProfile) {
        shellArgs.push("--" + AOT_VMSERVICE_SHARED_LIBRARY_NAME + "=" + VMSERVICE_SNAPSHOT_LIBRARY);
      }
    }
    shellArgs.push("--cache-dir-path=" + this.initResult!.engineCachesPath);
    if (StringUtils.isNotEmpty(this.flutterApplicationInfo!.domainNetworkPolicy)) {
      shellArgs.push("--domain-network-policy=" + this.flutterApplicationInfo!.domainNetworkPolicy);
    }

    const resourceCacheMaxBytesThreshold = 1080 * 1920 * 12 * 4;
    shellArgs.push("--resource-cache-max-bytes-threshold=" + resourceCacheMaxBytesThreshold);

    shellArgs.push("--prefetched-default-font-manager");

    shellArgs.push("--leak-vm=" + true);

    //shellArgs.push("--enable-impeller");

    // //最终初始化操作
    const costTime = Date.now() - this.initStartTimestampMillis;
    this.flutterNapi!.init(
      this.context!,
      shellArgs,
      kernelPath,
      this.initResult!.appStoragePath,
      this.initResult!.engineCachesPath!,
      costTime
    );
    this.initialized = true;
  }

  findAppBundlePath(): string {
    return this.flutterApplicationInfo == null ? "" : this.flutterApplicationInfo!.flutterAssetsDir;
  }

  getLookupKeyForAsset(asset: string, packageName?: string): string {
    return this.fullAssetPathFrom(asset);
  }

  fullAssetPathFrom(filePath: string): string {
    return this.flutterApplicationInfo == null ? "" : this.flutterApplicationInfo!.flutterAssetsDir + "/" + filePath;
  }

  private async checkTimestamp(dataDir: string) : Promise<string | null> {
    let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
    const expectedTimestamp = TIMESTAMP_PREFIX + bundleInfo.versionCode + "-" + bundleInfo.updateTime;
    const existingTimestamps = this.getExistingTimestamps(dataDir);
    if (existingTimestamps == null) {
      Log.i(TAG, "No extracted resources found");
      return expectedTimestamp;
    }

    if (existingTimestamps.length == 1) {
      Log.i(TAG, "Found extracted resources " + existingTimestamps[0]);
    }

    if (existingTimestamps.length != 1 || !(expectedTimestamp == existingTimestamps[0])) {
      Log.i(TAG, "Resource version mismatch " + expectedTimestamp);
      return expectedTimestamp;
    }

    return null;
  }

  private getExistingTimestamps(dataDir: string): string[] {
    return fs.accessSync(dataDir) ? fs.listFileSync(dataDir, {
      filter: {
        displayName: [`${TIMESTAMP_PREFIX}*`]
      }
    }) : new Array();
  }

}

class InitResult {
  appStoragePath: string;
  engineCachesPath: string;
  dataDirPath: string;

  constructor(appStoragePath: string,
              engineCachesPath: string,
              dataDirPath: string) {
    this.appStoragePath = appStoragePath;
    this.engineCachesPath = engineCachesPath;
    this.dataDirPath = dataDirPath;
  }
}