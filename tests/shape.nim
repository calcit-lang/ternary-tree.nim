
import random
import tables
import strformat

import ternary_tree

randomize()

proc tryListShape(): void =
  var source: seq[int] = @[]
  var data = initTernaryTreeList[int](@[0])

  for i in 0..<18:
    source.add i

  data = initTernaryTreeList(source)

  for i in 0..<18:
    # echo data.formatInline
    let newData = data.assocAfter(i, 888)
    echo newData.getDepth, " : ", newData.formatInline

  # data.forceInplaceBalancing
  # echo data.getDepth, " : ", data.formatInline


proc tryMapShape(): void =
  var dict: Table[string, int]
  var data = initTernaryTreeMap(dict)

  for idx in 0..<20:
    data = data.assoc(fmt"x{idx}", idx + 10)
    echo data.formatInline()
    # echo "checked: ", data.checkStructure()

proc tryConcatList(): void =
  let a = initTernaryTreeList(@[1,2,3,4])
  let b = initTernaryTreeList(@[5,6,7,8])
  let c = initTernaryTreeList(@[9,10,11,12])

  echo a.formatInline
  echo b.formatInline
  echo c.formatInline
  echo a.concat(b).formatInline
  echo a.concat(b).concat(c).formatInline

  let d = a.concat(b)
  d.forceInplaceBalancing

  echo d.formatInline

  for i in 0..<8:
    for j in i..<9:
      echo fmt"{i}-{j} ", d.slice(i, j).formatInline

# tryListShape()

# tryMapShape()

tryConcatList()
