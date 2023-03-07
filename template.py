#!/usr/bin/env python3

"""
A tool to get a page from confluence
"""

import argparse
import logging
import os
import sys


def setup():
    parser = argparse.ArgumentParser(description='a tool to ')
    parser.add_argument('-o', '--optional', required=False,
                        help='this is what -o does')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--verbose', action='store_true')
    group.add_argument('--quiet', action='store_true')
    a = parser.parse_args()

    if a.verbose and not a.quiet:
        logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.DEBUG)
    if not a.verbose and a.quiet:
        logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.WARNING)
    if a.verbose and a.quiet:
        logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)
        logger.error('Cannot set verbose and quiet at the same time, ignoring both')
    if not a.verbose and not a.quiet:
        logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)
    logger.debug('Parsed arguments')

    if a.optional is not None:
        if not os.path.isdir(a.optional):
            fail_string = str(parser.print_help())
            fail_string = fail_string + '\nDir ' + a.optional + ' doesn\'t exist'
            usage(fail_string)

    required_files = []
    if required_files:
        verify_dependencies(required_files)

    return a


logger = logging.getLogger('optional.log')


def usage(error_message):
    print(__doc__)
    print(error_message)
    exit(1)


def verify_dependencies(list_of_files):
    pass


def main(args):
    args = setup()
    workspace = os.getenv('WORKSPACE')
    if workspace is None:
        workspace = os.getcwd()

    print(workspace)

    return True


if __name__ == "__main__":
    main(sys.argv)

