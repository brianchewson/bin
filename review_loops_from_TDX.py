import argparse
#import jenkinsapi WASN'T WORKING AS OF 7/19/16 4:35 PM proceeding with requests (can't see http://starci.lebanon.cd-adapco.com:9090/api/python)
# open the notes_for_backward_fail_finder.txt in the ~/bin dir
import datetime
import json
import logging
import os
import requests
import subprocess
import sys
import xml.etree.ElementTree as etree

sys.path.append(os.getcwd())
sys.path.insert(0,'/home/brianh/gits/build/admin/tools/ProductionCoverage/')

import suites_to_run_from_TDX as startest



logging.basicConfig(level=logging.INFO)
logging.getLogger("requests").setLevel(logging.WARNING)
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
configuration_file=os.path.dirname(os.path.realpath(__file__)) + '/.my.cnf'
now = datetime.datetime.now()


def execute_sql(sql_cnf_file, sql_server, sql_db, sql_query):
    cmd=['mysql', '--defaults-file=' + sql_cnf_file, '-h', sql_server, '-D', sql_db, '-Bse', sql_query]
    proc = subprocess.Popen(cmd,stdout=subprocess.PIPE)
    retval = proc.communicate()[0]
    retval = retval.decode()
    return(retval)


def find_jira(module, suite, message):
    ret_val = 'open a jira'
    jira_query_url = 'http://jira.cd-adapco.com/rest/api/2/search?jql=%20text%20~%20%22' + module + '.' + suite +\
          '"%20AND%20resolution%20%3D%20Unresolved'
    jira_query_response = url_request(jira_query_url)
    jira_query_json = json.loads(jira_query_response.text)
    if jira_query_json:
        for issue in jira_query_json['issues']:
            jira_id = issue.get('key')
            if message in issue['fields']['description']:
                ret_val = jira_id
                break

    return ret_val


def get_all_backward_jobs(server):
    ret_val = []
    job_name_url = server + '/api/xml?tree=jobs[name]'
    jobs_response = url_request(job_name_url)
    jobs_xml = etree.fromstring(jobs_response.text)
    for job in jobs_xml.findall('job'):
        for name in job.findall('name'):
            job_name = name.text
            if job_name.startswith('dev_test'):
                if 'backward' in job_name or 'bkwd' in job_name:
                    ret_val.append(job_name)

    ret_val.sort()
    return ret_val


def get_backward_home(job_name, server):
    backward_home_url = server + '/job/' + job_name + '/config.xml'
    backward_home_response = url_request(backward_home_url)
    backward_home = backward_home_response.text
    if 'archives' in backward_home:
        return 'dev'
    else:
        return 'rel'


def get_cycle(job_name, server):
    cycle_url = server + '/job/' + job_name + '/lastSuccessfulBuild/artifact/cycle.properties/*view*/'
    cycle_repsonse = url_request(cycle_url)
    cycle_properties = cycle_repsonse.text
    ret_val = cycle_properties.split('=', 1)[1]
    return ret_val


def get_tdx_args(job_name):
    if '_lin64' in job_name:
        args_arch = 'linux-x86_64-2.5'
        args_cplr = 'gnu4.8'
    else:
        args_arch = 'win64'
        args_cplr = 'intel15.0'

    if '-r8' in job_name:
        args_cplrprec = 'r8'
    else:
        args_cplrprec = 'r4'

    if '_np' in job_name:
        args_np = '!= 0'
    else:
        args_np = '= 0'
    return args_arch, args_cplr, args_cplrprec, args_np


def get_current_version(job_name, server):
    version_url = server + '/job/' + job_name + '/lastBuild/api/xml?tree=actions[parameters[name,value]]'
    version_response = url_request(version_url)
    version_xml = etree.fromstring(version_response.text)

    for parameter in version_xml.iter('parameter'):
        name = parameter.find('name').text
        value = parameter.find('value').text
        if name == 'VERSION':
            return value


