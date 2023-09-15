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

#ifndef OHOS_SNAPSHOT_SURFACE_PRODUCER_H
#define OHOS_SNAPSHOT_SURFACE_PRODUCER_H
#include "flutter/flow/surface.h"
#include "flutter/shell/common/snapshot_surface_producer.h"
#include "flutter/shell/platform/ohos/surface/ohos_surface.h"

namespace flutter {
class OHOSSnapshotSurfaceProducer : public SnapshotSurfaceProducer {
 public:
  explicit OHOSSnapshotSurfaceProducer(OHOSSurface& ohos_surface);

  // |SnapshotSurfaceProducer|
  std::unique_ptr<Surface> CreateSnapshotSurface() override;

 private:
  OHOSSurface& ohos_surface_;
};
}  // namespace flutter

#endif