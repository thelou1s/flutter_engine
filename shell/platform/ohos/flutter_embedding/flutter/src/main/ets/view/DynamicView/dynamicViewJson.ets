/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import { DVModel, DVModelParameters, DVModelEvents, DVModelChildren } from "./dynamicView";

export function createDVModelFromJson(json: Object): DVModel {

  /* private use helper functions */

  function createChildrenFrom(children: Array<Object>): DVModelChildren {
    let result = new DVModelChildren();
    if (Array.isArray(children)) {
      (children as Array<Object>).forEach(child => {
        const childView = createDVModelFromJson(child);
        if (childView != undefined) {
          result.push(childView);
        }
      });
    }
    return result;
  }

  function createAttributesFrom(attributes: Object): DVModelParameters {
    let result = new DVModelParameters();
    if ((typeof attributes == "object") && (!Array.isArray(attributes))) {
      Object.keys(attributes).forEach(k => result[k] = attributes[k]);
    }
    return result;
  }

  function createEventsFrom(events: Object): DVModelEvents {
    let result = new DVModelEvents();
    if ((typeof events == "object") && (!Array.isArray(events))) {
      Object.keys(events).forEach(k => result[k] = events[k]);
    }
    return result;
  }

  if (typeof json !== 'object') {
    console.error("createDVModelFromJson: input is not JSON");
    return undefined;
  }

  return new DVModel(
    json["compType"],
    createAttributesFrom(json["attributes"]),
    createEventsFrom(json["events"]),
    createChildrenFrom(json["children"]),
    json["build"]
  );
}
