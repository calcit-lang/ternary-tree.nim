
import strformat

import ternary_tree/types
import ternary_tree/map
import ternary_tree/utils

# just get, will not compute recursively
proc getDepth*[T](tree: TernaryTreeList[T]): int =
  if tree.isNil:
    return 0
  case tree.kind
  of ternaryTreeLeaf:
    1
  of ternaryTreeBranch:
    tree.depth

proc decideParentDepth[T](xs: varargs[TernaryTreeList[T]]): int =
  var depth = 0
  for x in xs:
    let y = x.getDepth
    if y > depth:
      depth = y
  return depth + 1

proc initTernaryTreeList*[T](size: int, offset: int, xs: var seq[T]): TernaryTreeList[T] =
  case size
    of 0:
      TernaryTreeList[T](kind: ternaryTreeBranch, size: 0, depth: 1)
    of 1:
      TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: xs[offset + 0])
    of 2:
      let left = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: xs[offset + 0])
      let right = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: xs[offset + 1])
      TernaryTreeList[T](kind: ternaryTreeBranch, size: 2, left: left, right: right, depth: 2)
    of 3:
      let left = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: xs[offset + 0])
      let middle = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: xs[offset + 1])
      let right = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: xs[offset + 2])
      TernaryTreeList[T](kind: ternaryTreeBranch, size: 3, left: left, middle: middle, right: right, depth: 2)
    else:
      let divided = divideTernarySizes(size)

      let left = initTernaryTreeList(divided.left, offset, xs)
      let middle = initTernaryTreeList(divided.middle, offset + divided.left, xs)
      let right = initTernaryTreeList(divided.right, offset + divided.left + divided.middle, xs)
      TernaryTreeList[T](
        kind: ternaryTreeBranch, size: size,
        depth: decideParentDepth(left, middle, right),
        left: left, middle: middle, right: right,
      )

proc initTernaryTreeList*[T](xs: seq[T]): TernaryTreeList[T] =
  var ys = xs
  initTernaryTreeList(xs.len, 0, ys)

proc `$`*(tree: TernaryTreeList): string =
  fmt"TernaryTreeList[{tree.size}, ...]"

proc len*(tree: TernaryTreeList): int =
  if tree.isNil:
    0
  else:
    tree.size

proc isLeaf(tree: TernaryTreeList): bool =
  tree.kind == ternaryTreeLeaf

proc isBranch(tree: TernaryTreeList): bool =
  tree.kind == ternaryTreeBranch

proc formatInline*(tree: TernaryTreeList): string =
  if tree.isNil:
    return "_"
  case tree.kind
  of ternaryTreeLeaf:
    $tree.value
  of ternaryTreeBranch:
    "(" & tree.left.formatInline & " " & tree.middle.formatInline & " " & tree.right.formatInline & ")"
    # "(" & tree.left.formatInline & " " & tree.middle.formatInline & " " & tree.right.formatInline & fmt")@{tree.depth} " & fmt"{tree.left.getDepth} {tree.middle.getDepth} {tree.right.getDepth}..."

proc writeSeq*[T](tree: TernaryTreeList[T], acc: var seq[T]): void =
  if tree.isNil:
    discard
  case tree.kind
  of ternaryTreeLeaf:
    acc.add tree.value
  of ternaryTreeBranch:
    if not tree.left.isNil:
      tree.left.writeSeq(acc)
    if not tree.middle.isNil:
      tree.middle.writeSeq(acc)
    if not tree.right.isNil:
      tree.right.writeSeq(acc)

proc toSeq*[T](tree: TernaryTreeList[T]): seq[T] =
  var acc: seq[T]
  writeSeq(tree, acc)
  return acc

# recursive iterator not supported, use slow seq for now
# https://forum.nim-lang.org/t/5697
iterator items*[T](tree: TernaryTreeList[T]): T =
  let seqItems = tree.toSeq()

  for x in seqItems:
    yield x

iterator pairs*[T](tree: TernaryTreeList[T]): tuple[k: int, v: T] =
  let seqItems = tree.toSeq()

  for idx, x in seqItems:
    yield (idx, x)

proc get*[T](tree: TernaryTreeList[T], idx: int): T =
  if idx < 0:
    raise newException(ValueError, "Cannot index negative number")
  if idx > (tree.size - 1):
    raise newException(ValueError, "Index too large")

  if tree.kind == ternaryTreeLeaf:
    if idx == 0:
      return tree.value
    else:
      raise newException(ValueError, fmt"Cannot get from leaf with index {idx}")

  let leftSize = tree.left.len
  let middleSize = tree.middle.len
  let rightSize = tree.right.len

  if leftSize + middleSize + rightSize != tree.size:
    raise newException(ValueError, "tree.size does not match sum of branch sizes")

  if idx <= leftSize - 1:
    return tree.left.get(idx)
  elif idx <= leftSize + middleSize - 1:
    return tree.middle.get(idx - leftSize)
  else:
    return tree.right.get(idx - leftSize - middleSize)

