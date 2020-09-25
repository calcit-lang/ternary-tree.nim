
import strformat
import math

import ternary_tree/types

export TernaryTreeList, TernaryTreeKind

proc initTernaryTreeList*[T](xs: seq[T]): TernaryTreeList[T] =
  let size = xs.len
  let depth = log(size.float, 3.float).ceil

  case size
    of 0:
      TernaryTreeList[T](kind: ternaryTreeBranch, size: 0, depth: 1)
    of 1:
      TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: xs[0])
    of 2:
      let left = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: xs[0])
      let right = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: xs[1])
      TernaryTreeList[T](kind: ternaryTreeBranch, size: 2, depth: 1, left: left, right: right)
    of 3:
      let left = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: xs[0])
      let middle = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: xs[1])
      let right = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: xs[2])
      TernaryTreeList[T](kind: ternaryTreeBranch, size: 3, depth: 1, left: left, middle: middle, right: right)
    else:
      let extra = size mod 3
      let groupSize = (size / 3).floor.int
      var leftSize = groupSize
      var middleSize = groupSize
      var rightSize = groupSize

      case extra
      of 0:
        discard
      of 1:
        middleSize = middleSize + 1
      of 2:
        leftSize = leftSize + 1
        rightSize = rightSize + 1
      else:
        raise newException(ValueError, "Unexpected mod result")

      let left = initTernaryTreeList(xs[0..<leftSize])
      let middle = initTernaryTreeList(xs[leftSize..<(leftSize + middleSize)])
      let right = initTernaryTreeList(xs[(leftSize + middleSize)..^1])
      let parentDepth = max(@[left.depth, middle.depth, right.depth]) + 1
      TernaryTreeList[T](kind: ternaryTreeBranch, size: size, depth: parentDepth, left: left, middle: middle, right: right)


proc `$`*(tree: TernaryTreeList): string =
  fmt"TernaryTreeList[{tree.size}, {tree.depth}]"

proc len*(tree: TernaryTreeList): int =
  tree.size

proc showLinear*(tree: TernaryTreeList): string =
  if tree.isNil:
    return "nil"
  case tree.kind
  of ternaryTreeLeaf:
    $tree.value
  of ternaryTreeBranch:
    "(" & tree.left.showLinear & " " & tree.middle.showLinear & " " & tree.right.showLinear & ")"

proc toSeq*[T](tree: TernaryTreeList[T]): seq[T] =
  var acc: seq[T] = @[]
  if tree == nil:
    return acc
  case tree.kind
  of ternaryTreeLeaf:
    acc.add tree.value
    return acc
  of ternaryTreeBranch:
    if tree.left != nil:
      let xs = tree.left.toSeq
      for x in xs:
        acc.add x
    if tree.middle != nil:
      let xs = tree.middle.toSeq
      for x in xs:
        acc.add x
    if tree.right != nil:
      let xs = tree.right.toSeq
      for x in xs:
        acc.add x
    return acc

# recursive iterator not supported, use slow seq for now
# https://forum.nim-lang.org/t/5697
iterator items*[T](tree: TernaryTreeList[T]): T =
  var acc: seq[T] = @[]
  let seqItems = tree.toSeq()

  for x in seqItems:
    yield x

# TODO assoc
# TODO dissoc
# TODO update
# TODO assoc-after
# TODO assoc-before
