
import nimprof

import ternary_tree

var data = initTernaryTreeList[int](@[])
for idx in 0..<8000:
  data = data.append(idx)

for idx in 0..<8000:
  discard data[idx]
