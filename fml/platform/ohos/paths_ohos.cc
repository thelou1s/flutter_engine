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

#include "flutter/fml/platform/ohos/paths_ohos.h"

#include "flutter/fml/file.h"

namespace fml {
namespace paths {

std::pair<bool, std::string> GetExecutablePath() {
  return {false, ""};
}

static std::string gCachesPath;

void InitializeOhosCachesPath(std::string caches_path) {
  gCachesPath = std::move(caches_path);
}

fml::UniqueFD GetCachesDirectory() {
  // If the caches path is not initialized, the FD will be invalid and caching
  // will be disabled throughout the system.
  return OpenDirectory(gCachesPath.c_str(), false, fml::FilePermission::kRead);
}

}  // namespace paths
}  // namespace fml
