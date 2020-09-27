
import tables
import options
import math
import hashes
import strformat
import algorithm

import ./types
import ./utils

type TernaryTreeMapKeyValuePair[K, V] = tuple
  k: K
  v: V

proc getMax(tree: TernaryTreeMap): int =
  if tree.isNil:
    raise newException(ValueError, "Cannot find max hash of nil")
  case tree.kind
  of ternaryTreeLeaf:
    tree.value
  of ternaryTreeBranch:
    tree.maxHash

proc getMin(tree: TernaryTreeMap): int =
  if tree.isNil:
    raise newException(ValueError, "Cannot find min hash of nil")
  case tree.kind
  of ternaryTreeLeaf:
    tree.value
  of ternaryTreeBranch:
    tree.minHash

proc createLeaf[K, T](k: K, v: T): TernaryTreeMap[K, T] =
  TernaryTreeMap[K, T](
    kind: ternaryTreeLeaf, size: 1, depth: 1,
    hash: k.hash, key: k, value: v
  )

proc createLeaf[K, T](item: TernaryTreeMapKeyValuePair[K, T]): TernaryTreeMap[K, T] =
  TernaryTreeMap[K, T](
    kind: ternaryTreeLeaf, size: 1, depth: 1,
    hash: item.k.hash, key: item.k, value: item.v
  )

# this proc is not exported, pick up next proc as the entry.
# pairs must be sorted before passing to proc.
proc initTernaryTreeMap[K, T](xs: seq[TernaryTreeMapKeyValuePair[K, T]]): TernaryTreeMap[K, T] =
  let size = xs.len

  case size
  of 0:
    TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: 0, depth: 1, maxHash: 0, minHash: 0,
      left: nil, middle: nil, right: nil
    )
  of 1:
    let middlePair = xs[0]
    let hashVal = middlePair.k.hash
    TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: 1, depth: 2, maxHash: hashVal, minHash: hashVal,
      left: nil, right: nil,
      middle: createLeaf(middlePair)
    )
  of 2:
    let leftPair = xs[0]
    let rightPair = xs[1]
    TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: 2, depth: 2,
      maxHash: rightPair.k.hash,
      minHash: leftPair.k.hash,
      middle: nil,
      left: createLeaf(leftPair),
      right:  createLeaf(rightPair),
    )
  of 3:
    let leftPair = xs[0]
    let middlePair = xs[1]
    let rightPair = xs[2]
    TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: 3, depth: 2,
      maxHash: rightPair.k.hash,
      minHash: leftPair.k.hash,
      left: createLeaf(leftPair),
      middle: createLeaf(middlePair),
      right: createLeaf(rightPair),
    )
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

    let left = initTernaryTreeMap(xs[0..<leftSize])
    let middle = initTernaryTreeMap(xs[leftSize..<(leftSize + middleSize)])
    let right = initTernaryTreeMap(xs[(leftSize + middleSize)..^1])

    let parentDepth = max(@[left.depth, middle.depth, right.depth]) + 1
    TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: size, depth: parentDepth,
      maxHash: right.getMax,
      minHash: left.getMin,
      left: left, middle: middle, right: right
    )

proc initTernaryTreeMap*[K, T](t: Table[K, T]): TernaryTreeMap[K, T] =
  var xs: seq[TernaryTreeMapKeyValuePair[K, T]]

  for k, v in t:
    xs.add((k,v))

  let ys = xs.sorted(proc(x, y: TernaryTreeMapKeyValuePair[K, T]): int =
    let hx = x.k.hash
    let hy = y.k.hash
    cmp(hx, hy)
  )

  initTernaryTreeMap(ys)

proc `$`*(tree: TernaryTreeMap): string =
  fmt"TernaryTreeMap[{tree.size}, {tree.depth}]"

proc len*(tree: TernaryTreeMap): int =
  if tree.isNil:
    0
  else:
    tree.size

proc formatInline*(tree: TernaryTreeMap, withHash: bool = false): string =
  if tree.isNil:
    return "_"
  case tree.kind
  of ternaryTreeLeaf:
    if withHash:
      fmt"{tree.hash}->{tree.key}:{tree.value}"
    else:
      fmt"{tree.key}:{tree.value}"
  of ternaryTreeBranch:
    "(" & tree.left.formatInline(withHash) & " " & tree.middle.formatInline(withHash) & " " & tree.right.formatInline(withHash) & ")"

