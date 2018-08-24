#!/usr/bin/env xonsh

import os
import datetime

from pathlib import Path
from os.path import join, dirname

from dotenv import load_dotenv

dotenv_path = join(dirname(__file__), '.env')
load_dotenv(dotenv_path)

NEOLOGD_PATH = os.environ.get('NEOLOGD_PATH')
p = Path(NEOLOGD_PATH + '/seed')
seed = list(p.glob('mecab-user-dict-seed.*.csv.xz'))[0]

DIFF_PATH = os.environ.get('DIFF_PATH')
cp @(str(seed)) @(DIFF_PATH + 'diff_from.csv.xz')
xz -dv @(DIFF_PATH + 'diff_from.csv.xz')

cd @(NEOLOGD_PATH)
./bin/install-mecab-ipadic-neologd -n

seed = list(p.glob('mecab-user-dict-seed.*.csv.xz'))[0]
cp @(str(seed)) @(DIFF_PATH + 'diff_to.csv.xz')
xz -dv @(DIFF_PATH + 'diff_to.csv.xz')

cd @(DIFF_PATH)
diff diff_from.csv diff_to.csv > diff.txt

line_put = []
line_delete = []
line_edit = []
with open(DIFF_PATH + 'diff.txt') as f:
    for row in f:
        k = row.split(',')[0]
        if row.startswith('< '):
            line_delete.append(k)
        if row.startswith('> '):
            line_put.append(k)
        if row.startswith('| '):
            line_edit.append(k)

echo delete @(str(len(line_delete)))
echo put @(str(len(line_put)))
echo edit @(str(len(line_edit)))

now = datetime.datetime.now()
f = open(DIFF_PATH + 'neologd_diff_summary_{0:%Y%m%d}.txt'.format(now), 'w')
for l in line_delete:
    f.write(l)
    f.write('\n')
for l in line_put:
    f.write(l)
    f.write('\n')
for l in line_edit:
    f.write(l)
    f.write('\n')
f.close()

rm @(DIFF_PATH + 'diff_from.csv')
rm @(DIFF_PATH + 'diff_to.csv')
rm @(DIFF_PATH + 'diff.txt')
