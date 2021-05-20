# executenotebook.py
#!/usr/bin/python3
import json
import requests
import os
import sys
import getopt
import time

def main():
    shard = ''
    token = ''
    clusterid = ''
    localpath = ''
    workspacepath = ''
    outfilepath = ''

    try:
        opts, args = getopt.getopt(sys.argv[1:], 'hs:t:c:lwo',
                                   ['shard=', 'token=', 'clusterid=', 'localpath=', 'workspacepath=', 'outfilepath='])
    except getopt.GetoptError:
        print(
            'executenotebook.py -s <shard> -t <token>  -c <clusterid> -l <localpath> -w <workspacepath> -o <outfilepath>)')
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print(
                'executenotebook.py -s <shard> -t <token> -c <clusterid> -l <localpath> -w <workspacepath> -o <outfilepath>')
            sys.exit()
        elif opt in ('-s', '--shard'):
            shard = arg
        elif opt in ('-t', '--token'):
            token = arg
        elif opt in ('-c', '--clusterid'):
            clusterid = arg
        elif opt in ('-l', '--localpath'):
            localpath = arg
        elif opt in ('-w', '--workspacepath'):
            workspacepath = arg
        elif opt in ('-o', '--outfilepath'):
            outfilepath = arg

    print('-s is ' + shard)
    print('-t is ' + token)
    print('-c is ' + clusterid)
    print('-l is ' + localpath)
    print('-w is ' + workspacepath)
    print('-o is ' + outfilepath)
    # Generate array from walking local path

    notebooks = []
    for path, subdirs, files in os.walk(localpath):
        for name in files:
            fullpath = path + '/' + name
            # removes localpath to repo but keeps workspace path
            fullworkspacepath = workspacepath + path.replace(localpath, '')

            name, file_extension = os.path.splitext(fullpath)
            if file_extension.lower() in ['.scala', '.sql', '.r', '.py']:
                row = [fullpath, fullworkspacepath, 1]
                notebooks.append(row)

    # run each element in array
    for notebook in notebooks:
        nameonly = os.path.basename(notebook[0])
        workspacepath = notebook[1]

        name, file_extension = os.path.splitext(nameonly)

        # workpath removes extension
        fullworkspacepath = workspacepath + '/' + name

        print('Running job for:' + fullworkspacepath)
        values = {'run_name': name,
            'existing_cluster_id': clusterid,
            'timeout_seconds': 3600,
            'notebook_task': {'notebook_path': fullworkspacepath}
        }

        resp = requests.post(shard + '/api/2.0/jobs/runs/submit',
                             headers={'Authorization': 'Bearer %s' % token},
                             json=values)

        runjson = resp.text
        print("runjson:" + runjson)
        d = json.loads(runjson)
        runid = d['run_id']

        i=0
        waiting = True
        while waiting:
            time.sleep(10)
            jobresp = requests.get(shard + '/api/2.0/jobs/runs/get?run_id='+str(runid),
                                   headers={'Authorization': 'Bearer %s' % token},
                                   json=values)
            jobjson = jobresp.text
            print("jobjson:" + jobjson)
            j = json.loads(jobjson)
            current_state = j['state']['life_cycle_state']
            runid = j['run_id']
            if current_state in ['TERMINATED', 'INTERNAL_ERROR', 'SKIPPED'] or i >= 12:
                break
            i=i+1

        if outfilepath != '':
            file = open(outfilepath + '/' +  str(runid) + '.json', 'w')
            file.write(json.dumps(j))
            file.close()

if __name__ == '__main__':
    main()