# sorted by hash(tree.key)
proc toHashSortedSeq*[K, T](tree: TernaryTreeMap[K, T]): seq[TernaryTreeMapKeyValuePair[K, T]] =
  if tree.isNil or tree.len == 0:
    return @[]
  if tree.kind == ternaryTreeLeaf:
    return @[(tree.key, tree.value)]

  var acc: seq[TernaryTreeMapKeyValuePair[K, T]]

  for item in tree.left.toHashSortedSeq:
    acc.add item
  for item in tree.middle.toHashSortedSeq:
    acc.add item
  for item in tree.right.toHashSortedSeq:
    acc.add item

  return acc

proc contains*[K, T](tree: TernaryTreeMap[K, T], item: K): bool =
  if tree.isNil:
    return false

  let hx = item.hash
  # echo "looking for: ", hx, " ", item, " in ", tree.formatInline(true)
  if not tree.left.isNil:
    if tree.left.kind == ternaryTreeLeaf:
      if tree.left.hash == hx:
        return true
    elif hx >= tree.left.minHash and hx <= tree.left.maxHash:
      return tree.left.contains(item)

  if not tree.middle.isNil:
    if tree.middle.kind == ternaryTreeLeaf:
      if tree.middle.hash == hx:
        return true
    elif hx >= tree.middle.minHash and hx <= tree.middle.maxHash:
      return tree.middle.contains(item)

  if not tree.right.isNil:
    # echo "right..."
    if tree.right.kind == ternaryTreeLeaf:
      if tree.right.hash == hx:
        return true
    elif hx >= tree.right.minHash and hx <= tree.right.maxHash:
      return tree.right.contains(item)

  return false

proc get*[K, T](tree: TernaryTreeMap[K, T], item: K): Option[T] =
  let hx = item.hash
  # echo "looking for: ", hx, " ", item, " in ", tree.formatInline
  if not tree.left.isNil:
    if tree.left.kind == ternaryTreeLeaf:
      if tree.left.hash == hx:
        return some(tree.left.value)
    elif hx >= tree.left.minHash and hx <= tree.left.maxHash:
      return tree.left.get(item)

  if not tree.middle.isNil:
    if tree.middle.kind == ternaryTreeLeaf:
      if tree.middle.hash == hx:
        return some(tree.middle.value)
    elif hx >= tree.middle.minHash and hx <= tree.middle.maxHash:
      return tree.middle.get(item)

  if not tree.right.isNil:
    if tree.right.kind == ternaryTreeLeaf:
      if tree.right.hash == hx:
        return some(tree.right.value)
    elif hx >= tree.right.minHash and hx <= tree.right.maxHash:
      return tree.right.get(item)

  return none(T)

# leaves on the left has smaller hashes
# TODO check sizes, depth, hashes
proc checkStructure*(tree: TernaryTreeMap): bool =
  let xs = tree.toHashSortedSeq
  if xs.len <= 1:
    return true
  var x0 = xs[0]
  let xRest = xs[1..^1]
  for item in xRest:
    if x0.k.hash > item.k.hash:
      return false
    x0 = item
  return true

proc rangeContainsHash*[K, T](tree: TernaryTreeMap[K, T], thisHash: Hash): bool =
  if tree.isNil:
    false
  elif tree.kind == ternaryTreeLeaf:
    tree.hash == thisHash
  else:
    thisHash >= tree.getMin and thisHash <= tree.getMax

proc assocExisted*[K, T](tree: TernaryTreeMap[K, T], key: K, item: T): TernaryTreeMap[K, T] =
  if tree.isNil or tree.len == 0:
    raise newException(ValueError, "Cannot call assoc on nil")

  let thisHash = key.hash

  if tree.kind == ternaryTreeLeaf:
    if key == tree.key:
      if item == tree.value:
        return tree
      else:
        return createLeaf(key, item)
    else:
      raise newException(ValueError, "Unexpected missing hash in assoc, invalid branch")

  if thisHash < tree.minHash:
    raise newException(ValueError, "Unexpected missing hash in assoc, hash too small")

  elif thisHash > tree.maxHash:
    raise newException(ValueError, "Unexpected missing hash in assoc, hash too large")

  if not tree.left.isNil:
    if tree.left.rangeContainsHash(thisHash):
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch, size: tree.size, depth: tree.depth,
        maxHash: tree.maxHash,
        minHash: tree.minHash,
        left: tree.left.assocExisted(key, item),
        middle: tree.middle,
        right: tree.right
      )

  if not tree.middle.isNil:
    if tree.middle.rangeContainsHash(thisHash):
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch, size: tree.size, depth: tree.depth,
        maxHash: tree.maxHash,
        minHash: tree.minHash,
        left: tree.left,
        middle: tree.middle.assocExisted(key, item),
        right: tree.right
      )

  if not tree.right.isNil:
    if tree.right.rangeContainsHash(thisHash):
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch, size: tree.size, depth: tree.depth,
        maxHash: tree.maxHash,
        minHash: tree.minHash,
        left: tree.left,
        middle: tree.middle,
        right: tree.right.assocExisted(key, item)
      )
  else:
    raise newException(ValueError, "Unexpected missing hash in assoc, found not branch")

