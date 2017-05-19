"""a tool to return starview+ squish tests
"""
#before running any imports, check if the build dir exists
#give the user an ability to define the import location, verify that import location
import argparse
import os
import sys

class ValidateWorkspace(argparse.Action):
    def __init__(self, option_strings, dest, nargs=None, **kwargs):
        if nargs is not None:
            raise ValueError('cannot use nargs for this type of argument in argparser')
        super(ValidateWorkspace, self).__init__(option_strings, dest, **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        #print('%r %r %r' % (namespace, values, option_string))
        setattr(namespace, self.dest, set_workspace(values))

    def set_workspace(self,input_dir=None):
        if input_dir is not None:
            return input_dir

        if 'WORKSPACE' in os.environ:
            return os.environ['WORKSPACE']

        return self.walk_workspace(os.path.abspath(os.path.dirname(sys.argv[0])))

    def walk_workspace(self, input_dir)
        parent = os.path.abspath(os.path.join(input_dir, os.pardir))

        if parent == input_dir:
            return os.cwd

        if os.path.isdir(os.path.join(input_dir, '.git')):
            return parent
        else:
            return self.walk_workspace(parent)

def setup():
    #deliberately restricting to one module at this time
    parser = argparse.ArgumentParser(description='to search for suites which match the input')
    parser.add_argument('-l', '--list', nargs='*', required=True,
                        help='all the files to look in')
    parser.add_argument('-m', '--match', required=True,
                        help='return the list of suites which match this arg')
    parser.add_argument('-w', '--workspace', action=ValidateWorkspace, required=False,
                        help='define a workspace, if not defined by the environment')
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


    #assume here that we're getting a legitimate version
    #add the version check into common functions, and replace this block

    #if WORKSPACE = ""
    #  find the WORKSPACE, needs a common function
    #fi
    #cd WORKSPACE

    #check if the STAR-View+ installation exists
    #if not (os.path.isfile(a.starviewhome + '/bin/' + starview_exe)):
    #    logger.error('No STAR-View+ executable at ' + a.starviewhome + '/bin/' + starview_exe)
    #    sys.exit(1)
    #global starviewhome
    #starviewhome = a.starviewhome + '/bin'

    #if not (os.path.isdir(test_module_dir + '/' + a.module)):
    #    logger.error('The specified module "' + a.module + '" doesn\'t exist at ' + test_module_dir)
    #    sys.exit(1)
    #global module
    #module = a.module

    #check that the squish_dir exists!!!
    #if not (os.path.isdir(squish_dir)):
    #    logger.error('There is no squish installation at ' + squish_dir )
    #    sys.exit(1)

    return a

def main(args):
    args = setup()
    print(args.workspace)