proc `[]`*[T](tree: TernaryTreeList[T], idx: int): T =
  tree.get(idx)

proc first*[T](tree: TernaryTreeList[T]): T =
  if tree.len > 0:
    tree.get(0)
  else:
    raise newException(ValueError, "Cannot get from empty list")

proc last*[T](tree: TernaryTreeList[T]): T =
  if tree.len > 0:
    tree.get(tree.len - 1)
  else:
    raise newException(ValueError, "Cannot get from empty list")

proc assoc*[T](tree: TernaryTreeList[T], idx: int, item: T): TernaryTreeList[T] =
  if idx < 0:
    raise newException(ValueError, "Cannot index negative number")
  if idx > (tree.size - 1):
    raise newException(ValueError, "Index too large")

  if tree.kind == ternaryTreeLeaf:
    if idx == 0:
      return TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)
    else:
      raise newException(ValueError, fmt"Cannot get from leaf with index {idx}")

  let leftSize = tree.left.len
  let middleSize = tree.middle.len
  let rightSize = tree.right.len

  if leftSize + middleSize + rightSize != tree.size:
    raise newException(ValueError, "tree.size does not match sum of branch sizes")

  if idx <= leftSize - 1:
    let changedBranch = tree.left.assoc(idx, item)
    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size,
      depth: decideParentDepth(changedBranch, tree.middle, tree.right),
      left: changedBranch,
      middle: tree.middle,
      right: tree.right
    )
  elif idx <= leftSize + middleSize - 1:
    let changedBranch = tree.middle.assoc(idx - leftSize, item)
    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size,
      depth: decideParentDepth(tree.left, changedBranch, tree.right),
      left: tree.left,
      middle: changedBranch,
      right: tree.right
    )
  else:
    let changedBranch = tree.right.assoc(idx - leftSize - middleSize, item)
    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size,
      depth: decideParentDepth(tree.left, tree.middle, changedBranch),
      left: tree.left,
      middle: tree.middle,
      right: changedBranch
    )

proc dissoc*[T](tree: TernaryTreeList[T], idx: int): TernaryTreeList[T] =
  if tree.isNil:
    raise newException(ValueError, "dissoc does not work on nil")

  if idx < 0:
    raise newException(ValueError, fmt"Index is negative {idx}")

  if tree.len == 0:
    raise newException(ValueError, "Cannot remove from empty list")

  if idx > tree.len - 1:
    raise newException(ValueError, fmt"Index too large {idx}")

  if tree.len == 1:
    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: 0,
      depth: 1,
      left: nil,
      middle: nil,
      right: nil
    )

  if tree.kind == ternaryTreeLeaf:
    raise newException(ValueError, "dissoc should be handled at branches")

  let leftSize = tree.left.len
  let middleSize = tree.middle.len
  let rightSize = tree.right.len

  if leftSize + middleSize + rightSize != tree.size:
    raise newException(ValueError, "tree.size does not match sum of branch sizes")

  if idx <= leftSize - 1:
    var changedBranch = tree.left.dissoc(idx)
    if changedBranch.size == 0:
      changedBranch = nil
    result = TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size - 1,
      depth: decideParentDepth(changedBranch, tree.middle, tree.right),
      left: changedBranch,
      middle: tree.middle,
      right: tree.right
    )
  elif idx <= leftSize + middleSize - 1:
    var changedBranch = tree.middle.dissoc(idx - leftSize)
    if changedBranch.size == 0:
      changedBranch = nil
    result = TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size - 1,
      depth: decideParentDepth(tree.left, changedBranch, tree.right),
      left: tree.left,
      middle: changedBranch,
      right: tree.right
    )
  else:
    var changedBranch = tree.right.dissoc(idx - leftSize - middleSize)
    if changedBranch.size == 0:
      changedBranch = nil
    result = TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size - 1,
      depth: decideParentDepth(tree.left, tree.middle, changedBranch),
      left: tree.left,
      middle: tree.middle,
      right: changedBranch
    )

  if result.len == 1:
    result = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: result.get(0))

  return result

proc rest*[T](tree: TernaryTreeList[T]): TernaryTreeList[T] =
  if tree.isNil:
    raise newException(ValueError, "Cannot call rest on nil")
  if tree.len < 1:
    raise newException(ValueError, "Cannot call rest on empty list")

  tree.dissoc(0)

