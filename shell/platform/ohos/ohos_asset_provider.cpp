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

#include "ohos_asset_provider.h"
#include <rawfile/raw_file.h>
#include <rawfile/raw_file_manager.h>
#include "napi_common.h"

namespace flutter {

class FileDescriptionMapping : public fml::Mapping {
 public:
  explicit FileDescriptionMapping(RawFile* fileHandle)
      : fileHandle_(fileHandle), filebuf(nullptr), _read_from_file(false) {
    LOGD("FileDescriptionMapping :%{public}p", fileHandle_);
    int ret = 0;
    if (0 > (ret = ReadFile())) {
      LOGD("FileDescriptionMapping :%{public}d", ret);
    }
  }
  void* GetBuffer() {
    // TODO 考虑线程安全

    if (filebuf != nullptr)
      return filebuf;

    size_t bufLenth = GetSize();

    if (fileHandle_ != nullptr && bufLenth > 0) {
      LOGD("FileDescriptionMapping buflenth = %{public}ld", bufLenth);
      filebuf = malloc(bufLenth + 1);
      memset(filebuf, 0, bufLenth + 1);
    }
    return filebuf;
  }

  ~FileDescriptionMapping() override {
    if (fileHandle_ != nullptr) {
      OH_ResourceManager_CloseRawFile(fileHandle_);
    }
    if (filebuf != nullptr) {
      free(filebuf);
      filebuf = nullptr;
    }
  }

  size_t GetSize() const override {
    if (fileHandle_ == nullptr)
      return 0;

    size_t ret = OH_ResourceManager_GetRawFileSize(fileHandle_);
    LOGD("GetSize():%{public}zu", ret);
    return ret;
  }

  int ReadFile() {
    if (fileHandle_ == nullptr) {
      LOGE("GetMapping  failed. fileHandle_:%{public}p,filebuf:%{public}p",
           fileHandle_, filebuf);
      return -1;
    }

    size_t len = GetSize();
    void* buf = GetBuffer();
    int ret = 0;

    if (buf != nullptr) {
      ret = OH_ResourceManager_ReadRawFile(fileHandle_, buf, len);
      _read_from_file = true;
    }
    LOGD("GetMapping ... total:%{public}zu, ret:%{public}d,buf:%{public}p", len,
         ret, buf);
    return ret;
  }
  const uint8_t* GetMapping() const override {
    return reinterpret_cast<const uint8_t*>(filebuf);
  }

  bool IsDontNeedSafe() const override {
    // thread unsafe
    return false;
  }

 private:
  RawFile* fileHandle_;
  void* filebuf;
  bool _read_from_file;
  FML_DISALLOW_COPY_AND_ASSIGN(FileDescriptionMapping);
};

OHOSAssetProvider::OHOSAssetProvider(void* assetHandle, const std::string& dir)
    : assetHandle_(assetHandle), dir_(dir) {
  LOGD("assets dir:%{public}s", dir.c_str());
}

bool OHOSAssetProvider::IsValid() const {
  return (assetHandle_ != nullptr);
}

bool OHOSAssetProvider::IsValidAfterAssetManagerChange() const {
  return true;
}

AssetResolver::AssetResolverType OHOSAssetProvider::GetType() const {
  return AssetResolver::AssetResolverType::kApkAssetProvider;
}

std::unique_ptr<fml::Mapping> OHOSAssetProvider::GetAsMapping(
    const std::string& asset_name) const {
  NativeResourceManager* nativeResMgr =
      reinterpret_cast<NativeResourceManager*>(assetHandle_);
  if (assetHandle_ == nullptr || nativeResMgr == nullptr) {
    LOGE("nativeResMgr is null:%{public}p or  nativeResMgr is null:%{public}p ",
         assetHandle_, nativeResMgr);
  }
  std::string relativePath = dir_ + "/" + asset_name;

  LOGE("GetAsMapping=%{public}s->%{public}s", asset_name.c_str(),
       relativePath.c_str());

  RawFile* fileHandle =
      OH_ResourceManager_OpenRawFile(nativeResMgr, relativePath.c_str());
  LOGE("GetAsMapping=%{public}s->%{public}p", relativePath.c_str(), fileHandle);

  if (fileHandle == nullptr) {
    fileHandle =
        OH_ResourceManager_OpenRawFile(nativeResMgr, asset_name.c_str());
    LOGE("GetAsMapping2 ..fallback:%{public}s->%{public}p", asset_name.c_str(),
         fileHandle);
  }
  LOGE("GetAsMappingend:%{public}p", fileHandle);
  return fileHandle == nullptr
             ? nullptr
             : (std::make_unique<FileDescriptionMapping>(fileHandle));
}

std::unique_ptr<OHOSAssetProvider> OHOSAssetProvider::Clone() const {
  return std::make_unique<OHOSAssetProvider>(assetHandle_);
}

}  // namespace flutter
