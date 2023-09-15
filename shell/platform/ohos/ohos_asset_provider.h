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

#ifndef OHOS_ASSET_PROVIDER_H
#define OHOS_ASSET_PROVIDER_H

#include "flutter/assets/asset_resolver.h"
#include "flutter/fml/memory/ref_counted.h"

namespace flutter {

// ohos平台的文件管理 ，必须通过NativeResourceManager* 指针对它进行初始化
class OHOSAssetProvider final : public AssetResolver {
 public:
  explicit OHOSAssetProvider(void* assetHandle,
                             const std::string& dir = "flutter_assets");
  ~OHOSAssetProvider() = default;

  std::unique_ptr<OHOSAssetProvider> Clone() const;

 private:
  void* assetHandle_;
  std::string dir_;

  bool IsValid() const override;

  bool IsValidAfterAssetManagerChange() const override;

  AssetResolver::AssetResolverType GetType() const override;

  std::unique_ptr<fml::Mapping> GetAsMapping(
      const std::string& asset_name) const override;
};
}  // namespace flutter
#endif