def get_tmg(job_name, server):
    ret_val = ''
    tmg_url = server + '/job/' + job_name + '/config.xml'
    tmg_response = url_request(tmg_url)
    tmg_text = tmg_response.text
    tmg_split = tmg_text.split('CONFIG=')[1]
    ret_val = tmg_split.split()[0]
    return ret_val


def get_results(job_name, tmg, version):
    arch, cplr, cplrprec, np = get_tdx_args(job_name)
    version_split = version.split('.')
    major = version_split[0]
    minor = version_split[1]
    patch = version_split[2]

    query = make_query(arch, cplr, cplrprec, np, tmg, major, minor, patch)
    database_return = execute_sql(configuration_file, 'tdx02', 'cdna', query)
    return database_return


def get_suite_attributes(module, suite, version):
    # try to glean group information from java file
    # try to glean server data from java file
    # this is dumb, why would you do this? Ask the database
    query_opts = []
    query_opts.extend(['-m', module, '-a', suite, '-p', 'o', '-v', version, '-mode', 'rs~irs'])
    suite_result = startest.main(query_opts)
    logger.debug('get_configured_suites: python suites_to_run_from_TDX.py ' + ' '.join(query_opts))

    suite_json = suite_result[0]
    groups = suite_json['groups']
    server_mode = suite_json['server_mode']
#     groups = suite_result['groups']
#     server_mode = suite_result['server_mode']

    return groups, server_mode


def get_suite_history(module, suite, branch, version):
    # trying to determine the age of the suite for rel sims (Released from sandbox in the Major.minor won't have rel sims)
    # trying to determine the age of the suite for dev sims (less than five days old, may not have any sims yet)

    release = version.rsplit('.', 1)[0]
    age_url = 'http://gitweb.lebanon.cd-adapco.com/?p=startest.git;a=atom;f=' + module + '/test/unit/src/' +\
              module + '/' + suite + 'Test.java'

    age_response = url_request(age_url)
    age_xml = etree.fromstring(age_response.text)

    xml = '{http://www.w3.org/2005/Atom}'
    xml_entry = xml + 'entry'
    xml_title = xml + 'title'
    xml_updated = xml + 'updated'

    if branch == 'rel':
        for entry in age_xml.findall(xml_entry):
            title = entry.find(xml_title)
            title = title.text
            if ('andbox' in title) and (release in title):
                ret_val = 'New for' + release
            else:
                ret_val = 'Requires Investigation'
    elif branch == 'dev':
        entry = age_xml.find(xml_entry)
        update = entry.find(xml_updated)
        update = update.text
        update = datetime.datetime.strptime(update, '%Y-%m-%dT%H:%M:%SZ')
        age = now - update
        if age.days < 5:
            hours = age.seconds / 3600
            ret_val = 'Too new for any sim files ' + age.days + ' days ' + hours + ' hours'
        else:
            ret_val = 'Requires Investigation'

    return ret_val


def is_building(job_name, server):
    building_url = server + '/job/' + job_name + '/lastBuild/api/xml?tree=building'
    building_response = url_request(building_url)
    building_text = building_response.text
    if '>true<' in building_text:
        return True
    else:
        return False


def in_queue(job_name, server):
    job_queue_url = server + '/job/' + job_name + '/api/xml?tree=inQueue'
    job_queue_response = url_request(job_queue_url)
    job_queue_text = job_queue_response.text
    if '>true<' in job_queue_text:
        return True
    else:
        return False