proc butlast*[T](tree: TernaryTreeList[T]): TernaryTreeList[T] =
  if tree.isNil:
    raise newException(ValueError, "Cannot call butlast on nil")
  if tree.len < 1:
    raise newException(ValueError, "Cannot call butlast on empty list")

  tree.dissoc(tree.len - 1)

proc insert*[T](tree: TernaryTreeList[T], idx: int, item: T, after: bool = false): TernaryTreeList[T] =
  if tree.isNil:
    raise newException(ValueError, "Cannot insert into nil")
  if tree.len == 0:
    raise newException(ValueError, "Empty node is not a correct position for inserting")

  if tree.kind == ternaryTreeLeaf:
    var left: TernaryTreeList[T] = nil
    var right: TernaryTreeList[T] = nil

    if after:
      right = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)
    else:
      left = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)

    return TernaryTreeList[T](
      kind: ternaryTreeBranch,
      depth: tree.getDepth + 1,
      size: 2,
      left: left,
      middle: tree,
      right: right
    )

  if tree.len == 1:
    if after:
      if tree.left != nil:
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          size: 2,
          depth: 2,
          left: tree.left,
          middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
          right: nil
        )
      elif tree.middle != nil:
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          size: 2,
          depth: 2,
          left: nil,
          middle: tree.middle,
          right: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)
        )
    else:
      if tree.right != nil:
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          size: 2,
          depth: 2,
          left: nil,
          middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
          right: tree.right
        )
      elif tree.middle != nil:
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          size: 2,
          depth: tree.middle.getDepth + 1,
          left: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
          middle: tree.middle,
          right: nil
        )

  if tree.len == 2:
    if after:
      if tree.right.isNil:
        let changedBranch = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          size: 3,
          depth: 2,
          left: tree.left,
          middle: tree.middle,
          right: changedBranch
        )

    else:
      if tree.left.isNil:
        let changedBranch = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          size: 3,
          depth: 2,
          left: changedBranch,
          middle: tree.middle,
          right: tree.right
        )

  let leftSize = tree.left.len
  let middleSize = tree.middle.len
  let rightSize = tree.right.len

  if leftSize + middleSize + rightSize != tree.size:
    raise newException(ValueError, "tree.size does not match sum of branch sizes")


  # echo "picking: ", idx, " ", leftSize, " ", middleSize, " ", rightSize

  if idx <= leftSize - 1:
    let changedBranch = tree.left.insert(idx, item, after)

    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size + 1,
      depth: decideParentDepth(changedBranch, tree.middle, tree.right),
      left: changedBranch,
      middle: tree.middle,
      right: tree.right
    )
  elif idx <= leftSize + middleSize - 1:
    let changedBranch = tree.middle.insert(idx - leftSize, item, after)

    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size + 1,
      depth: decideParentDepth(tree.left, changedBranch, tree.right),
      left: tree.left,
      middle: changedBranch,
      right: tree.right
    )
  else:
    let changedBranch = tree.right.insert(idx - leftSize - middleSize, item, after)

    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size + 1,
      depth: decideParentDepth(tree.left, tree.middle, changedBranch),
      left: tree.left,
      middle: tree.middle,
      right: changedBranch
    )

proc assocBefore*[T](tree: TernaryTreeList[T], idx: int, item: T, after: bool = false): TernaryTreeList[T] =
  insert(tree, idx, item, false)

proc assocAfter*[T](tree: TernaryTreeList[T], idx: int, item: T, after: bool = false): TernaryTreeList[T] =
  insert(tree, idx, item, true)

# this function mutates original tree to make it more balanced
proc forceInplaceBalancing*[T](tree: TernaryTreeList[T]): void =
  # echo "Force inplace balancing of list: ", tree.size
  var ys = tree.toSeq
  let newTree = initTernaryTreeList(ys.len, 0.int, ys)
  tree.left = newTree.left
  tree.middle = newTree.middle
  tree.right = newTree.right

# TODO, need better strategy for detecting
proc maybeReblance[T](tree: TernaryTreeList[T]): void =
  let currentDepth = tree.getDepth
  if currentDepth > 50:
    if 3.roughIntPow(currentDepth - 50) > tree.size:
      tree.forceInplaceBalancing

proc prepend*[T](tree: TernaryTreeList[T], item: T, disableBalancing: bool = false): TernaryTreeList[T] =
  if tree.isNil or tree.len == 0:
    return TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)
  result = insert(tree, 0, item, false)

  if (not disableBalancing):
    result.maybeReblance

proc append*[T](tree: TernaryTreeList[T], item: T, disableBalancing: bool = false): TernaryTreeList[T] =
  if tree.isNil or tree.len == 0:
    return TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)
  result = insert(tree, tree.len - 1, item, true)

  if (not disableBalancing):
    result.maybeReblance

