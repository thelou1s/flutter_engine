import subprocess
import threading
import time
import os
import signal
import inspect
import ctypes
import tempfile


class TimeoutError(Exception):
    pass

class SubProcess(threading.Thread):

    def __init__(self, cmd, path, timeout=5, log = False):
        super(SubProcess,self).__init__()
        self.cmd = cmd
        self.event = threading.Event()
        self.stdout = ""
        self.stderr = ""
        self.retcode = None
        self.timeout = timeout
        self.path = path
        self.log = log
        self.sub = None

    def run(self):
        try:
            start_time = time.time()
            read_flag = end_flag = False
            PIPE = subprocess.PIPE
            self.sub = subprocess.Popen(self.cmd, cwd=self.path, shell=True, stderr=PIPE, stdout=PIPE, text=True)
            while not self.event.is_set() and self.sub.poll() is None:
                self.stdout += self.sub.stdout.read()
                time.sleep(0.05)
                self.stderr +=self.sub.stderr.read()
                if (time.time()-start_time) > self.timeout:
                    self.retcode = -2
                    self.sub.stderr = TimeoutError('执行超时：' + self.cmd)
                    return
            self.sub.stdout.close()
            self.sub.stderr.close()
            self.retcode = self.sub.returncode
        except Exception as ex:
            self.retcode = -1
            self.stderr = ex
            self.event.set()
            self.sub.stdout.close()
            self.sub.stderr.close()

    def stop(self):
        self.event.set()

# 执行数组命令
def excuteArr(cmdArr, path=".", log = True, timeout=5):
    str = ' '.join(cmdArr)
    return execCommandEx(str, path, log, timeout)

def execCommandEx(cmd, path = ".", log = False, timeout=1):
    start_time = end_time = time.time()
    sub = SubProcess(cmd, path, 10, log)
    sub.daemon = True
    sub.start()
    while True:
        # print("执行中000：" + cmd  + "  is_set:" + str(sub.event.is_set()) +  " is_alive:" + str(sub.is_alive())  + " name:" + sub.name +  "  time:" + str(time.time())    + " start:" + str(start_time) + "  t:" + str(int(time.time() - start_time)) + "  tout:" + str(timeout))
        if int(time.time()  - start_time) > int(timeout):
            # print("执行中：" + cmd + "  time:" + str(time.time())    + " start:" + str(start_time) + "  t:" + str(int(time.time() - start_time)) + "  tout:" + str(timeout))
            sub.retcode = -1
            sub.stderr = TimeoutError('执行超时：' + cmd)
            sub.stop()
        if not sub.is_alive() or sub.event.is_set():
            break
        time.sleep(0.1)
        end_time = time.time()
    return sub.retcode,sub.stdout,sub.stderr
