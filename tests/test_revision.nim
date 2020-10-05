
import unittest
import options
import strformat

import ternary_tree

test "init list":
  # check ($initTernaryTreeRevision[int](@[1,2,3,4]) == "TernaryTreeList[4, 3]")

  let data = initTernaryTreeRevision[int](@[1,2,3,4,5,6,7,8,9])
  # echo data.formatInline

  check data.get(@[pickLeft]) == some(2)
  check data.len == 9

  check seqToStringPath(@[pickLeft, pickMiddle]) == "d"

  check "asd".stringToSeqPath.seqToStringPath == "asd"
  check "hhch$".stringToSeqPath.seqToStringPath == "hhch$"
  let xs = @[pickLeft, pickLeft, pickMiddle, pickRight, pickLeft, pickMiddle, pickLeft, pickRight]
  check xs.seqToStringPath.stringToSeqPath == xs
  let xs2 = @[pickLeft, pickLeft, pickMiddle, pickRight, pickLeft, pickMiddle, pickLeft]
  check xs2.seqToStringPath.stringToSeqPath == xs2
  let xs3 = @[pickLeft, pickLeft, pickMiddle, pickRight, pickLeft]
  check xs3.seqToStringPath.stringToSeqPath == xs3

  check data.toSeq == @[1, 2, 3, 4, 5, 6, 7, 8, 9]
  check data.keys == @["a", "d", "g", "j", "", "p", "s", "v", "y"]

  check (data.contains("j") == true)
  check (data.contains("k") == false)

  var i = 0
  for k, v in data:
    # echo fmt"=> {k} {v}"
    i = i + 1
  check i == 9

  check data.formatInline == "((a:1 d:2 g:3) (j:4 m:5 p:6) (s:7 v:8 y:9))"
  check data.dissoc("a").formatInline == "((_ d:2 g:3) (j:4 m:5 p:6) (s:7 v:8 y:9))"

  check data.assoc("a", 11).formatInline == "((a:11 d:2 g:3) (j:4 m:5 p:6) (s:7 v:8 y:9))"
  check data.assocBefore("a", 11).formatInline == "((($:11 a:1 _) d:2 g:3) (j:4 m:5 p:6) (s:7 v:8 y:9))"
  check data.assocAfter("a", 11).formatInline == "(((_ a:1 b:11) d:2 g:3) (j:4 m:5 p:6) (s:7 v:8 y:9))"
