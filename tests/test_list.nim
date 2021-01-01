
import unittest
import algorithm

import ternary_tree

test "init list":
  check ($initTernaryTreeList[int](@[1,2,3,4]) == "TernaryTreeList[4, ...]")

  let origin11 = @[1,2,3,4,5,6,7,8,9,10,11]
  let data11 = initTernaryTreeList[int](origin11)

  check data11.checkStructure

  check (data11.formatInline == "((1 (2 _ 3) 4) (5 6 7) (8 (9 _ 10) 11))")
  check (origin11 == data11.toSeq)

  let emptyXs = newSeq[int](0)
  check initTernaryTreeList[int]() == initTernaryTreeList(emptyXs)

test "list operations":
  let origin11 = @[1,2,3,4,5,6,7,8,9,10,11]
  let data11 = initTernaryTreeList[int](origin11)

  # get
  for idx in 0..<origin11.len:
    check (origin11[idx] == data11.loopGet(idx))
    check (origin11[idx] == data11[idx])

  check (data11.first == 1)
  check (data11.last == 11)

  # assoc
  let origin5 = @[1,2,3,4,5]
  let data5 = initTernaryTreeList(origin5)
  let updated = data5.assoc(3, 10)
  check (updated.loopGet(3) == 10)
  check (data5.loopGet(3) == 4)
  check (updated.len == data5.len)

  for idx in 0..<data5.len:
    # echo data5.dissoc(idx).formatInline
    check data5.dissoc(idx).len == (data5.len - 1)

  check data5.formatInline == "((1 _ 2) 3 (4 _ 5))"
  check data5.dissoc(0).formatInline == "(2 3 (4 _ 5))"
  check data5.dissoc(1).formatInline == "(1 3 (4 _ 5))"
  check data5.dissoc(2).formatInline == "((1 _ 2) _ (4 _ 5))"
  check data5.dissoc(3).formatInline == "((1 _ 2) 3 5)"
  check data5.dissoc(4).formatInline == "((1 _ 2) 3 4)"

  check initTernaryTreeList(@[1]).rest.formatInline == "(_ _ _)"
  check initTernaryTreeList(@[1,2]).rest.formatInline == "2"
  check initTernaryTreeList(@[1,2,3]).rest.formatInline == "(_ 2 3)"
  check initTernaryTreeList(@[1,2,3,4]).rest.formatInline == "(_ (2 _ 3) 4)"
  check initTernaryTreeList(@[1,2,3,4,5]).rest.formatInline == "(2 3 (4 _ 5))"

  check initTernaryTreeList(@[1]).butlast.formatInline == "(_ _ _)"
  check initTernaryTreeList(@[1,2]).butlast.formatInline == "1"
  check initTernaryTreeList(@[1,2,3]).butlast.formatInline == "(1 2 _)"
  check initTernaryTreeList(@[1,2,3,4]).butlast.formatInline == "(1 (2 _ 3) _)"
  check initTernaryTreeList(@[1,2,3,4,5]).butlast.formatInline == "((1 _ 2) 3 4)"