proc concat*[T](xs: TernaryTreeList[T], ys: TernaryTreeList[T]): TernaryTreeList[T] =
  if xs.isNil or xs.len == 0:
    return ys
  if ys.isNil or ys.len == 0:
    return xs
  result = TernaryTreeList[T](
    kind: ternaryTreeBranch, size: xs.size + ys.size,
    depth: decideParentDepth(xs, nil, ys),
    left: xs,
    middle: nil,
    right: ys
  )
  result.maybeReblance

proc sameShape*[T](xs: TernaryTreeList[T], ys: TernaryTreeList[T]): bool =
  if xs.isNil:
    if ys.isNil:
      return true
    else:
      return false
  if ys.isNil:
    return false

  if xs.len != ys.len:
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

proc identical*[T](xs: TernaryTreeList[T], ys: TernaryTreeList[T]): bool =
  cast[pointer](xs) == cast[pointer](ys)

proc `==`*[T](xs: TernaryTreeList[T], ys: TernaryTreeList[T]): bool =
  if xs.len != ys.len:
    return false

  if xs.identical(ys):
    return true

  for idx in 0..<xs.len:
    if xs.get(idx) != ys.get(idx):
      return false

  return true

proc checkStructure*[T](tree: TernaryTreeList[T]): bool =
  if tree.isNil:
    return true
  case tree.kind
  of ternaryTreeLeaf:
    if tree.size != 1:
      raise newException(ValueError, fmt"Bad size at node {tree.formatInline}")
  of ternaryTreeBranch:
    if tree.size != tree.left.len + tree.middle.len + tree.right.len:
      raise newException(ValueError, fmt"Bad size at branch {tree.formatInline}")

    if tree.depth != decideParentDepth(tree.left, tree.middle, tree.right):
      let x = decideParentDepth(tree.left, tree.middle, tree.right)
      raise newException(ValueError, fmt"Bad depth at branch {tree.formatInline}")

    discard tree.left.checkStructure
    discard tree.middle.checkStructure
    discard tree.right.checkStructure

  return true

# excludes value at endIdx, kept aligned with JS & Clojure
proc slice*[T](tree: TernaryTreeList[T], startIdx: int, endIdx: int): TernaryTreeList[T] =
  # echo fmt"slice {tree.formatInline}: {startIdx}..{endIdx}"
  if endIdx > tree.len:
    raise newException(ValueError, fmt"Slice range too large {endIdx} for {tree}")
  if startIdx < 0:
    raise newException(ValueError, fmt"Slice range too small {startIdx} for {tree}")
  if startIdx > endIdx:
    raise newException(ValueError, fmt"Invalid slice range {startIdx}..{endIdx} for {tree}")
  if startIdx == endIdx:
    return TernaryTreeList[T](kind: ternaryTreeBranch, size: 0, depth: 0)

  if tree.kind == ternaryTreeLeaf:
    if startIdx == 0 and endIdx == 1:
      return tree
    else:
      raise newException(ValueError, fmt"Invalid slice range for a leaf: {startIdx} {endIdx}")

  let leftSize = tree.left.len
  let middleSize = tree.middle.len
  let rightSize = tree.right.len

  # echo fmt"sizes: {leftSize} {middleSize} {rightSize}"

  if startIdx >= leftSize + middleSize:
    return tree.right.slice(startIdx - leftSize - middleSize, endIdx - leftSize - middleSize)
  if startIdx >= leftSize:
    if endIdx <= leftSize + middleSize:
      return tree.middle.slice(startIdx - leftSize, endIdx - leftSize)
    else:
      let middleCut = tree.middle.slice(startIdx - leftSize, middleSize)
      let rightCut = tree.right.slice(0, endIdx - leftSize - middleSize)
      return middleCut.concat(rightCut)

  if endIdx <= leftSize:
    return tree.left.slice(startIdx, endIdx)

  if endIdx <= leftSize + middleSize:
    let leftCut = tree.left.slice(startIdx, leftSize)
    let middleCut = tree.middle.slice(0, endIdx - leftSize)
    return leftCut.concat(middleCut)

  if endIdx <= leftSize + middleSize + rightSize:
    let leftCut = tree.left.slice(startIdx, leftSize)
    let rightCut = tree.right.slice(0, endIdx - leftSize - middleSize)
    return leftCut.concat(tree.middle).concat(rightCut)

proc reverse*[T](tree: TernaryTreeList[T]): TernaryTreeList[T] =
  if tree.isNil:
    return tree

  case tree.kind
  of ternaryTreeLeaf:
    tree
  of ternaryTreeBranch:
    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size,
      depth: tree.depth,
      left: tree.right.reverse,
      middle: tree.middle.reverse,
      right: tree.left.reverse
    )
