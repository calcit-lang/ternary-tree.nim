
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

  check data10.toSortedSeq == inList

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