proc isSome*[K, T](tree: TernaryTreeMap[K, T]): bool =
  if tree.isNil:
    false
  else:
    true

proc assocNew*[K, T](tree: TernaryTreeMap[K, T], key: K, item: T): TernaryTreeMap[K, T] =
  # echo fmt"assoc new: {key} to {tree.formatInline}"
  if tree.isNil or tree.len == 0:
    return createLeaf(key, item)

  let thisHash = key.hash

  if tree.kind == ternaryTreeLeaf:
    if key == tree.key:
      raise newException(ValueError, "Unexpected existed key in assoc")
    else:
      if thisHash > tree.hash:
        return TernaryTreeMap[K, T](
          kind: ternaryTreeBranch, size: 2, depth: 2, maxHash: thisHash, minHash: tree.hash,
          left: nil,
          middle: tree,
          right: createLeaf(key, item),
        )
      else:
        return TernaryTreeMap[K, T](
          kind: ternaryTreeBranch, size: 2, depth: 2, maxHash: tree.hash, minHash: thisHash,
          left: createLeaf(key, item),
          middle: tree,
          right: nil,
        )

  if thisHash < tree.minHash:
    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: tree.size + 1, depth: tree.depth + 1,
      maxHash: tree.maxHash, minHash: thisHash,
      left: createLeaf(key, item),
      middle: tree,
      right: nil,
    )

  if thisHash > tree.maxHash:
    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: tree.size + 1, depth: tree.depth + 1,
      maxHash: thisHash, minHash: tree.minHash,
      left: nil,
      middle: tree,
      right: createLeaf(key, item),
    )

  if tree.left.rangeContainsHash(thisHash):
    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: tree.size + 1, depth: tree.depth,
      maxHash: tree.maxHash,
      minHash: tree.minHash,
      left: tree.left.assocNew(key, item),
      middle: tree.middle,
      right: tree.right
    )
  if tree.middle.rangeContainsHash(thisHash):
    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: tree.size + 1, depth: tree.depth,
      maxHash: tree.maxHash,
      minHash: tree.minHash,
      left: tree.left,
      middle: tree.middle.assocNew(key, item),
      right: tree.right
    )
  if tree.middle.rangeContainsHash(thisHash):
    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: tree.size + 1, depth: tree.depth,
      maxHash: tree.maxHash,
      minHash: tree.minHash,
      left: tree.left,
      middle: tree.middle,
      right: tree.right.assocNew(key, item)
    )

  if tree.middle.isSome:
    if thisHash < tree.middle.getMin:
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch, size: tree.size + 1, depth: tree.depth,
        maxHash: tree.maxHash,
        minHash: tree.minHash,
        left: tree.left.assocNew(key, item),
        middle: tree.middle,
        right: tree.right
      )
    else:
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch, size: tree.size + 1, depth: tree.depth,
        maxHash: tree.maxHash,
        minHash: tree.minHash,
        left: tree.left,
        middle: tree.middle,
        right: tree.right.assocNew(key, item)
      )

  # not outbound, not at any branch, and middle is empty, so put in middle
  return TernaryTreeMap[K, T](
    kind: ternaryTreeBranch, size: tree.size + 1, depth: tree.depth,
    maxHash: tree.maxHash,
    minHash: tree.minHash,
    left: tree.left,
    middle: tree.middle.assocNew(key, item),
    right: tree.right
  )

proc assoc*[K, T](tree: TernaryTreeMap[K, T], key: K, item: T, disableBalancing: bool = false): TernaryTreeMap[K, T] =
  if tree.isNil or tree.len == 0:
    return createLeaf(key, item)

  if tree.contains(key):
    result = tree.assocExisted(key, item)
  else:
    result = tree.assocNew(key, item)

  if (not disableBalancing) and result.depth > 27:
    if 3.roughIntPow(result.depth - 9) > result.size:
      result.forceInplaceBalancing

proc getDepth*(tree: TernaryTreeMap): int =
  if tree.isNil:
    0
  else:
    tree.depth

proc maxDepthOf3(left: TernaryTreeMap, middle: TernaryTreeMap, right: TernaryTreeMap): int =
  max(@[left.getDepth, middle.getDepth, right.getDepth])

