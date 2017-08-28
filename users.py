#!/usr/bin/env python

import sys, time, subprocess, yaml, argparse
from pg import DB

CONFIG_PATH = 'config.yml'

with open(CONFIG_PATH, 'r') as ymlfile:
    cfg = yaml.load(ymlfile)
    srcChoice = cfg['src']
    dstChoice = cfg['dst']

parser = argparse.ArgumentParser()
parser.add_argument('--src', help='Source server', dest='src', default=['delta-region','alpha-region'], choices=srcChoice)
parser.add_argument('--dst', help='Destination server', dest='dst', nargs='*', default=['alpha-region', 'beta-region', 'omega-region', 'test-alpha-old-region', 'test-alpha-old-region', 'delta-region','gamma-region', 'test-alpha-etg-region', 'test-alpha-comfy-region', 'test-alpha-cib-region', 'prod-bts_region'], choices=dstChoice)
#parser.add_argument('--dst', help='Destination server', dest='dst', nargs='*', default=['test-sigma'], choices=dstChoice)
args = parser.parse_args()

tables = ["act_id_user", "act_id_group", "act_id_membership"]

upd = {
    "act_id_user": "UPDATE act_id_user SET (rev_, first_, last_, email_, pwd_, picture_id_) = (newvals.rev_, newvals.first_, newvals.last_, newvals.email_, newvals.pwd_, NULL) FROM newvals WHERE newvals.id_ = act_id_user.id_",
    "act_id_group": "UPDATE act_id_group SET (rev_, name_, type_) = (newvals.rev_, newvals.name_, newvals.type_) FROM newvals WHERE newvals.id_ = act_id_group.id_",
    "act_id_membership": "SELECT 1",
}

insert = {
    "act_id_user": "INSERT INTO act_id_user SELECT newvals.id_, newvals.rev_, newvals.first_, newvals.last_, newvals.email_, newvals.pwd_, newvals.picture_id_ FROM newvals LEFT OUTER JOIN act_id_user ON (act_id_user.id_ = newvals.id_) WHERE act_id_user.id_ IS NULL",
    "act_id_group": "INSERT INTO act_id_group SELECT newvals.id_, newvals.rev_, newvals.name_, newvals.type_ FROM newvals LEFT OUTER JOIN act_id_group ON (act_id_group.id_ = newvals.id_) WHERE act_id_group.id_ IS NULL",
    "act_id_membership": "INSERT INTO act_id_membership SELECT newvals.user_id_, newvals.group_id_ FROM newvals LEFT OUTER JOIN act_id_membership ON (act_id_membership.user_id_ = newvals.user_id_) AND (act_id_membership.group_id_ = newvals.group_id_) WHERE act_id_membership.user_id_ IS NULL",
}



src = cfg[args.src]

print("")
print("------------------------------------------------------------------------------------")
print("Source: " + str(args.src))
print("------------------------------------------------------------------------------------")

srcdb = DB(dbname=src["db"], host=src["host"], port=int(src["port"]), user=src["user"], passwd=src["password"])

for srv in args.dst:
    item = cfg[srv]
    print("")
    print("------------------------------------------------------------------------------------")
    print("Destination: " + str(srv))
    print("------------------------------------------------------------------------------------")
    dstdb = DB(dbname=item["db"], host=item["host"], port=int(item["port"]), user=item["user"], passwd=item["password"])

    for table in tables:
        dstdb.start()
        rows = srcdb.query('SELECT * FROM %s' % table).getresult()
        dstdb.query('CREATE TEMPORARY TABLE newvals ON COMMIT DROP AS TABLE %s WITH NO DATA' % table)
        dstdb.inserttable('newvals', rows)
        dstdb.query('LOCK TABLE %s IN EXCLUSIVE MODE' % table)
        print(upd.get(table))
        dstdb.query(upd.get(table))
        print(insert.get(table))
        dstdb.query(insert.get(table))
        dstdb.commit()


