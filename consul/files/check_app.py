#!/usr/bin/env python3

import re
import sys
import argparse
import subprocess
from subprocess import PIPE

def check_app(name):
    cmd = 'ps axu | grep ' + name + ' | grep -v -e grep -e python3'
    cp = subprocess.run(
            cmd, stdout=PIPE, stderr=PIPE,
            universal_newlines=True,
            shell=True)
    if len(cp.stdout.split('\n')) > 1:
        print(f'{name} is running')
        return True
    else:
        print(f'{name} is NOT running')
        sys.exit(1)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            description='Check running application')
    parser.add_argument(
            'app_name', help='Name of the application')
    args = parser.parse_args()
    check_app(args.app_name)
