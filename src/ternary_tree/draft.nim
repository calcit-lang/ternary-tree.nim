
import sequtils
import strutils
import options
import strformat

import ./types
import ./utils

proc initTernaryTreeDraft*[T](xs: seq[T]): TernaryTreeDraft[T] =
  let size = xs.len

  case size
  of 0:
    TernaryTreeDraft[T](kind: ternaryTreeBranch)
  of 1:
    TernaryTreeDraft[T](kind: ternaryTreeLeaf, value: xs[0])
  of 2:
    let left = TernaryTreeDraft[T](kind: ternaryTreeLeaf, value: xs[0])
    let right = TernaryTreeDraft[T](kind: ternaryTreeLeaf, value: xs[1])
    TernaryTreeDraft[T](kind: ternaryTreeBranch, left: left, right: right)
  of 3:
    let left = TernaryTreeDraft[T](kind: ternaryTreeLeaf, value: xs[0])
    let middle = TernaryTreeDraft[T](kind: ternaryTreeLeaf, value: xs[1])
    let right = TernaryTreeDraft[T](kind: ternaryTreeLeaf, value: xs[2])
    TernaryTreeDraft[T](kind: ternaryTreeBranch, left: left, middle: middle, right: right)
  else:
    let divided = divideTernarySizes(size)

    let left = initTernaryTreeDraft(xs[0..<divided.left])
    let middle = initTernaryTreeDraft(xs[divided.left..<(divided.left + divided.middle)])
    let right = initTernaryTreeDraft(xs[(divided.left + divided.middle)..^1])
    TernaryTreeDraft[T](kind: ternaryTreeBranch, left: left, middle: middle, right: right)

# TODO might need more information
proc `$`*[T](tree: TernaryTreeDraft[T]): string =
  "TernaryTreeDraft[...]"

const shortChartMap = "$abcdefghijklmnopqrstuvwxyz"

proc stringToSeqPath*(text: string): seq[PickBranch] =
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

proc seqToStringPath*(xs: seq[PickBranch]): string =
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

proc get*[T](tree: TernaryTreeDraft[T], path: string): Option[T] =
  tree.get(path.stringToSeqPath)

proc get*[T](tree: TernaryTreeDraft[T], path: seq[PickBranch]): Option[T] =
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
    if path.len == 0:
      return tree.middle.get(@[])

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
  cast[pointer](xs) == cast[pointer](ys)

proc `==`*(xs, ys: seq[PickBranch]): bool =
  if xs.len == 0:
    for y in ys:
      if y != pickMiddle:
        return false
    return true
  if ys.len == 0:
    for x in xs:
      if x != pickMiddle:
        return false
    return true
  if xs[0] != ys[0]:
    return false
  return xs[1..^1] == ys[1..^1]

proc isEmpty*[T](tree: TernaryTreeDraft[T]): bool =
  if tree.isNil:
    return true

  case tree.kind
  of ternaryTreeLeaf:
    return false
  of ternaryTreeBranch:
    if tree.left.len > 0:
      return false
    if tree.middle.len > 0:
      return false
    if tree.right.len > 0:
      return false
    return true

proc assoc*[T](tree: TernaryTreeDraft[T], path: seq[PickBranch], item: T): TernaryTreeDraft[T] =
  if tree.isNil:
    if path.len == 0:
      return TernaryTreeDraft[T](kind: ternaryTreeLeaf, value: item)

    raise newException(ValueError, fmt"no target for assoc at {path}")

  case tree.kind
  of ternaryTreeLeaf:
    if path.len == 0:
      return TernaryTreeDraft[T](kind: ternaryTreeLeaf, value: item)
    raise newException(ValueError, fmt"no target for assoc at {path}")

  of ternaryTreeBranch:
    if path.len == 0:
      if tree.isEmpty:
        return TernaryTreeDraft[T](kind: ternaryTreeLeaf, value: item)
      else:
        return TernaryTreeDraft[T](
          kind: ternaryTreeBranch,
          left: tree.left,
          middle: tree.middle.assoc(path[1..^1], item),
          right: tree.right
        )

    let pick = path[0]
    case pick
    of pickLeft:
      TernaryTreeDraft[T](
        kind: ternaryTreeBranch,
        left: tree.left.assoc(path[1..^1], item),
        middle: tree.middle,
        right: tree.right
      )
    of pickMiddle:
      TernaryTreeDraft[T](
        kind: ternaryTreeBranch,
        left: tree.left,
        middle: tree.middle.assoc(path[1..^1], item),
        right: tree.right
      )
    of pickRight:
      TernaryTreeDraft[T](
        kind: ternaryTreeBranch,
        left: tree.left,
        middle: tree.middle,
        right: tree.right.assoc(path[1..^1], item)
      )

