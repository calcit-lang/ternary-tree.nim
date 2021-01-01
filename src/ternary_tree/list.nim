
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

proc initTernaryTreeList*[T](size: int, offset: int, xs: var seq[TernaryTreeList[T]]): TernaryTreeList[T] =
  case size
    of 0:
      TernaryTreeList[T](kind: ternaryTreeBranch, size: 0, depth: 1)
    of 1:
      xs[offset]
    of 2:
      let left = xs[offset]
      let right = xs[offset + 1]
      TernaryTreeList[T](kind: ternaryTreeBranch, size: 2, left: left, right: right, depth: 2)
    of 3:
      let left = xs[offset]
      let middle = xs[offset + 1]
      let right = xs[offset + 2]
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
  var ys = newSeq[TernaryTreeList[T]](xs.len)
  for idx, x in xs:
    ys[idx] = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: x)
  initTernaryTreeList(xs.len, 0, ys)

proc initTernaryTreeList*[T](): TernaryTreeList[T] =
  TernaryTreeList[T](kind: ternaryTreeBranch, size: 0, depth: 1)

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

proc writeSeq*[T](tree: TernaryTreeList[T], acc: var seq[T], idx: RefInt): void =
  if tree.isNil:
    discard
  case tree.kind
  of ternaryTreeLeaf:
    acc[idx[]] = tree.value
    idx[] = idx[] + 1
  of ternaryTreeBranch:
    if not tree.left.isNil:
      tree.left.writeSeq(acc, idx)
    if not tree.middle.isNil:
      tree.middle.writeSeq(acc, idx)
    if not tree.right.isNil:
      tree.right.writeSeq(acc, idx)

proc toSeq*[T](tree: TernaryTreeList[T]): seq[T] =
  var acc = newSeq[T](tree.len)
  var counter = new RefInt
  counter[] = 0
  writeSeq(tree, acc, counter)
  return acc

proc each*[T](tree: TernaryTreeList[T], f: proc(x: T): void): void =
  if tree.isNil:
    discard
  case tree.kind
  of ternaryTreeLeaf:
    f(tree.value)
  of ternaryTreeBranch:
    if not tree.left.isNil:
      tree.left.each(f)
    if not tree.middle.isNil:
      tree.middle.each(f)
    if not tree.right.isNil:
      tree.right.each(f)

# returns -1 if not found
proc findIndex*[T](tree: TernaryTreeList[T], f: proc(x: T): bool): int =
  if tree.isNil:
    return -1
  case tree.kind:
  of ternaryTreeLeaf:
    if f(tree.value):
      return 0
    else:
      return -1
  of ternaryTreeBranch:
    let tryLeft = tree.left.findIndex(f)
    if tryLeft >= 0:
      return tryLeft
    let tryMiddle = tree.middle.findIndex(f)
    if tryMiddle >= 0:
      return tryMiddle + tree.left.len
    let tryRight = tree.right.findIndex(f)
    if tryRight >= 0:
      return tryRight + tree.left.len + tree.middle.len
    return -1

# returns -1 if not found
proc indexOf*[T](tree: TernaryTreeList[T], item: T): int =
  if tree.isNil:
    return -1
  case tree.kind:
  of ternaryTreeLeaf:
    if item == tree.value:
      return 0
    else:
      return -1
  of ternaryTreeBranch:
    let tryLeft = tree.left.indexOf(item)
    if tryLeft >= 0:
      return tryLeft
    let tryMiddle = tree.middle.indexOf(item)
    if tryMiddle >= 0:
      return tryMiddle + tree.left.len
    let tryRight = tree.right.indexOf(item)
    if tryRight >= 0:
      return tryRight + tree.left.len + tree.middle.len
    return -1

proc writeLeavesSeq*[T](tree: TernaryTreeList[T], acc: var seq[TernaryTreeList[T]], idx: RefInt): void =
  if tree.isNil:
    discard
  case tree.kind
  of ternaryTreeLeaf:
    acc[idx[]] = tree
    idx[] = idx[] + 1
  of ternaryTreeBranch:
    if not tree.left.isNil:
      tree.left.writeLeavesSeq(acc, idx)
    if not tree.middle.isNil:
      tree.middle.writeLeavesSeq(acc, idx)
    if not tree.right.isNil:
      tree.right.writeLeavesSeq(acc, idx)

