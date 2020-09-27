
import hashes
import options
import strformat
import tables
import unittest

import ternary_tree

test "init list":
  var dict: Table[string, int]
  for idx in 0..<10:
    dict[fmt"{idx}"] = idx + 10

  let data10 = initTernaryTreeMap[string, int](dict)

  echo data10
  echo data10.formatInline

  echo data10.toSortedSeq

  echo data10.contains("1")
  echo data10.contains("11")

  echo data10.get("1")
  echo data10.get("11")

  # check ($initTernaryTreeMap[int, int](data) == "TernaryTreeList[4, 2]")

  # echo hash(1)
  # echo hash(2)
  # echo hash(3)
  # echo hash("1")
  # echo hash("2")
  # echo hash("3")