def make_query(q_arch, q_cplr, q_cplrprec, q_np, q_tmg, q_major, q_minor, q_patch):
        return '''SELECT M.Name AS Module,
           S.Name AS Suite,
           Test.Name AS TestCase,
           tc.Message AS Details
    FROM
        TestSuiteResult AS tsr
        JOIN
        Suite AS S ON (S.SuiteID = tsr.SuiteID_FK)
        JOIN
        ModuleResult AS mr ON (mr.ModuleResultID = tsr.ModuleResultID_FK)
        JOIN
        Module AS M ON (M.ModuleID = mr.ModuleID_FK)
        JOIN
        Config AS cfg ON (cfg.ConfigID = mr.ConfigID_FK)
        JOIN
        ProductVersion AS pv ON (pv.ProductVersionID = cfg.ProductVersionID_FK)
        JOIN
        Architecture AS arch ON (arch.ArchitectureID = cfg.ArchitectureID_FK)
        JOIN
        Compiler AS cplr ON (cplr.CompilerID = cfg.CompilerID_FK)
        JOIN
        CompilerPrecision AS cplrprec ON (cplrprec.CompilerPrecisionID = cfg.CompilerPrecisionID_FK)
        JOIN
        TestManagementGroup AS tmg ON (tmg.TestManagementGroupID = cfg.TestManagementGroupID_FK)
        JOIN
        TestCase AS tc ON (tsr.TestResultID = tc.TestResultID_FK)
        JOIN
        Test ON (Test.TestID = tc.TestID_FK)
    WHERE
        tsr.TestFail > 0
        AND
        tc.Message IS NOT NULL
        AND
        arch.Name = \'''' + q_arch + '''\'
        AND
        cplr.Name = \'''' + q_cplr + '''\'
        AND
        cplrprec.Name = \'''' + q_cplrprec + '''\'
        AND
        cfg.Np ''' + q_np + '''
        AND
        tmg.Name = \'''' + q_tmg + '''\'
        AND
        pv.Major = ''' + q_major + '''
        AND
        pv.Minor = ''' + q_minor + '''
        AND
        pv.Patch = ''' + q_patch + '''
    ;'''


def url_request(url):
    if 'starci' in url:
        auth_token = ('test', '88257d321f7afe0920bfc9ac894073b1')
    elif ('jira' in url) or ('gitweb' in url):
        auth_token = ('test', 'test')

    try:
        ret_val = requests.request("GET", url, auth=auth_token)
    except requests.exceptions.ConnectionError:
        print('A Connection error occurred. Could not connect to ' + url)
        exit(1)
    except requests.exceptions.ConnectTimeout:
        print('The request timed out while trying to connect to the remote server. Could not connect to ' + url)
        exit(1)
    except requests.exceptions.HTTPError:
        print('An HTTP error occurred. Could not connect to ' + url)
        exit(1)
    except requests.exceptions.ReadTimeout:
        print('The server did not send any data in the allotted amount of time. Could not connect to ' + url)
        exit(1)
    except requests.exceptions.TooManyRedirects:
        print('Too many redirects. Could not connect to ' + url)
        exit(1)
    except requests.exceptions.URLRequired:
        print('A valid URL is required to make a request. Could not connect to ' + url)
        exit(1)
    except requests.exceptions.RequestException:
        print('There was an ambiguous exception that occurred while handling your request. Could not connect to ' + url)
        exit(1)
    except:
        print('Unknown error. Could not connect to ' + url)
        exit(1)

    return ret_val