proc dissocExisted*[K, T](tree: TernaryTreeMap[K, T], key: K): TernaryTreeMap[K, T] =
  if tree.isNil:
    raise newException(ValueError, "Unexpected missing key in dissoc")

  if tree.kind == ternaryTreeLeaf:
    if tree.key == key:
      return nil
    else:
      raise newException(ValueError, "Unexpected missing key in dissoc on leaf")

  if tree.len == 1:
    if not tree.contains(key):
      raise newException(ValueError, "Unexpected missing key in dissoc single branch")
    return nil

  let thisHash = key.hash

  if tree.left.rangeContainsHash(thisHash):
    let changedBranch = tree.left.dissocExisted(key)
    let nextDepth = maxDepthOf3(changedBranch, tree.middle, tree.right)

    var minHash: int
    if not changedBranch.isNil:
      minHash = changedBranch.getMin
    elif not tree.middle.isNil:
      minHash = tree.middle.getMin
    else:
      minHash = tree.right.getMin

    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: tree.size - 1, depth: nextDepth,
      maxHash: tree.maxHash,
      minHash: minHash,
      left: changedBranch,
      middle: tree.middle,
      right: tree.right
    )

  if tree.middle.rangeContainsHash(thisHash):
    let changedBranch = tree.middle.dissocExisted(key)
    let nextDepth = maxDepthOf3(tree.left, changedBranch, tree.right)

    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: tree.size - 1, depth: nextDepth,
      maxHash: tree.getMax,
      minHash: tree.minHash,
      left: tree.left,
      middle: changedBranch,
      right: tree.right
    )

  if tree.right.rangeContainsHash(thisHash):
    let changedBranch = tree.right.dissocExisted(key)
    let nextDepth = maxDepthOf3(tree.left, tree.middle, changedBranch)

    var maxHash: int
    if not changedBranch.isNil:
      maxHash = changedBranch.getMax
    elif not tree.middle.isNil:
      maxHash = tree.middle.getMax
    else:
      maxHash = tree.left.getMax

    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: tree.size - 1, depth: nextDepth,
      maxHash: maxHash,
      minHash: tree.minHash,
      left: tree.left,
      middle: tree.middle,
      right: changedBranch
    )

  raise newException(ValueError, "Cannot find branch in dissoc")


proc dissoc*[K, T](tree: TernaryTreeMap[K, T], key: K): TernaryTreeMap[K, T] =
  if tree.contains(key):
    tree.dissocExisted(key)
  else:
    tree

proc toPairs*[K, T](tree: TernaryTreeMap[K, T]): seq[TernaryTreeMapKeyValuePair[K, T]] =
  if tree.isNil:
    return @[]
  if tree.kind == ternaryTreeLeaf:
    result.add((k: tree.key, v: tree.value))
  else:
    for item in tree.left.toPairs:
      result.add item
    for item in tree.middle.toPairs:
      result.add item
    for item in tree.right.toPairs:
      result.add item

proc keys*[K, T](tree: TernaryTreeMap[K, T]): seq[K] =
  if tree.isNil:
    return @[]
  if tree.kind == ternaryTreeLeaf:
    result.add(tree.key)
  else:
    for item in tree.left.keys:
      result.add item
    for item in tree.middle.keys:
      result.add item
    for item in tree.right.keys:
      result.add item

proc `$`*[K,V](p: TernaryTreeMapKeyValuePair[K, V]): string =
  fmt"{p.k}:{p.v}"

proc `==`*[K,V](xs: TernaryTreeMap[K, V], ys: TernaryTreeMap[K, V]): bool =
  if xs.len != ys.len:
    return false

  if xs.len == 0:
    return true

  let keys = xs.keys
  for key in keys:

    if xs.get(key) != ys.get(key):
      return false
  return true

proc merge*[K,V](xs: TernaryTreeMap[K, V], ys: TernaryTreeMap[K, V]): TernaryTreeMap[K, V] =
  result = xs
  for key in ys.keys:
    let item = ys.get(key)
    if item.isSome:
      result = result.assoc(key, ys.get(key).get)
    else:
      raise newException(ValueError, "Unexpected nil value during merge")

# this function mutates original tree to make it more balanced
proc forceInplaceBalancing*[K,T](tree: TernaryTreeMap[K,T]): void =
  # echo "Force inplace balancing of list"
  let xs = tree.toHashSortedSeq
  let newTree = initTernaryTreeMap(xs)
  tree.left = newTree.left
  tree.middle = newTree.middle
  tree.right = newTree.right

proc sameShape*[K,T](xs: TernaryTreeMap[K,T], ys: TernaryTreeMap[K,T]): bool =
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
    if xs.key != ys.key:
      return false
    elif xs.value != ys.value:
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

# TODO, do comparing faster
