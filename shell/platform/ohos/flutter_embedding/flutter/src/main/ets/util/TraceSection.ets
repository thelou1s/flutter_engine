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

import hiTraceMeter from '@ohos.hiTraceMeter'

export class TraceSection {

  static taskId: number = 1;

  private static cropSectionName(sectionName: string): string {
    return sectionName.length < 124 ? sectionName : sectionName.substring(0, 124) + "...";
  }

  /**
   * Wraps Trace.beginSection to ensure that the line length stays below 127 code units.
   *
   * @param sectionName The string to display as the section name in the trace.
   */
  public static begin(sectionName: string): void {
    hiTraceMeter.startTrace(this.cropSectionName(sectionName), this.taskId++);
  }

  /** Wraps Trace.endSection. */
  public static end(sectionName: string): void {
    hiTraceMeter.finishTrace(this.cropSectionName(sectionName), this.taskId);
  }
}
