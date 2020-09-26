
import unittest

import ternary_tree

test "init list":
  var data: seq[TernaryTreeMapKeyValuePair[int, int]] = @[]
  for idx in 0..<10:
    data.add (idx, idx + 10)

  echo initTernaryTreeMap[int, int](data)
  echo initTernaryTreeMap[int, int](data).formatInline
  # check ($initTernaryTreeMap[int, int](data) == "TernaryTreeList[4, 2]")
