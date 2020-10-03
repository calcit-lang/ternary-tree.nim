
import options
# import strformat

import ./types
import ./utils

# $abcdefghijkl m nopqrstuvwxyz

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

proc get*[T](tree: TernaryTreeDraft[T], path: string): T =
  # TODO
  return nil

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

# TODO get
# TODO len
# TODO contains
# TODO `[]`
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