proc assoc*[T](tree: TernaryTreeDraft[T], path: string, item: T): TernaryTreeDraft[T] =
  tree.assoc(path.stringToSeqPath, item)

proc toSeq*[T](tree: TernaryTreeDraft[T]): seq[T] =
  if tree.isNil:
    return @[]
  case tree.kind
  of ternaryTreeLeaf:
    return @[tree.value]
  of ternaryTreeBranch:
    for x in tree.left.toSeq:
      result.add x
    for x in tree.middle.toSeq:
      result.add x
    for x in tree.right.toSeq:
      result.add x

proc `==`*[T](xs, ys: TernaryTreeDraft[T]): bool =
  xs.toSeq == ys.toSeq

# this function mutates original tree to make it more balanced
proc forceInplaceBalancing*[T](tree: TernaryTreeDraft[T]): void =
  # echo "Force inplace balancing of draft"
  let xs = tree.toSeq
  let newTree = initTernaryTreeDraft(xs)
  tree.left = newTree.left
  tree.middle = newTree.middle
  tree.right = newTree.right

proc stripeTrailingMiddle(xs: seq[PickBranch]): seq[PickBranch] =
  if xs.len == 0:
    return xs
  if xs[^1] == pickMiddle:
    return stripeTrailingMiddle(xs[0..^2])
  else:
    return xs

proc keys*[T](tree: TernaryTreeDraft[T], basePath: seq[PickBranch] = @[]): seq[string] =
  if tree.isNil:
    return @[]

  case tree.kind
  of ternaryTreeLeaf:
    return @[basePath.stripeTrailingMiddle.seqToStringPath]
  of ternaryTreeBranch:
    for item in tree.left.keys(basePath.concat(@[pickLeft])):
      result.add item
    for item in tree.middle.keys(basePath.concat(@[pickMiddle])):
      result.add item
    for item in tree.right.keys(basePath.concat(@[pickRight])):
      result.add item

iterator pairs*[T](tree: TernaryTreeDraft[T]): tuple[k: string, v: T] =
  if tree.isEmpty:
    discard
  else:
    let ks = tree.keys
    for k in ks:
      let v = tree.get(k).get
      yield (k, v)

proc formatInline*(tree: TernaryTreeDraft, basePath: seq[PickBranch] = @[]): string =
  if tree.isNil:
    return "_"
  case tree.kind
  of ternaryTreeLeaf:
    basePath.seqToStringPath & ":" & $tree.value
  of ternaryTreeBranch:
    "(" & tree.left.formatInline(basePath.concat(@[pickLeft])) &
    " " & tree.middle.formatInline(basePath.concat(@[pickMiddle])) &
    " " & tree.right.formatInline(basePath.concat(@[pickRight])) & ")"

