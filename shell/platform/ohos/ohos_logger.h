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

#ifndef __OHOS__LOGGER_H
#define __OHOS__LOGGER_H
#include <hilog/log.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  /** Debug level to be used by {@link OH_LOG_DEBUG} */
  OHOS_LOG_DEBUG = 3,
  /** Informational level to be used by {@link OH_LOG_INFO} */
  OHOS_LOG_INFO = 4,
  /** Warning level to be used by {@link OH_LOG_WARN} */
  OHOS_LOG_WARN = 5,
  /** Error level to be used by {@link OH_LOG_ERROR} */
  OHOS_LOG_ERROR = 6,
  /** Fatal level to be used by {@link OH_LOG_FATAL} */
  OHOS_LOG_FATAL = 7,
} OhosLogLevel;

extern int ohos_log(OhosLogLevel level, const char* fmt, ...);

#ifdef __cplusplus
}  // end extern
#endif

#endif
