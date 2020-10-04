
import strutils
import options
import strformat

import ./types
import ./utils

proc initTernaryTreeDraft*[T](xs: seq[T]): TernaryTreeDraft[T] =
  let size = xs.len

  case size
  of 0:
    TernaryTreeDraft[T](kind: ternaryTreeBranch, size: 0)
  of 1:
    TernaryTreeDraft[T](kind: ternaryTreeLeaf, size: 1, value: xs[0])
  of 2:
    let left = TernaryTreeDraft[T](kind: ternaryTreeLeaf, size: 1, value: xs[0])
    let right = TernaryTreeDraft[T](kind: ternaryTreeLeaf, size: 1, value: xs[1])
    TernaryTreeDraft[T](kind: ternaryTreeBranch, size: 2, left: left, right: right)
  of 3:
    let left = TernaryTreeDraft[T](kind: ternaryTreeLeaf, size: 1, value: xs[0])
    let middle = TernaryTreeDraft[T](kind: ternaryTreeLeaf, size: 1, value: xs[1])
    let right = TernaryTreeDraft[T](kind: ternaryTreeLeaf, size: 1, value: xs[2])
    TernaryTreeDraft[T](kind: ternaryTreeBranch, size: 3, left: left, middle: middle, right: right)
  else:
    let divided = divideTernarySizes(size)

    let left = initTernaryTreeDraft(xs[0..<divided.left])
    let middle = initTernaryTreeDraft(xs[divided.left..<(divided.left + divided.middle)])
    let right = initTernaryTreeDraft(xs[(divided.left + divided.middle)..^1])
    TernaryTreeDraft[T](kind: ternaryTreeBranch, size: size, left: left, middle: middle, right: right)

# TODO might need more information
proc `$`*[T](tree: TernaryTreeDraft[T]): string =
  "TernaryTreeDraft[...]"

const shortChartMap = "$abcdefghijklmnopqrstuvwxyz"

proc stringToSeqPath*(text: string): seq[Branching] =
  for x in text:
    let idx = shortChartMap.find(x)
    if idx < 0 or idx >= 27:
      raise newException(ValueError, fmt"char out of range {x}")
    let a3 = idx.mod(3)
    let b3 = ((idx - a3) / 3).int
    let a2 = b3.mod(3)
    let b2 = ((b3 - a2) / 3).int
    let a1 = b2.mod(3)
    for y in @[a1, a2, a3]:
      case y
      of 0:
        result.add pickLeft
      of 1:
        result.add pickMiddle
      of 2:
        result.add pickRight
      else:
        raise newException(ValueError, fmt"unexpected mod result ${y}")
  if result[^1] == pickMiddle:
    result = result[0..^2]
    if result[^1] == pickMiddle:
      result = result[0..^2]

proc seqToStringPath*(xs: seq[Branching]): string =
  var unit = 9
  var acc = 0
  for x in xs:
    case x
    of pickLeft:
      acc = acc + unit * 0
    of pickMiddle:
      acc = acc + unit * 1
    of pickRight:
      acc = acc + unit * 2
    if unit == 1:
      unit = 9
      result = result & shortChartMap[acc]
      acc = 0
    else:
      unit = (unit / 3).int
  if unit == 3:
    result = result & shortChartMap[acc + 4]
  if unit == 1:
    result = result & shortChartMap[acc + 1]

proc get*[T](tree: TernaryTreeDraft[T], path: string): T =
  tree.get(path.stringToSeqPath)

proc get*[T](tree: TernaryTreeDraft[T], path: seq[Branching]): Option[T] =
  if tree.isNil:
    return none(T)

  case tree.kind
  of ternaryTreeLeaf:
    if path.len == 0:
      return some(tree.value)
    else:
      # raise newException(ValueError, fmt"missing branch for path {path}")
      return none(T)
  of ternaryTreeBranch:
    let pick = path[0]
    case pick
    of pickLeft:
      return tree.left.get(path[1..^1])
    of pickMiddle:
      return tree.middle.get(path[1..^1])
    of pickRight:
      return tree.right.get(path[1..^1])

proc `[]`*[T](tree: TernaryTreeDraft[T], path: string): Option[T] =
  tree.get(path)

proc contains*[T](tree: TernaryTreeDraft[T], path: string): Option[T] =
  let item = tree.get(path)
  return item.isSome

proc len*[T](tree: TernaryTreeDraft[T]): int =
  if tree.isNil:
    return 0

  case tree.kind
  of ternaryTreeLeaf:
    return 1
  of ternaryTreeBranch:
    return tree.left.len + tree.middle.len + tree.right.len

proc identical*[T](xs: TernaryTreeDraft[T], ys: TernaryTreeDraft[T]): bool =
  if cast[pointer](xs) == cast[pointer](ys):
    return true

# TODO assoc
# TODO assoc-before
# TODO assoc-after
# TODO dissoc
# TODO toSeq
# TODO pairs
# TODO formatInline
# TODO checkStructure
# TODO identical
# TODO `==`
# TODO forceInplaceBalancing
