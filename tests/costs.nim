
import nimprof
import tables
import strformat
import algorithm
import hashes
import times

import ternary_tree

let n = 2000

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
  var data10 = initTernaryTreeMap[string, int](dict)

  for idx in 0..<n:
    data10 = data10.assoc($idx, idx + 10)

  for y in 0..<40:
    for idx in 0..<n:
      discard data10[$idx]

  echo data10.getDepth
  data10.forceInplaceBalancing
  echo data10.getDepth

proc testMapMerge(): void =
  var dict: Table[string, int]
  var data10 = initTernaryTreeMap[string, int](dict)
  var data11 = initTernaryTreeMap[string, int](dict)

  for idx in 0..<n:
    data10 = data10.assoc($idx, idx + 10)

  for idx in 0..<n:
    data11 = data10.assoc( "x" & $idx, idx + 11)

  for y in 0..<20:
    discard data10.merge(data11)

let t1 = now()

testMap()
# testList()
# testMapMerge()

let t2 = now()
echo "Costs: ", t2 - t1
