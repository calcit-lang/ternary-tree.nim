
import strformat
import math

import ternary_tree/types
import ternary_tree/map

export TernaryTreeList, TernaryTreeKind
export initTernaryTreeMap, `$`, formatInline, toSortedSeq, contains, get, checkStructure, assoc, dissoc, len

proc initTernaryTreeList*[T](xs: seq[T]): TernaryTreeList[T] =
  let size = xs.len

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
  if tree.isNil:
    0
  else:
    tree.size

proc formatInline*(tree: TernaryTreeList): string =
  if tree.isNil:
    return "_"
  case tree.kind
  of ternaryTreeLeaf:
    $tree.value
  of ternaryTreeBranch:
    "(" & tree.left.formatInline & " " & tree.middle.formatInline & " " & tree.right.formatInline & ")"

proc toSeq*[T](tree: TernaryTreeList[T]): seq[T] =
  var acc: seq[T] = @[]
  if tree.isNil:
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

  var leftSize = tree.left.len
  var middleSize = tree.middle.len
  var rightSize = tree.right.len

  if leftSize + middleSize + rightSize != tree.size:
    raise newException(ValueError, "tree.size does not match sum of branch sizes")

  if idx <= leftSize - 1:
    return tree.left.get(idx)
  elif idx <= leftSize + middleSize - 1:
    return tree.middle.get(idx - leftSize)
  else:
    return tree.right.get(idx - leftSize - middleSize)

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
      return TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: item)
    else:
      raise newException(ValueError, fmt"Cannot get from leaf with index {idx}")

  var leftSize = tree.left.len
  var middleSize = tree.middle.len
  var rightSize = tree.right.len

  if leftSize + middleSize + rightSize != tree.size:
    raise newException(ValueError, "tree.size does not match sum of branch sizes")

  if idx <= leftSize - 1:
    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size, depth: tree.depth,
      left: tree.left.assoc(idx, item),
      middle: tree.middle,
      right: tree.right
    )
  elif idx <= leftSize + middleSize - 1:
    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size, depth: tree.depth,
      left: tree.left,
      middle: tree.middle.assoc(idx - leftSize, item),
      right: tree.right
    )
  else:
    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size, depth: tree.depth,
      left: tree.left,
      middle: tree.middle,
      right: tree.right.assoc(idx - leftSize - middleSize, item)
    )

proc calculateDepth*[T](tree: TernaryTreeList[T]): int =
  if tree.isNil:
    0
  else:
    tree.depth

proc maxDepthOf3[T](left: TernaryTreeList[T], middle: TernaryTreeList[T], right: TernaryTreeList[T]): int =
  max(@[left.calculateDepth, middle.calculateDepth, right.calculateDepth])

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
      kind: ternaryTreeBranch, size: 0, depth: 1,
      left: nil,
      middle: nil,
      right: nil
    )

  if tree.kind == ternaryTreeLeaf:
    raise newException(ValueError, "dissoc should be handled at branches")

  var leftSize = tree.left.len
  var middleSize = tree.middle.len
  var rightSize = tree.right.len

  if leftSize + middleSize + rightSize != tree.size:
    raise newException(ValueError, "tree.size does not match sum of branch sizes")

  if idx <= leftSize - 1:
    var changedChild = tree.left.dissoc(idx)
    let newDepth = maxDepthOf3(changedChild, tree.middle, tree.right) + 1
    if changedChild.size == 0:
      changedChild = nil
    result = TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size - 1, depth: newDepth,
      left: changedChild,
      middle: tree.middle,
      right: tree.right
    )
  elif idx <= leftSize + middleSize - 1:
    var changedChild = tree.middle.dissoc(idx - leftSize)
    let newDepth = maxDepthOf3(tree.left, changedChild, tree.right) + 1
    if changedChild.size == 0:
      changedChild = nil
    result = TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size - 1, depth: newDepth,
      left: tree.left,
      middle: changedChild,
      right: tree.right
    )
  else:
    var changedChild = tree.right.dissoc(idx - leftSize - middleSize)
    let newDepth = maxDepthOf3(tree.left, tree.middle, changedChild) + 1
    if changedChild.size == 0:
      changedChild = nil
    result = TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size - 1, depth: newDepth,
      left: tree.left,
      middle: tree.middle,
      right: changedChild
    )

  if result.len == 1:
    result = TernaryTreeList[T](kind: ternaryTreeLeaf, depth: 1, size: 1, value: result.get(0))

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
      right = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: item)
    else:
      left = TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: item)

    return TernaryTreeList[T](
      kind: ternaryTreeBranch,
      depth: 2,
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
          depth: tree.depth,
          size: 2,
          left: tree.left,
          middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: item),
          right: nil
        )
      elif tree.middle != nil:
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          depth: tree.depth,
          size: 2,
          left: nil,
          middle: tree.middle,
          right: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: item)
        )
    else:
      if tree.right != nil:
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          depth: tree.depth,
          size: 2,
          left: nil,
          middle: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: item),
          right: tree.right
        )
      elif tree.middle != nil:
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          depth: tree.depth,
          size: 2,
          left: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: item),
          middle: tree.middle,
          right: nil
        )

  if tree.len == 2:
    if after:
      if tree.right.isNil:
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          depth: tree.depth,
          size: 3,
          left: tree.left,
          middle: tree.middle,
          right: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: item)
        )

    else:
      if tree.left.isNil:
        return TernaryTreeList[T](
          kind: ternaryTreeBranch,
          depth: tree.depth,
          size: 3,
          left: TernaryTreeList[T](kind: ternaryTreeLeaf, size: 1, depth: 1, value: item),
          middle: tree.middle,
          right: tree.right
        )

  var leftSize = tree.left.len
  var middleSize = tree.middle.len
  var rightSize = tree.right.len

  if leftSize + middleSize + rightSize != tree.size:
    raise newException(ValueError, "tree.size does not match sum of branch sizes")


  # echo "picking: ", idx, " ", leftSize, " ", middleSize, " ", rightSize

  if idx <= leftSize - 1:
    let changedChild = tree.left.insert(idx, item, after)
    let newDepth = maxDepthOf3(changedChild, tree.middle, tree.right) + 1

    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size + 1, depth: newDepth,
      left: changedChild,
      middle: tree.middle,
      right: tree.right
    )
  elif idx <= leftSize + middleSize - 1:
    let changedChild = tree.middle.insert(idx - leftSize, item, after)
    let newDepth = maxDepthOf3(tree.left, changedChild, tree.right) + 1

    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size + 1, depth: newDepth,
      left: tree.left,
      middle: changedChild,
      right: tree.right
    )
  else:
    let changedChild = tree.right.insert(idx - leftSize - middleSize, item, after)
    let newDepth = maxDepthOf3(tree.left, tree.middle, changedChild) + 1

    return TernaryTreeList[T](
      kind: ternaryTreeBranch, size: tree.size + 1, depth: newDepth,
      left: tree.left,
      middle: tree.middle,
      right: changedChild
    )