proc toLeavesSeq*[T](tree: TernaryTreeList[T]): seq[TernaryTreeList[T]] =
  var acc = newSeq[TernaryTreeList[T]](tree.len)
  var counter = new RefInt
  counter[] = 0
  writeLeavesSeq(tree, acc, counter)
  return acc

# recursive iterator not supported, use slow seq for now
# https://forum.nim-lang.org/t/5697
iterator items*[T](tree: TernaryTreeList[T]): T =
  # let seqItems = tree.toSeq()

  # for x in seqItems:
  #   yield x

  for idx in 0..<tree.len:
    yield tree[idx]

iterator pairs*[T](tree: TernaryTreeList[T]): tuple[k: int, v: T] =
  let seqItems = tree.toSeq()

  for idx, x in seqItems:
    yield (idx, x)

proc loopGet*[T](originalTree: TernaryTreeList[T], originalIdx: int): T =
  var tree = originalTree
  var idx = originalIdx
  while tree.isNil.not:
    if idx < 0:
      raise newException(TernaryTreeError, "Cannot index negative number")

    if tree.kind == ternaryTreeLeaf:
      if idx == 0:
        return tree.value
      else:
        raise newException(TernaryTreeError, fmt"Cannot get from leaf with index {idx}")

    if idx > (tree.size - 1):
      raise newException(TernaryTreeError, "Index too large")

    let leftSize = if tree.left.isNil: 0 else: tree.left.size
    let middleSize = if tree.middle.isNil: 0 else: tree.middle.size
    let rightSize = if tree.right.isNil: 0 else: tree.right.size

    if leftSize + middleSize + rightSize != tree.size:
      raise newException(TernaryTreeError, "tree.size does not match sum of branch sizes")

    if idx <= leftSize - 1:
      tree = tree.left
    elif idx <= leftSize + middleSize - 1:
      tree = tree.middle
      idx = idx - leftSize
    else:
      tree = tree.right
      idx = idx - leftSize - middleSize

  raise newException(TernaryTreeError, fmt"Failed to get {idx}")

proc `[]`*[T](tree: TernaryTreeList[T], idx: int): T =
  tree.loopGet(idx)

proc first*[T](tree: TernaryTreeList[T]): T =
  if tree.len > 0:
    tree.loopGet(0)
  else:
    raise newException(TernaryTreeError, "Cannot get from empty list")

proc last*[T](tree: TernaryTreeList[T]): T =
  if tree.len > 0:
    tree.loopGet(tree.len - 1)
  else:
    raise newException(TernaryTreeError, "Cannot get from empty list")

proc assoc*[T](tree: TernaryTreeList[T], idx: int, item: T): TernaryTreeList[T] =
  if idx < 0:
    raise newException(TernaryTreeError, "Cannot index negative number")
  if idx > (tree.size - 1):
    raise newException(TernaryTreeError, "Index too large")

  if tree.kind == ternaryTreeLeaf:
    if idx == 0:
      return TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)
    else:
      raise newException(TernaryTreeError, fmt"Cannot get from leaf with index {idx}")

  let leftSize = tree.left.len
  let middleSize = tree.middle.len
  let rightSize = tree.right.len

  if leftSize + middleSize + rightSize != tree.size:
    raise newException(TernaryTreeError, "tree.size does not match sum of branch sizes")

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
    raise newException(TernaryTreeError, "dissoc does not work on nil")

  if idx < 0:
    raise newException(TernaryTreeError, fmt"Index is negative {idx}")

  if tree.len == 0:
    raise newException(TernaryTreeError, "Cannot remove from empty list")

  if idx > tree.len - 1:
    raise newException(TernaryTreeError, fmt"Index too large {idx}")

  if tree.len == 1:
    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: 0,
      depth: 1,
      left: nil,
      middle: nil,
      right: nil
    )

  if tree.kind == ternaryTreeLeaf:
    raise newException(TernaryTreeError, "dissoc should be handled at branches")

  let leftSize = tree.left.len
  let middleSize = tree.middle.len
  let rightSize = tree.right.len

  if leftSize + middleSize + rightSize != tree.size:
    raise newException(TernaryTreeError, "tree.size does not match sum of branch sizes")

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
    result = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: result.loopGet(0))

  return result

