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

import BuildProfile from "../../../../../../BuildProfile.ets";

const DEFAULT_AOT_SHARED_LIBRARY_NAME = "libapp.so";
const DEFAULT_VM_SNAPSHOT_DATA = "vm_snapshot_data";
const DEFAULT_ISOLATE_SNAPSHOT_DATA = "isolate_snapshot_data";
const DEFAULT_FLUTTER_ASSETS_DIR = "flutter_assets";


/**
 * application 信息，后期看如何设置
 */
export default class FlutterApplicationInfo {
  aotSharedLibraryName: string;
  vmSnapshotData: string;
  isolateSnapshotData: string;
  flutterAssetsDir: string;
  domainNetworkPolicy: string;
  nativeLibraryDir: string;
  automaticallyRegisterPlugins: boolean;
  //是否是开发模式，先放在这里，后续应该从context获取
  isDebugMode: boolean;
  //是否是profile模式
  isProfile: boolean;

  constructor(aotSharedLibraryName: string | null,
              vmSnapshotData: string | null,
              isolateSnapshotData: string | null,
              flutterAssetsDir: string | null,
              domainNetworkPolicy: string | null,
              nativeLibraryDir: string,
              automaticallyRegisterPlugins: boolean) {
    this.aotSharedLibraryName = aotSharedLibraryName == null ? DEFAULT_AOT_SHARED_LIBRARY_NAME : aotSharedLibraryName;
    this.vmSnapshotData = vmSnapshotData == null ? DEFAULT_VM_SNAPSHOT_DATA : vmSnapshotData;
    this.isolateSnapshotData = isolateSnapshotData == null ? DEFAULT_ISOLATE_SNAPSHOT_DATA : isolateSnapshotData;
    this.flutterAssetsDir = flutterAssetsDir == null ? DEFAULT_FLUTTER_ASSETS_DIR : flutterAssetsDir;
    this.domainNetworkPolicy = domainNetworkPolicy == null ? "" : domainNetworkPolicy;
    this.nativeLibraryDir = nativeLibraryDir;
    this.automaticallyRegisterPlugins = automaticallyRegisterPlugins;
    this.isDebugMode = "debug" == String(BuildProfile.BUILD_MODE_NAME);
    this.isProfile = "profile" == String(BuildProfile.BUILD_MODE_NAME);
  }
}