proc assocBefore*[T](tree: TernaryTreeList[T], idx: int, item: T, after: bool = false): TernaryTreeList[T] =
  insert(tree, idx, item, false)

proc assocAfter*[T](tree: TernaryTreeList[T], idx: int, item: T, after: bool = false): TernaryTreeList[T] =
  insert(tree, idx, item, true)

# this function mutates original tree to make it more balanced
proc forceInplaceBalancing*[T](tree: TernaryTreeList[T]): void =
  # echo "Force inplace balancing of list"
  let xs = tree.toSeq
  let newTree = initTernaryTreeList(xs)
  tree.left = newTree.left
  tree.middle = newTree.middle
  tree.right = newTree.right

proc roughIntPow(x: int, times: int): int =
  if times < 1:
    return x

  result = 1
  for idx in 0..<times:
    result = result * x

proc prepend*[T](tree: TernaryTreeList[T], item: T, disableBalancing: bool = false): TernaryTreeList[T] =
  if tree.isNil or tree.len == 0:
    return TernaryTreeList[T](kind: ternaryTreeLeaf, depth: 1, size: 1, value: item)
  result = insert(tree, 0, item, false)

  if (not disableBalancing) and result.depth > 27:
    if 3.roughIntPow(result.depth - 9) > result.size:
      result.forceInplaceBalancing

proc append*[T](tree: TernaryTreeList[T], item: T, disableBalancing: bool = false): TernaryTreeList[T] =
  if tree.isNil or tree.len == 0:
    return TernaryTreeList[T](kind: ternaryTreeLeaf, depth: 1, size: 1, value: item)
  result = insert(tree, tree.len - 1, item, true)

  if (not disableBalancing) and result.depth > 27:
    if 3.roughIntPow(result.depth - 9) > result.size:
      result.forceInplaceBalancing

proc concat*[T](xs: TernaryTreeList[T], ys: TernaryTreeList[T]): TernaryTreeList[T] =
  if xs.isNil or xs.len == 0:
    return ys
  if ys.isNil or ys.len == 0:
    return xs
  let newDepth = max(xs.calculateDepth, ys.calculateDepth) + 1
  return TernaryTreeList[T](
    kind: ternaryTreeBranch, size: xs.size + ys.size, depth: newDepth,
    left: xs,
    middle: nil,
    right: ys
  )

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

  if xs.depth != ys.depth:
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

proc `==`*[T](xs: TernaryTreeList[T], ys: TernaryTreeList[T]): bool =
  if xs.len != ys.len:
    return false

  for idx in 0..<xs.len:
    if xs.get(idx) != ys.get(idx):
      return false

  return true

# TODO hash for fast comparing

# TODO slice