proc dissoc*[T](tree: TernaryTreeDraft[T], path: seq[PickBranch]): TernaryTreeDraft[T] =
  if tree.isNil:
    if path.len == 0:
      return nil
    else:
      raise newException(ValueError, fmt"no target to dissoc for ${path}")
  case tree.kind
  of ternaryTreeLeaf:
    if path.len == 0:
      return nil
    else:
      raise newException(ValueError, fmt"no target to dissoc for ${path}")
  of ternaryTreeBranch:
    if path.len == 0:
      return nil
    let pick = path[0]
    let restPath = path[1..^1]
    case pick
    of pickLeft:
      return TernaryTreeDraft[T](
        kind: ternaryTreeBranch,
        left: tree.left.dissoc(restPath),
        middle: tree.middle,
        right: tree.right
      )
    of pickMiddle:
      return TernaryTreeDraft[T](
        kind: ternaryTreeBranch,
        left: tree.left,
        middle: tree.middle.dissoc(restPath),
        right: tree.right
      )
    of pickRight:
      return TernaryTreeDraft[T](
        kind: ternaryTreeBranch,
        left: tree.left,
        middle: tree.middle,
        right: tree.right.dissoc(restPath)
      )

proc dissoc*[T](tree: TernaryTreeDraft[T], path: string): TernaryTreeDraft[T] =
  tree.dissoc(path.stringToSeqPath)

proc assocAside*[T](tree: TernaryTreeDraft[T], path: seq[PickBranch], item: T, aside: PickBranch): TernaryTreeDraft[T] =
  if tree.isNil:
    raise newException(ValueError, fmt"target nil is bad for assoc aside at {path}")

  case tree.kind
  of ternaryTreeLeaf:
    if path.len == 0:
      case aside
      of pickLeft:
        return TernaryTreeDraft[T](
          kind: ternaryTreeBranch,
          left: TernaryTreeDraft[T](kind: ternaryTreeLeaf, value: item),
          middle: tree,
          right: nil
        )
      of pickRight:
        return TernaryTreeDraft[T](
          kind: ternaryTreeBranch,
          left: nil,
          middle: tree,
          right: TernaryTreeDraft[T](kind: ternaryTreeLeaf, value: item)
        )
      else:
        raise newException(ValueError, fmt"invalid aside pickMiddle")
    raise newException(ValueError, fmt"no target for assoc at {path}")


  of ternaryTreeBranch:
    if path.len == 0:
      if tree.isEmpty:
        raise newException(ValueError, fmt"no target for assoc at {path}")
      else:
        return TernaryTreeDraft[T](
          kind: ternaryTreeBranch,
          left: tree.left,
          middle: tree.middle.assocAside(path[1..^1], item, aside),
          right: tree.right
        )

    let pick = path[0]
    case pick
    of pickLeft:
      TernaryTreeDraft[T](
        kind: ternaryTreeBranch,
        left: tree.left.assocAside(path[1..^1], item, aside),
        middle: tree.middle,
        right: tree.right
      )
    of pickMiddle:
      TernaryTreeDraft[T](
        kind: ternaryTreeBranch,
        left: tree.left,
        middle: tree.middle.assocAside(path[1..^1], item, aside),
        right: tree.right
      )
    of pickRight:
      TernaryTreeDraft[T](
        kind: ternaryTreeBranch,
        left: tree.left,
        middle: tree.middle,
        right: tree.right.assocAside(path[1..^1], item, aside)
      )

proc assocBefore*[T](tree: TernaryTreeDraft[T], path: string, item: T): TernaryTreeDraft[T] =
  tree.assocAside(path.stringToSeqPath, item, pickLeft)

proc assocAfter*[T](tree: TernaryTreeDraft[T], path: string, item: T): TernaryTreeDraft[T] =
  tree.assocAside(path.stringToSeqPath, item, pickRight)

proc sameShape*[T](xs: TernaryTreeDraft[T], ys: TernaryTreeDraft[T]): bool =
  if xs.isNil:
    if ys.isNil:
      return true
    else:
      return false
  if ys.isNil:
    return false

  if xs.kind != ys.kind:
    return false

  if xs.kind == ternaryTreeLeaf:
    if xs.value != ys.value:
      return false
    else:
      return true

  if not xs.left.sameShape(ys.left):
    return false

  if not xs.middle.sameShape(ys.middle):
    return false

  if not xs.right.sameShape(ys.right):
    return false

  return true

# TODO checkStructure
