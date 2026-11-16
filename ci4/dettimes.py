"""Adds one DETTIMES line (all ten detect() run times, in ms) to the sample's
integration_test/detector_bundled_test.dart, next to its DETBUNDLED line, which
reports only the last frame. Same edit for every variant; nothing else changes."""
import sys

p = sys.argv[1]
s = open(p).read()
anchor = '    await tester.runAsync(detector.close);\n'
line = ("    debugPrint('DETTIMES ${[for (final f in frames) "
        "(f.runMicros / 1000).toStringAsFixed(1)].join(' ')}');\n")
assert s.count(anchor) == 1 and 'DETTIMES' not in s
open(p, 'w').write(s.replace(anchor, anchor + line, 1))
print(f'added DETTIMES to {p}')
