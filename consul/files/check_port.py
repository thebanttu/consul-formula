#!/usr/bin/env python3

import sys
import argparse
import socket

retval = 3
timeout = 4

def check_port(port, host='127.0.0.1'):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        if sock.connect_ex((host, int(port))) == 0:
            print(f'Port {port} on {host} is reachable.')
            return True
        else:
            print(f'Port {port} is NOT reachable on {host}')
            sys.exit(retval)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            description='Check if port is open')
    parser.add_argument('--server', '-s',
                        help='Name of the application')
    parser.add_argument('port',
                        help='Name of the application')
    args = parser.parse_args()
    if (args.server):
        check_port(args.port, args.server)
    else:
        check_port(args.port)

# {-_-}