test "list insertions":
  let origin5 = @[1,2,3,4,5]
  let data5 = initTernaryTreeList(origin5)

  check data5.formatInline == "((1 _ 2) 3 (4 _ 5))"

  check data5.insert(0, 10, false).formatInline == "(_ 10 ((1 _ 2) 3 (4 _ 5)))"
  check data5.insert(0, 10, true).formatInline  == "((1 10 2) 3 (4 _ 5))"
  check data5.insert(1, 10, false).formatInline == "((1 10 2) 3 (4 _ 5))"
  check data5.insert(1, 10, true).formatInline  == "((1 2 10) 3 (4 _ 5))"
  check data5.insert(2, 10, false).formatInline == "((1 _ 2) (_ 10 3) (4 _ 5))"
  check data5.insert(2, 10, true).formatInline  == "((1 _ 2) (3 10 _) (4 _ 5))"
  check data5.insert(3, 10, false).formatInline == "((1 _ 2) 3 (10 4 5))"
  check data5.insert(3, 10, true).formatInline  == "((1 _ 2) 3 (4 10 5))"
  check data5.insert(4, 10, false).formatInline == "((1 _ 2) 3 (4 10 5))"
  check data5.insert(4, 10, true).formatInline  == "(((1 _ 2) 3 (4 _ 5)) 10 _)"

  let origin4 = @[1,2,3,4]
  let data4 = initTernaryTreeList(origin4)

  check data4.assocBefore(3, 10).formatInline == "(1 (2 _ 3) (_ 10 4))"
  check data4.assocAfter(3, 10).formatInline == "(1 (2 _ 3) (4 10 _))"

  check data4.prepend(10).formatInline == "((_ 10 1) (2 _ 3) 4)"
  check data4.append(10).formatInline == "(1 (2 _ 3) (4 10 _))"

  let origin2 = @[1,2]
  let data2 = initTernaryTreeList(origin2)
  check data2.concat(data4).formatInline == "((1 _ 2) _ (1 (2 _ 3) 4))"

  check initTernaryTreeList[int](@[]).concat(data2).formatInline == "(1 _ 2)"

test "check equality":

  let origin4 = @[1,2,3,4]
  let data4 = initTernaryTreeList(origin4)
  let data4n = initTernaryTreeList(origin4)
  let data4Made = initTernaryTreeList(@[2,3,4]).prepend(1)

  check data4.sameShape(data4) == true
  check data4.sameShape(data4n) == true
  check data4.sameShape(data4Made) == false

  check (data4 == data4n)
  check (data4 == data4Made)
  check (data4n == data4Made)
  check data4.identical(data4Made) == false

test "force balancing":
  var data = initTernaryTreeList[int](@[])
  for idx in 0..<20:
    data = data.append(idx, true)
  # echo data.formatInline
  check data.formatInline == "(((0 1 2) (3 4 5) (6 7 8)) ((9 10 11) (12 13 14) (15 16 17)) (18 19 _))"
  data.forceInplaceBalancing
  check data.formatInline == "(((0 _ 1) (2 3 4) (5 _ 6)) ((7 _ 8) (9 _ 10) (11 _ 12)) ((13 _ 14) (15 16 17) (18 _ 19)))"
  # echo data.formatInline

test "iterator":
  let origin4 = @[1,2,3,4]
  let data4 = initTernaryTreeList(origin4)

  var i = 0
  for item in data4:
    i = i + 1

  check (i == 4)

  i = 0
  for idx, item in data4:
    i = i + idx

  check (i == 6)

test "check structure":
  var data = initTernaryTreeList[int](@[])
  for idx in 0..<20:
    data = data.append(idx, true)

  check data.checkStructure

  let origin11 = @[1,2,3,4,5,6,7,8,9,10,11]
  let data11 = initTernaryTreeList[int](origin11)

  check data11.checkStructure

test "slices":
  var data = initTernaryTreeList[int](@[])
  for idx in 0..<40:
    data = data.append(idx, true)

  var list40: seq[int] = @[]
  for idx in 0..<40:
    list40.add idx

  for i in 0..<40:
    for j in i..<40:
      check data.slice(i, j).toSeq == list40[i..<j]

test "reverse":
  let data = initTernaryTreeList(@[1,2,3,4,5,6,7,8,9,10])
  let reversedData = data.reverse
  check data.toSeq.reversed == reversedData.toSeq
  check reversedData.checkStructure

test "list each":
  var i = 0
  let data = initTernaryTreeList[int](@[1,2,3,4,5,6,7,8,9,10])
  data.each(proc(x: int) =
    i = i + 1
    discard
  )
  check i == 10

test "index of":
  let data = initTernaryTreeList[int](@[1,2,3,4,5,6,7,8])
  check data.indexOf(2) == 1
  check data.findIndex(proc(x:int):bool = x == 2) == 1
  check data.indexOf(9) == -1
  check data.findIndex(proc(x:int):bool = x == 9) == -1