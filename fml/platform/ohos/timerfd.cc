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

#include "flutter/fml/platform/ohos/timerfd.h"

#include <sys/types.h>
#include <unistd.h>
#include <cstring>

#include "flutter/fml/eintr_wrapper.h"
#include "flutter/fml/logging.h"

#if FML_TIMERFD_AVAILABLE == 0

#include <asm/unistd.h>
#include <sys/syscall.h>

int timerfd_create(int clockid, int flags) {
  return syscall(__NR_timerfd_create, clockid, flags);
}

int timerfd_settime(int ufc,
                    int flags,
                    const struct itimerspec* utmr,
                    struct itimerspec* otmr) {
  return syscall(__NR_timerfd_settime, ufc, flags, utmr, otmr);
}

#endif  // FML_TIMERFD_AVAILABLE == 0

namespace fml {
constexpr int NSEC_PER_SEC = 1000000000;
bool TimerRearm(int fd, fml::TimePoint time_point) {
  uint64_t nano_secs = time_point.ToEpochDelta().ToNanoseconds();

  // "0" will disarm the timer, desired behavior is to immediately
  // trigger the timer.
  if (nano_secs < 1) {
    nano_secs = 1;
  }

  struct itimerspec spec = {};
  spec.it_value.tv_sec = static_cast<time_t>(nano_secs / NSEC_PER_SEC);
  spec.it_value.tv_nsec = nano_secs % NSEC_PER_SEC;
  spec.it_interval = spec.it_value;  // single expiry.

  int result = ::timerfd_settime(fd, TFD_TIMER_ABSTIME, &spec, nullptr);
  if (result != 0) {
    FML_DLOG(ERROR) << "timerfd_settime err:" << strerror(errno);
  }
  return result == 0;
}

bool TimerDrain(int fd) {
  // 8 bytes must be read from a signaled timer file descriptor when signaled.
  uint64_t fire_count = 0;
  ssize_t size = FML_HANDLE_EINTR(::read(fd, &fire_count, sizeof(uint64_t)));
  if (size != sizeof(uint64_t)) {
    return false;
  }
  return fire_count > 0;
}

}  // namespace fml
