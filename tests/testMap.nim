
import hashes
import algorithm
import options
import strformat
import tables
import unittest

import ternary_tree

test "init map":
  var dict: Table[string, int]
  var inList: seq[tuple[k: string, v: int]] = @[]
  for idx in 0..<10:
    dict[fmt"{idx}"] = idx + 10
    inList.add((fmt"{idx}", idx + 10))

  inList = inList.sorted(proc(x, y: tuple[k: string, v: int]): int =
    let hx = x.k.hash
    let hy = y.k.hash
    cmp(hx, hy)
  )

  let data10 = initTernaryTreeMap[string, int](dict)

  # echo data10
  check data10.formatInline == "((2:12 3:13 7:17) ((_ 9:19 _) (6:16 _ 5:15) (_ 1:11 _)) (8:18 0:10 4:14))"

  check data10.toHashSortedSeq == inList

  check data10.contains("1") == true
  check data10.contains("11") == false

  check data10.get("1") == some(11)
  check data10.get("11") == none(int)

  check data10.checkStructure == true

test "assoc map":
  var dict: Table[string, int]
  for idx in 0..<10:
    dict[fmt"{idx}"] = idx + 10

  let data = initTernaryTreeMap(dict)

  # echo data.formatInline

  check data.contains("1") == true
  check data.contains("12") == false

  check data.assoc("1", 2222).formatInline(false) == "((2:12 3:13 7:17) ((_ 9:19 _) (6:16 _ 5:15) (_ 1:2222 _)) (8:18 0:10 4:14))"
  check data.assoc("23", 2222).formatInline(false) == "((2:12 3:13 7:17) ((_ 9:19 _) (6:16 _ 5:15) (23:2222 (_ 1:11 _) _)) (8:18 0:10 4:14))"

test "dissoc":

  var dict: Table[string, int]
  for idx in 0..<10:
    dict[fmt"{idx}"] = idx + 10

  let data = initTernaryTreeMap(dict)

  # echo data.formatInline

  for idx in 0..<10:
    let v = data.dissoc(fmt"{idx}")
    check v.contains(fmt"{idx}") == false
    check data.contains(fmt"{idx}") == true
    check v.len == (data.len - 1)

  for idx in 10..<12:
    let v = data.dissoc(fmt"{idx}")
    check v.contains(fmt"{idx}") == false
    check v.len == data.len

test "to seq":

  var dict: Table[string, int]
  for idx in 0..<10:
    dict[fmt"{idx}"] = idx + 10

  let data = initTernaryTreeMap(dict)

  check ($data.toPairs == "@[2:12, 3:13, 7:17, 9:19, 6:16, 5:15, 1:11, 8:18, 0:10, 4:14]")
  check (data.keys == @["2", "3", "7", "9", "6", "5", "1", "8", "0", "4"])

test "Equality":
  var dict: Table[string, int]
  for idx in 0..<10:
    dict[fmt"{idx}"] = idx + 10

  let data = initTernaryTreeMap(dict)
  let b = data.dissoc("3")

  check (data == data)
  check (data != b)

test "Merge":
  var dict: Table[string, int]
  var dictBoth: Table[string, int]
  for idx in 0..<4:
    dict[fmt"{idx}"] = idx + 10
    dictBoth[fmt"{idx}"] = idx + 10

  let data = initTernaryTreeMap(dict)

  var dictB: Table[string, int]
  for idx in 10..<14:
    dictB[fmt"{idx}"] = idx + 23
    dictBoth[fmt"{idx}"] = idx + 23
  let b = initTernaryTreeMap(dictB)

  let merged = data.merge(b)
  let both = initTernaryTreeMap(dictBoth)

  check (merged == both)
