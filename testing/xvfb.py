# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Functions to setup xvfb, which is used by the linux machines.
"""

import os
import platform
import signal
import subprocess
import tempfile
import time


def _XvfbDisplayIndex(_child_build_name):
  return '9'


def _XvfbPidFilename(child_build_name):
  """Returns the filename to the Xvfb pid file.  This name is unique for each
  builder. This is used by the linux builders."""
  return os.path.join(
      tempfile.gettempdir(),
      'xvfb-' + _XvfbDisplayIndex(child_build_name) + '.pid'
  )


def StartVirtualX(child_build_name, build_dir):
  """Start a virtual X server and set the DISPLAY environment variable so sub
  processes will use the virtual X server.  Also start openbox. This only works
  on Linux and assumes that xvfb and openbox are installed.

  Args:
    child_build_name: The name of the build that we use for the pid file.
        E.g., webkit-rel-linux.
    build_dir: The directory where binaries are produced.  If this is non-empty,
        we try running xdisplaycheck from |build_dir| to verify our X
        connection.
  """
  # We use a pid file to make sure we don't have any xvfb processes running
  # from a previous test run.
  StopVirtualX(child_build_name)

  xdisplaycheck_path = None
  if build_dir:
    xdisplaycheck_path = os.path.join(build_dir, 'xdisplaycheck')

  display = ':%s' % _XvfbDisplayIndex(child_build_name)
  # Note we don't add the optional screen here (+ '.0')
  os.environ['DISPLAY'] = display

  # Parts of Xvfb use a hard-coded "/tmp" for its temporary directory.
  # This can cause a failure when those parts expect to hardlink against
  # files that were created in "TEMPDIR" / "TMPDIR".
  #
  # See: https://crbug.com/715848
  env = os.environ.copy()
  if env.get('TMPDIR') and env['TMPDIR'] != '/tmp':
    print('Overriding TMPDIR to "/tmp" for Xvfb, was: %s' % (env['TMPDIR'],))
    env['TMPDIR'] = '/tmp'

  if xdisplaycheck_path and os.path.exists(xdisplaycheck_path):
    print('Verifying Xvfb is not running ...')
    checkstarttime = time.time()
    xdisplayproc = subprocess.Popen([xdisplaycheck_path, '--noserver'],
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT,
                                    env=env)
    # Wait for xdisplaycheck to exit.
    logs = xdisplayproc.communicate()[0]
    if xdisplayproc.returncode == 0:
      print('xdisplaycheck says there is a display still running, exiting...')
      raise Exception('Display already present.')

    xvfb_lock_filename = '/tmp/.X%s-lock' % _XvfbDisplayIndex(child_build_name)
    if os.path.exists(xvfb_lock_filename):
      print('Removing stale xvfb lock file %r' % xvfb_lock_filename)
      try:
        os.unlink(xvfb_lock_filename)
      except OSError as e:
        print('Removing xvfb lock file failed: %s' % e)

  # Figure out which X server to try.
  cmd = 'Xvfb'

  # Start a virtual X server that we run the tests in.  This makes it so we can
  # run the tests even if we didn't start the tests from an X session.
  proc = subprocess.Popen([
      cmd, display, '-screen', '0', '1280x800x24', '-ac', '-dpi', '96',
      '-maxclients', '512'
  ],
                          stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT,
                          env=env)
  xvfb_pid_filename = _XvfbPidFilename(child_build_name)
  open(xvfb_pid_filename, 'w').write(str(proc.pid))

  # Wait for Xvfb to start up.
  time.sleep(10)

  # Verify that Xvfb has started by using xdisplaycheck.
  if xdisplaycheck_path and os.path.exists(xdisplaycheck_path):
    print('Verifying Xvfb has started...')
    checkstarttime = time.time()
    xdisplayproc = subprocess.Popen([xdisplaycheck_path],
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT)
    # Wait for xdisplaycheck to exit.
    logs = xdisplayproc.communicate()[0]
    checktime = time.time() - checkstarttime
    if xdisplayproc.returncode != 0:
      print('xdisplaycheck failed after %d seconds.' % checktime)
      print('xdisplaycheck output:')
      for l in logs.splitlines():
        print('> %s' % l)
      rc = proc.poll()
      if rc is None:
        print('Xvfb still running, stopping.')
        proc.terminate()
      else:
        print('Xvfb exited, code %d' % rc)

      print('Xvfb output:')
      for l in proc.communicate()[0].splitlines():
        print('> %s' % l)
      raise Exception(logs)
    else:
      print('xdisplaycheck succeeded after %d seconds.' % checktime)
      print('xdisplaycheck output:')
      for l in logs.splitlines():
        print('> %s' % l)
    print('...OK')

  # Some ChromeOS tests need a window manager.
  subprocess.Popen('openbox', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  print('Window manager (openbox) started.')


def StopVirtualX(child_build_name):
  """Try and stop the virtual X server if one was started with StartVirtualX.
  When the X server dies, it takes down the window manager with it.
  If a virtual x server is not running, this method does nothing."""
  xvfb_pid_filename = _XvfbPidFilename(child_build_name)
  if os.path.exists(xvfb_pid_filename):
    xvfb_pid = int(open(xvfb_pid_filename).read())
    print('Stopping Xvfb with pid %d ...' % xvfb_pid)
    # If the process doesn't exist, we raise an exception that we can ignore.
    try:
      os.kill(xvfb_pid, signal.SIGKILL)
    except OSError:
      print('... killing failed, presuming unnecessary.')
    os.remove(xvfb_pid_filename)
    print('Xvfb pid file removed')
