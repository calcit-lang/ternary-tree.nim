
import nimprof
import tables
import strformat
import algorithm
import hashes
import times

import ternary_tree

let n = 10000

proc testList(): void =
  var data = initTernaryTreeList[int](@[])
  for idx in 0..<n:
    data = data.append(idx)

  for y in 0..<100:
    for idx in 0..<n:
      discard data[idx]

    for item in data:
      discard item

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


let t1 = now()

# testMap()
testList()

let t2 = now()
echo "Costs: ", t2 - t1
