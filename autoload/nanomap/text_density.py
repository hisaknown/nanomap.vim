# -*- coding: utf-8 -*-
from __future__ import division
import fileinput
import argparse
import math
import sys

# Set encoding of stdout as utf-8
if sys.version_info.major == 3:
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
else:
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout)


def interp_liner(l, q):
    if q >= len(l) - 1:
        return l[-1]
    if q <= 0:
        return l[0]
    query_lower = int(math.floor(q))
    slope = (l[query_lower + 1] - l[query_lower])
    intercept = l[query_lower] - slope * q
    return slope * q + intercept


parser = argparse.ArgumentParser()
parser.add_argument('files', metavar='FILE', nargs='*',
                    help='files to read, if empty, stdin is used')
parser.add_argument('--n_target_lines', type=int, default='40',
                    help='Number of lines for output.')
parser.add_argument('--encoding', type=str, default='utf-8')
parser.add_argument('--out_type', type=str, choices=['char', 'color'],
                    default='color')
parser.add_argument('--color_bins', type=int, default=255)
args = parser.parse_args()

# MEMO: Following glyphs may be useful:
# ▀
# ▄
# █
# ▌
# ▖
# ▘
# ▙
# ▛

n_char_per_line = []
for line in fileinput.input(files=args.files,
                            openhook=fileinput.hook_encoded(args.encoding)):
    n_char_per_line.append(len(line))
n_lines = len(n_char_per_line)

if n_lines < 2 * args.n_target_lines:
    abstracted_n_chars = n_char_per_line
else:
    abstracted_n_chars = []
    len_abstracted_n_chars = n_lines / (2 * args.n_target_lines)
    for i in range(2 * args.n_target_lines):
        abstracted_n_chars.append(len_abstracted_n_chars
                                  * interp_liner(n_char_per_line,
                                                 i * len_abstracted_n_chars))

res = []

chars_max = max(abstracted_n_chars)
chars_min = min(abstracted_n_chars)
if args.out_type == 'char':
    # Thresholds for character assginment
    chars_one_third = chars_min + int(float(chars_max - chars_min) / 3)
    chars_two_third = chars_min + int(float(chars_max - chars_min) * 2 / 3)

    for pair in [abstracted_n_chars[i:i+2]
                 for i in range(0, len(abstracted_n_chars), 2)]:
        if len(pair) < 2:
            pair.append(0)

        if pair[0] > chars_two_third and pair[1] > chars_two_third:
            res.append(u'█')
        elif pair[0] > chars_two_third and pair[1] > chars_one_third:
            res.append(u'▛')
        elif pair[0] > chars_one_third and pair[1] > chars_two_third:
            res.append(u'▙')
        elif pair[0] > chars_one_third and pair[1] > chars_one_third:
            res.append(u'▌')
        elif pair[0] > chars_two_third:
            res.append(u'▀')
        elif pair[1] > chars_two_third:
            res.append(u'▄')
        elif pair[0] > chars_one_third:
            res.append(u'▘')
        elif pair[1] > chars_one_third:
            res.append(u'▖')
        else:
            res.append(' ')
elif args.out_type == 'color':
    temp_res = []
    for v in abstracted_n_chars:
        color = (v - chars_min) / (chars_max - chars_min)
        color = int(color * (args.color_bins - 1))
        temp_res.append(color)
    for i in range(0, len(temp_res), 2):
        if i == len(temp_res) - 1:
            res.append(u'▀nanomap{0:02d}{1:02d}'.format(
                temp_res[i], 0
            ))
        else:
            res.append(u'▀nanomap{0:02d}{1:02d}'.format(
                temp_res[i], temp_res[i + 1]
            ))
        current_pos = i * (n_lines / (args.n_target_lines * 2))

for r in res:
    print(r)
# import numpy as np
# from matplotlib import pyplot as plt
# plt.imshow(np.array(res)[:, None])
# plt.show()
