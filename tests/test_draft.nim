
import unittest
import options
import strformat

import ternary_tree

test "init list":
  # check ($initTernaryTreeDraft[int](@[1,2,3,4]) == "TernaryTreeList[4, 3]")

  let data = initTernaryTreeDraft[int](@[1,2,3,4,5,7,8,9])

  echo data
  echo data.get(@[pickLeft])
  echo data.len

  echo seqToStringPath(@[pickLeft, pickMiddle])

  check "asd".stringToSeqPath.seqToStringPath == "asd"
  check "hhch$".stringToSeqPath.seqToStringPath == "hhch$"
  let xs = @[pickLeft, pickLeft, pickMiddle, pickRight, pickLeft, pickMiddle, pickLeft, pickRight]
  check xs.seqToStringPath.stringToSeqPath == xs
  let xs2 = @[pickLeft, pickLeft, pickMiddle, pickRight, pickLeft, pickMiddle, pickLeft]
  check xs2.seqToStringPath.stringToSeqPath == xs2
  let xs3 = @[pickLeft, pickLeft, pickMiddle, pickRight, pickLeft]
  check xs3.seqToStringPath.stringToSeqPath == xs3

  echo data.toSeq
  echo data.keys

  for k, v in data:
    echo fmt"=> {k} {v}"

  echo data.formatInline
  echo data.dissoc("a").formatInline

  echo data.assoc("a", 11).formatInline
  echo data.assocBefore("a", 11).formatInline
  echo data.assocAfter("a", 11).formatInline
