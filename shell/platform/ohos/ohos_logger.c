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

#include "ohos_logger.h"

#define OHOS_TAG "XComFlutterOHOS"

int ohos_log(OhosLogLevel level, const char* fmt, ...) {
  char buffer[1024];
  int len = 0;
  {
    va_list args;
    va_start(args, fmt);
    len = vsnprintf(buffer, sizeof(buffer) - 1, fmt, args);
    va_end(args);
  }
  if (len <= 0) {
    return len;
  }
  buffer[len] = '\0';
  // int OH_LOG_Print(LogType type, LogLevel level, unsigned int domain, const
  // char *tag, const char *fmt, ...)
  OH_LOG_Print(LOG_APP, (LogLevel)level, LOG_DOMAIN, OHOS_TAG,
               "Thread:%{public}lu  %{public}s", (unsigned long)pthread_self(),
               buffer);
  return len;
}
