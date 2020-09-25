
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

proc showLinear*(tree: TernaryTreeList): string =
  if tree.isNil:
    return "nil"
  case tree.kind
  of ternaryTreeLeaf:
    $tree.value
  of ternaryTreeBranch:
    "(" & tree.left.showLinear & " " & tree.middle.showLinear & " " & tree.right.showLinear & ")"
