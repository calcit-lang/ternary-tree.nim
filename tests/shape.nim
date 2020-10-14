
import tables
import strformat

import ternary_tree

proc tryListShape(): void =
  var data = initTernaryTreeList[int](@[])

  for i in 0..<82:
    data = data.append i
    echo data.getDepth, " : ", data.formatInline



proc tryMapShape(): void =
  var dict: Table[string, int]
  var data = initTernaryTreeMap(dict)

  for idx in 0..<30:
    data = data.assoc(fmt"{idx}", idx + 10)
    echo data.formatInline

# tryListShape()

tryMapShape()