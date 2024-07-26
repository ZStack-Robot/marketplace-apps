import subprocess


def get_process(cmd, shell=None, workdir=None, pipe=None, executable=None):
    if pipe:
        return subprocess.Popen(cmd, shell=shell, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                close_fds=True, executable=executable, cwd=workdir)
    else:
        return subprocess.Popen(cmd, shell=shell, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                close_fds=True, executable=executable, cwd=workdir)


def bash_roe(cmd, workdir=None, errorout=False, ret_code=0, pipe_fail=False):
    p = get_process("/bin/bash", pipe=True, workdir=workdir)
    if pipe_fail:
        cmd = 'set -o pipefail; %s' % cmd

    cmd = cmd.encode('utf-8')

    o, e = p.communicate(cmd)
    r = p.returncode

    if r != ret_code and errorout:
        raise Exception('failed to execute bash[%s], return code: %s, stdout: %s, stderr: %s' % (cmd, r, o, e))
    if r == ret_code:
        e = None

    o = o.decode()
    return r, o, e
