
import tables
import options
import math
import hashes
import strformat
import algorithm

import ./types

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
      middle: TernaryTreeMap[K, T](
        kind: ternaryTreeLeaf, size: 1, depth: 1,
        hash: hashVal, key: middlePair.k, value: middlePair.v
      )
    )
  of 2:
    let leftPair = xs[0]
    let rightPair = xs[1]
    let leftHashVal = leftPair.k.hash
    let rightHashVal = rightPair.k.hash
    TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: 2, depth: 2,
      maxHash: max(@[leftHashVal, rightHashVal]),
      minHash: min(@[leftHashVal, rightHashVal]),
      middle: nil,
      left: TernaryTreeMap[K, T](
        kind: ternaryTreeLeaf, size: 1, depth: 1,
        hash: leftHashVal, key: leftPair.k, value: leftPair.v
      ),
      right: TernaryTreeMap[K, T](
        kind: ternaryTreeLeaf, size: 1, depth: 1,
        hash: rightHashVal, key: rightPair.k, value: rightPair.v
      ),
    )
  of 3:
    let leftPair = xs[0]
    let middlePair = xs[1]
    let rightPair = xs[2]
    let leftHashVal = leftPair.k.hash
    let middleHashVal = middlePair.k.hash
    let rightHashVal = rightPair.k.hash
    TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, size: 3, depth: 2,
      maxHash: max(@[leftHashVal, middleHashVal, rightHashVal]),
      minHash: min(@[leftHashVal, middleHashVal, rightHashVal]),
      left: TernaryTreeMap[K, T](
        kind: ternaryTreeLeaf, size: 1, depth: 1,
        hash: leftHashVal, key: leftPair.k, value: leftPair.v
      ),
      middle: TernaryTreeMap[K, T](
        kind: ternaryTreeLeaf, size: 1, depth: 1,
        hash: leftHashVal, key: middlePair.k, value: middlePair.v
      ),
      right: TernaryTreeMap[K, T](
        kind: ternaryTreeLeaf, size: 1, depth: 1,
        hash: rightHashVal, key: rightPair.k, value: rightPair.v
      ),
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
      maxHash: max(@[left.getMax, middle.getMax, right.getMax]),
      minHash: max(@[left.getMin, middle.getMin, right.getMin]),
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

proc formatInline*(tree: TernaryTreeMap): string =
  if tree.isNil:
    return "_"
  case tree.kind
  of ternaryTreeLeaf:
    fmt"{tree.hash}->{tree.key}:{tree.value}"
  of ternaryTreeBranch:
    "(" & tree.left.formatInline & " " & tree.middle.formatInline & " " & tree.right.formatInline & ")"

# sorted by hash(tree.key)
proc toSortedSeq*[K, T](tree: TernaryTreeMap[K, T]): seq[TernaryTreeMapKeyValuePair[K, T]] =

  if tree.isNil or tree.len == 0:
    return @[]

  if tree.kind == ternaryTreeLeaf:
    return @[(tree.key, tree.value)]

  var acc: seq[TernaryTreeMapKeyValuePair[K, T]]

  for item in tree.left.toSortedSeq:
    acc.add item

  for item in tree.middle.toSortedSeq:
    acc.add item

  for item in tree.right.toSortedSeq:
    acc.add item

  return acc

proc contains*[K, T](tree: TernaryTreeMap[K, T], item: K): bool =
  let hx = item.hash
  # echo "looking for: ", hx, " ", item
  if not tree.left.isNil:
    if tree.left.kind == ternaryTreeLeaf:
      return tree.left.hash == hx:
    elif hx >= tree.left.minHash and hx <= tree.left.maxHash:
      return tree.left.contains(item)

  if not tree.middle.isNil:
    if tree.middle.kind == ternaryTreeLeaf:
      return tree.middle.hash == hx:
    elif hx >= tree.middle.minHash and hx <= tree.middle.maxHash:
      return tree.middle.contains(item)

  if not tree.right.isNil:
    if tree.right.kind == ternaryTreeLeaf:
      return tree.right.hash == hx:
    elif hx >= tree.right.minHash and hx <= tree.right.maxHash:
      return tree.right.contains(item)

  return false

proc get*[K, T](tree: TernaryTreeMap[K, T], item: K): Option[T] =
  let hx = item.hash
  # echo "looking for: ", hx, " ", item
  if not tree.left.isNil:
    if tree.left.kind == ternaryTreeLeaf:
      if tree.left.hash == hx:
        return some(tree.left.value)
      else:
        return none(T)
    elif hx >= tree.left.minHash and hx <= tree.left.maxHash:
      return tree.left.get(item)

  if not tree.middle.isNil:
    if tree.middle.kind == ternaryTreeLeaf:
      if tree.middle.hash == hx:
        return some(tree.middle.value)
      else:
        return none(T)
    elif hx >= tree.middle.minHash and hx <= tree.middle.maxHash:
      return tree.middle.get(item)

  if not tree.right.isNil:
    if tree.right.kind == ternaryTreeLeaf:
      if tree.right.hash == hx:
        return some(tree.right.value)
      else:
        return none(T)
    elif hx >= tree.right.minHash and hx <= tree.right.maxHash:
      return tree.right.get(item)

  return none(T)


# TODO contains
# TODO get
# TODO assoc
# TODO dissoc
# TODO merge
# TODO items
