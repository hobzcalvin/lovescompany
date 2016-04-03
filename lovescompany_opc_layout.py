#!/usr/bin/env python

spacing = 0.11  # m
lines = []
mod = 0
for c in range(19, -20, -1):
    rs = [range(10), reversed(range(10))][(c+mod) % 2]
    for r in rs:
        lines.append('  {"point": [%.2f, %.2f, %.2f]}' %
                     (c*spacing, 0, (r - 5)*spacing))
    if c % 5 == 0:
        mod += 1
print '[\n' + ',\n'.join(lines) + '\n]'
