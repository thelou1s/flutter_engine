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

#ifndef FLUTTER_FML_PLATFORM_OHOS_PATHS_OHOS_H_
#define FLUTTER_FML_PLATFORM_OHOS_PATHS_OHOS_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/paths.h"

namespace fml {
namespace paths {

void InitializeOhosCachesPath(std::string caches_path);

}  // namespace paths
}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_OHOS_PATHS_OHOS_H_
