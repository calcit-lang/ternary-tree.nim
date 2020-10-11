
import nimprof
import tables
import strformat
import algorithm
import hashes

import ternary_tree

proc testList(): void =
  var data = initTernaryTreeList[int](@[])
  for idx in 0..<8000:
    data = data.append(idx)

  for idx in 0..<8000:
    discard data[idx]

proc testMap(): void =
  var dict: Table[string, int]
  for idx in 0..<100:
    dict[fmt"{idx}"] = idx + 10

  var data10 = initTernaryTreeMap[string, int](dict)
  for idx in 0..<10000:
    data10 = data10.assoc(fmt"{idx}", idx + 10)

  echo data10.getDepth
  data10.forceInplaceBalancing
  echo data10.getDepth


testMap()