def main(job_name, server):
    current_version = get_current_version('dev_tag_startest', server)
    if job_name == 'EMPTY':
        job_list = get_all_backward_jobs(server)
    else:
        job_list = [job_name]

    for job in job_list:
        job_version = get_current_version(job, server)
        job_is_building = is_building(job, server)
        if current_version == job_version and job_is_building:
            logger.info(job + ' is still running against ' + job_version)
        elif current_version != job_version and job_is_building:
            logger.warning(job + ' is running against ' + job_version)
        elif current_version != job_version and not job_is_building:
            # assume that the build isn't supposed to happen, unless the job is in the queue
            if in_queue(job, server):
                logger.info(job + ' is in the queue to build ' + current_version)
        elif current_version == job_version and not job_is_building:
            job_cycle = get_cycle(job, server)
            job_bkwd_home = get_backward_home(job, server)
            if job.endswith('_np'):
                job_serial = 'parallel'
            else:
                job_serial = 'serial'
            tmg = get_tmg(job, server)
            # results = get_results(job, tmg, job_version)
            print(job_version + '\t' + job)
            results = get_results(job, tmg, job_version)
            if not results:
                print('100% pass\t100% pass\t100% pass\t100% pass\t100% pass')
            else:
                # process results
                # here I imagine that based on job name we could interpret the results in different ways (ie bkwd vs vrf)
                unique_results = []
                jira_results = []
                for result in results.split('\n'):
                    # get only lines that had data (TDX is returning an empty line at the end of the query)
                    if result:
                        # get unique failures (consists of module/suite/message)
                        result_split = result.split('\t')
                        result_module = result_split[0]
                        result_suite = result_split[1]
                        result_case = result_split[2]
                        result_message = result_split[3]

                        if 'No backward compatibility files found' in result_message:
                            result_message = 'No backward compatibility files found'
                        else:
                            result_message = result_message.replace('junit.framework.AssertionFailedError: ', '')
                            if result_message.startswith('Server process exited with code'):
                                # use the first 36 characters, because that's the length of the above message plus the exit code
                                result_message = result_message[0:36]
                            elif 'Neo.Error' in result_message:
                                result_message = 'file not found'
                            elif 'Command:' in result_message:
                                result_message = result_message.split('Command:', 1)[0]
                                message_split = result_message.split('[', 1)
                                if len(message_split) > 1:
                                    result_message = message_split[1]
                            else:
                                result_message = 'I can\'t parse: ' + result_message

                        result_line = '\t'.join([result_module, result_suite, result_message])

                        if result_line not in unique_results:
                            unique_results.append(result_line)

                for result in unique_results:
                    # get the jira issues for the unique failures (helps cut down on Jira queries)
                    result_split = result.split('\t')
                    result_module = result_split[0]
                    result_suite = result_split[1]
                    result_message = result_split[2]
                    result_message = result_message.strip()

                    if 'file not found' in result_message:
                        jira = ''
                        action = 'regular deletion of sim files [de-dupe]'
                    elif 'No backward compatibility files found' not in result_message:
                        jira = find_jira(result_module, result_suite, result_message)
                        action = ''
                    else:
                        jira = 'none'
                        # use job_cycle, job_bkwd_home, and job_serial to handle some special cases when backward
                        #     doesn't have any sim files
                        # for the suite (get the suite history, and a blob of the file)
                        #              is it too new to have any sim files (dev sims, history suite < 5 days old/released from sandbox in the last five days)
                        #              new for the build cycle (rel sims, suite history has release from sandbox and MAJ.MIN
                        #              Only has release sims (dev sims, no dev sims available, only rel sims)
                        #              STARTEST-244 (serial, blob says server.serial, group.tutorials)
                        #                           (parallel, blob says server.parallel,
                        #                                                group.largetutorials,
                        #                                                group.largecase,
                        #                                                group.reactinglong,
                        #                                                group.speed)
                        suite_age = get_suite_history(result_module, result_suite, job_bkwd_home, current_version)
                        suite_group, suite_server = get_suite_attributes(result_module, result_suite, current_version)
                        suite_sim_files = get_sim_files(result_module, result_suite)

                        action = 'Requires investigation'

                    result_line = '\t'.join([result_module, result_suite, result_message, jira, action])
                    jira_results.append(result_line)

                # TODO: add  a process to cram suites in the same module, with the rest of the line the same together

                for result in jira_results:
                    print(result)



            print('')



if __name__ == "__main__":
    arg_parser = argparse.ArgumentParser(description='Check on the status of the backward compatibility loops, and ' +
                                         'fetch the TDX data if the test is complete')
    arg_parser.add_argument('-j', '--jobname', type=str, default='EMPTY', help='the jenkins job name')
    arg_parser.add_argument('-u', '--url', type=str, help='the jenkins server url',
                            default='http://starci.lebanon.cd-adapco.com:9090')
    args = arg_parser.parse_args()

    if args.jobname == '':
            print('No JOB NAME supplied')
            exit(1)

    # need to make an argument that accepts a version (in case you don't want to do the current version)
    # need to make an argument that accepts a job (in case you don't want to get info on all jobs) or maybe take a TMG

    main(args.jobname, args.url)