proc rest*[T](tree: TernaryTreeList[T]): TernaryTreeList[T] =
  if tree.isNil:
    raise newException(TernaryTreeError, "Cannot call rest on nil")
  if tree.len < 1:
    raise newException(TernaryTreeError, "Cannot call rest on empty list")

  tree.dissoc(0)

proc butlast*[T](tree: TernaryTreeList[T]): TernaryTreeList[T] =
  if tree.isNil:
    raise newException(TernaryTreeError, "Cannot call butlast on nil")
  if tree.len < 1:
    raise newException(TernaryTreeError, "Cannot call butlast on empty list")

  tree.dissoc(tree.len - 1)

proc insert*[T](tree: TernaryTreeList[T], idx: int, item: T, after: bool = false): TernaryTreeList[T] =
  if tree.isNil:
    raise newException(TernaryTreeError, "Cannot insert into nil")
  if tree.len == 0:
    raise newException(TernaryTreeError, "Empty node is not a correct position for inserting")

  if tree.kind == ternaryTreeLeaf:
    if after:
      return TernaryTreeList[T](
        kind: ternaryTreeBranch,
        depth: tree.getDepth + 1,
        size: 2,
        left: tree,
        middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
        right: nil
      )
    else:

      return TernaryTreeList[T](
        kind: ternaryTreeBranch,
        depth: tree.getDepth + 1,
        size: 2,
        left: nil,
        middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
        right: tree
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
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          size: 2,
          depth: 2,
          left: tree.right,
          middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
          right: nil
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
      else:
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          size: 2,
          depth: tree.middle.getDepth + 1,
          left: nil,
          middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
          right: tree.left
        )

  if tree.len == 2:
    if after:
      if tree.right.isNil:
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          size: 3,
          depth: 2,
          left: tree.left,
          middle: tree.middle,
          right: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)
        )
      elif tree.middle.isNil:
        if idx == 0:
          return TernaryTreeList[T](
            kind: ternaryTreeBranch,
            size: 3,
            depth: 2,
            left: tree.left,
            middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
            right: tree.right
          )
        elif idx == 1:
          return TernaryTreeList[T](
            kind: ternaryTreeBranch,
            size: 3,
            depth: 2,
            left: tree.left,
            middle: tree.right,
            right: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)
          )
        else:
          raise newException(TernaryTreeError, fmt"Unexpected idx: {idx}")
      else:
        if idx == 0:
          return TernaryTreeList[T](
            kind: ternaryTreeBranch,
            size: 3,
            depth: 2,
            left: tree.middle,
            middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
            right: tree.right
          )
        elif idx == 1:
          return TernaryTreeList[T](
            kind: ternaryTreeBranch,
            size: 3,
            depth: 2,
            left: tree.middle,
            middle: tree.right,
            right: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)
          )
        else:
          raise newException(TernaryTreeError, fmt"Unexpected idx: {idx}")
    else:
      if tree.left.isNil:
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          size: 3,
          depth: 2,
          left: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
          middle: tree.middle,
          right: tree.right
        )
      elif tree.middle.isNil:
        if idx == 0:
          return TernaryTreeList[T](
            kind: ternaryTreeBranch,
            size: 3,
            depth: 2,
            left: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
            middle: tree.left,
            right: tree.right
          )
        elif idx == 1:
          return TernaryTreeList[T](
            kind: ternaryTreeBranch,
            size: 3,
            depth: 2,
            left: tree.left,
            middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
            right: tree.right
          )
        else:
          raise newException(TernaryTreeError, fmt"Unexpected idx: {idx}")
      else:
        if idx == 0:
          return TernaryTreeList[T](
            kind: ternaryTreeBranch,
            size: 3,
            depth: 2,
            left: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
            middle: tree.left,
            right: tree.middle
          )
        elif idx == 1:
          return TernaryTreeList[T](
            kind: ternaryTreeBranch,
            size: 3,
            depth: 2,
            left: tree.left,
            middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
            right: tree.middle
          )
        else:
          raise newException(TernaryTreeError, fmt"Unexpected idx: {idx}")

  let leftSize = tree.left.len
  let middleSize = tree.middle.len
  let rightSize = tree.right.len

  if leftSize + middleSize + rightSize != tree.size:
    raise newException(TernaryTreeError, "tree.size does not match sum of branch sizes")


  # echo "picking: ", idx, " ", leftSize, " ", middleSize, " ", rightSize

  if idx == 0 and not after:
    if tree.left.len >= tree.middle.len and tree.left.len >= tree.right.len:
      return TernaryTreeList[T](
        kind: ternaryTreeBranch,
        size: tree.size + 1,
        depth: tree.depth + 1,
        left: nil,
        middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
        right: tree
      )

  if idx == tree.len - 1 and after:
    if tree.right.len >= tree.middle.len and tree.right.len >= tree.left.len:
      return TernaryTreeList[T](
        kind: ternaryTreeBranch,
        size: tree.size + 1,
        depth: tree.depth + 1,
        left: tree,
        middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
        right: nil
      )

  if after and idx == tree.len - 1 and rightSize == 0 and middleSize >= leftSize:
    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size + 1,
      depth: tree.depth,
      left: tree.left,
      middle: tree.middle,
      right: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item)
    )

  if not after and idx == 0 and leftSize == 0 and middleSize >= rightSize:
    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size + 1,
      depth: tree.depth,
      left: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, value: item),
      middle: tree.middle,
      right: tree.right
    )

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
  var ys = tree.toLeavesSeq()
  let newTree = initTernaryTreeList(ys.len, 0.int, ys)
  # let newTree = initTernaryTreeList(ys)
  tree.left = newTree.left
  tree.middle = newTree.middle
  tree.right = newTree.right
  tree.depth = decideParentDepth(tree.left, tree.middle, tree.right)

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
    if xs.loopGet(idx) != ys.loopGet(idx):
      return false

  return true

