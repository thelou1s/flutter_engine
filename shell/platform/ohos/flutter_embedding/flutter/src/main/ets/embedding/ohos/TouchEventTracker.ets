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
/** Tracks the motion events received by the FlutterView. */
import PlainArray from '@ohos.util.PlainArray';
import { TouchEvent } from '@ohos.multimodalInput.touchEvent';
import Queue from '@ohos.util.Queue';

export class TouchEventTracker {
  private eventById : PlainArray<TouchEvent>;
  private unusedEvents : Queue<number>;
  private static INSTANCE:TouchEventTracker;

  public static getInstance(): TouchEventTracker {
    if (TouchEventTracker.INSTANCE == null) {
      TouchEventTracker.INSTANCE = new TouchEventTracker();
    }
    return TouchEventTracker.INSTANCE;
  }

  constructor() {
    this.eventById = new PlainArray();
    this.unusedEvents = new Queue();
  }

  /** Tracks the event and returns a unique MotionEventId identifying the event. */
  public track(event :TouchEvent) : TouchEventId {
    const eventId:TouchEventId = TouchEventId.createUnique();
    this.eventById.add(eventId.getId(), event);
    this.unusedEvents.add(eventId.getId());
    return eventId;
  }

  /**
   * Returns the MotionEvent corresponding to the eventId while discarding all the motion events
   * that occurred prior to the event represented by the eventId. Returns null if this event was
   * popped or discarded.
   */
  public pop(eventId : TouchEventId) : TouchEvent {
    // remove all the older events.
    while (this.unusedEvents.length != 0 && this.unusedEvents.getFirst() < eventId.getId()) {
      this.eventById.remove(this.unusedEvents.pop());
    }

    // remove the current event from the heap if it exists.
    if (this.unusedEvents.length != 0 && this.unusedEvents.getFirst() == eventId.getId()) {
      this.unusedEvents.pop();
    }

    const event : TouchEvent = this.eventById.get(eventId.getId());
    this.eventById.remove(eventId.getId());
    return event;
  }
}

/** Represents a unique identifier corresponding to a motion event. */
export class TouchEventId {
  private static ID_COUNTER : number = 0;
  private id : number;

  constructor(id : number) {
    this.id = id;
  }

  public static from(id : number) : TouchEventId {
    return new TouchEventId(id);
  }

  public static createUnique() : TouchEventId {
    return new TouchEventId(TouchEventId.ID_COUNTER++);
  }

  public getId() : number {
    return this.id;
  }
}