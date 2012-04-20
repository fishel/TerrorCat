# This script calculates Spearman's rank correlation coefficients
# using python's scipy module.  It expects files that look like this:
#
#cz-en newssyscombtest2011
#	HUMAN_RANK	BLEU	TER
#cst	0.4690	0.1633	0.6369
#cu-bojar	0.5953	0.1874	0.6359
#cu-zeman	0.4420	0.1397	0.6554
#jhu	0.5711	0.1975	0.6029
#online-B	0.6784	0.2871	0.5232
#systran	0.5142	0.1800	0.6271
#uedin	0.6862	0.2243	0.5949
#uppsala	0.5692	0.2031	0.6153

import scipy
import scipy.stats
import sys

significant_digits = 3

title = sys.stdin.readline()
title = title.rstrip('\n')
metric_names = sys.stdin.readline().split()

metric_scores = {}
for metric in metric_names:
   metric_scores[metric] = []

for line in sys.stdin:
   scores = line.split()
   sysname = scores[0]
   for i in range(1, len(scores)):
      metric_scores[metric_names[i-1]].append(scores[i])

print round(scipy.stats.stats.spearmanr(metric_scores["HUMAN_RANK"], metric_scores["TerrorCat"])[0], significant_digits)