proc checkStructure*[T](tree: TernaryTreeList[T]): bool =
  if tree.isNil:
    return true
  case tree.kind
  of ternaryTreeLeaf:
    if tree.size != 1:
      raise newException(TernaryTreeError, fmt"Bad size at node {tree.formatInline}")
  of ternaryTreeBranch:
    if tree.size != tree.left.len + tree.middle.len + tree.right.len:
      raise newException(TernaryTreeError, fmt"Bad size at branch {tree.formatInline}")

    if tree.depth != decideParentDepth(tree.left, tree.middle, tree.right):
      let x = decideParentDepth(tree.left, tree.middle, tree.right)
      raise newException(TernaryTreeError, fmt"Bad depth at branch {tree.formatInline}")

    discard tree.left.checkStructure
    discard tree.middle.checkStructure
    discard tree.right.checkStructure

  return true

# excludes value at endIdx, kept aligned with JS & Clojure
proc slice*[T](tree: TernaryTreeList[T], startIdx: int, endIdx: int): TernaryTreeList[T] =
  # echo fmt"slice {tree.formatInline}: {startIdx}..{endIdx}"
  if endIdx > tree.len:
    raise newException(TernaryTreeError, fmt"Slice range too large {endIdx} for {tree}")
  if startIdx < 0:
    raise newException(TernaryTreeError, fmt"Slice range too small {startIdx} for {tree}")
  if startIdx > endIdx:
    raise newException(TernaryTreeError, fmt"Invalid slice range {startIdx}..{endIdx} for {tree}")
  if startIdx == endIdx:
    return TernaryTreeList[T](kind: ternaryTreeBranch, size: 0, depth: 0)

  if tree.kind == ternaryTreeLeaf:
    if startIdx == 0 and endIdx == 1:
      return tree
    else:
      raise newException(TernaryTreeError, fmt"Invalid slice range for a leaf: {startIdx} {endIdx}")

  if startIdx == 0 and endIdx == tree.len:
    return tree

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
    return tree
  of ternaryTreeBranch:
    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size,
      depth: tree.depth,
      left: tree.right.reverse,
      middle: tree.middle.reverse,
      right: tree.left.reverse
    )
