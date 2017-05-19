#!/usr/bin/env python3

"""
FIND A WAY TO GET THE FILENAME INTO THE FIRST SPOT
sys.argv[0] is a tool to 
"""

import argparse
import logging
import os
import sys
import time

def get_workspace(input_dir):
    logger.debug('Determining workspace')
    if input_dir is None:
        logger.debug('Trying to find workspace without input_dir')
    else:
        logger.debug('Setting workspace to ' + input_dir)
        return input_dir

    if 'WORKSPACE' in os.environ:
        return os.environ['WORKSPACE']

    if input_dir is None:
        this_dir = os.path.abspath(os.path.dirname(sys.argv[0]))
    else:
        this_dir = input_dir

    parent = os.path.abspath(os.path.join(this_dir, os.pardir))

    if parent == this_dir:
        # We are already at the filesystem root - no parent
        error_exit('Error in determining workspace - exiting')
    if os.path.isdir(os.path.join(this_dir, '.git')):
        return parent
    else:
        return get_workspace(parent)

def setup():
    parser = argparse.ArgumentParser(description='a tool to ')
    parser.add_argument('-o', '--optional', nargs='*', required=False,
                        help='this is what -o does')
    parser.add_argument('-w', '--workspace', required=False, help='define a workspace')
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

    a.workspace = get_workspace(a.workspace)
    return(a)

    
logger = logging.getLogger('optional.log')

def main(args):
    args = setup()
    startTime = time.time()
    itemOneTime = time.time() - startTime
    print('It took ', itemOneTime, ' seconds to ____')

    totalTime = time.time() - startTime
    print('It took ', totalTime, ' seconds total')
	
    processTime = totalTime - itemOneTime
    print('It took ', processTime, ' seconds to process _____')

    print('Workspace = ' + args.workspace)
    return True #Sucess




#put Classes here...





def usage():
    print(__doc__)

#see http://stackoverflow.com/questions/4041238/why-use-def-main for info I think this is returning zero or one for True/False
if __name__ == "__main__":
    sys.exit(not main(sys.argv))
