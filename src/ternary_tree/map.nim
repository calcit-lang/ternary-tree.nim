
import tables
import options
import hashes
import strformat
import algorithm
import sequtils

import ./types
import ./utils

type TernaryTreeMapKeyValuePairOfLeaf[K, V] = tuple
  k: K
  v: TernaryTreeMap[K, V]

proc isLeaf(tree: TernaryTreeMap): bool =
  tree.kind == ternaryTreeLeaf

proc isBranch(tree: TernaryTreeMap): bool =
  tree.kind == ternaryTreeBranch

proc getMax(tree: TernaryTreeMap): int =
  if tree.isNil:
    raise newException(TernaryTreeError, "Cannot find max hash of nil")
  case tree.kind
  of ternaryTreeLeaf:
    tree.hash
  of ternaryTreeBranch:
    tree.maxHash

proc getMin(tree: TernaryTreeMap): int =
  if tree.isNil:
    raise newException(TernaryTreeError, "Cannot find min hash of nil")
  case tree.kind
  of ternaryTreeLeaf:
    tree.hash
  of ternaryTreeBranch:
    tree.minHash

proc getDepth*(tree: TernaryTreeMap): int =
  # echo "calling...", tree
  if tree.isNil:
    return 0
  case tree.kind
  of ternaryTreeLeaf:
    return 1
  else:
    return max(@[tree.left.getDepth, tree.middle.getDepth, tree.right.getDepth]) + 1

proc createLeaf[K, T](k: K, v: T): TernaryTreeMap[K, T] =
  TernaryTreeMap[K, T](
    kind: ternaryTreeLeaf,
    hash: k.hash,
    elements: @[(k: k, v: v)]
  )

proc createLeaf[K, T](item: TernaryTreeMapKeyValuePair[K, T]): TernaryTreeMap[K, T] =
  TernaryTreeMap[K, T](
    kind: ternaryTreeLeaf,
    hash: item.k.hash, elements: @[item]
  )

# this proc is not exported, pick up next proc as the entry.
# pairs must be sorted before passing to proc.
proc initTernaryTreeMap[K, T](size: int, offset: int, xs: var seq[TernaryTreeMapKeyValuePairOfLeaf[K, T]]): TernaryTreeMap[K, T] =
  case size
  of 0:
    TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, maxHash: 0, minHash: 0,
      left: nil, middle: nil, right: nil
    )
  of 1:
    let middlePair = xs[offset]
    let hashVal = middlePair.k.hash
    TernaryTreeMap[K, T](
      kind: ternaryTreeBranch, maxHash: hashVal, minHash: hashVal,
      left: nil, right: nil,
      middle: middlePair.v
    )
  of 2:
    let leftPair = xs[offset]
    let rightPair = xs[offset + 1]
    TernaryTreeMap[K, T](
      kind: ternaryTreeBranch,
      maxHash: rightPair.k.hash,
      minHash: leftPair.k.hash,
      middle: nil,
      left: leftPair.v,
      right:  rightPair.v,
    )
  of 3:
    let leftPair = xs[offset]
    let middlePair = xs[offset + 1]
    let rightPair = xs[offset + 2]
    TernaryTreeMap[K, T](
      kind: ternaryTreeBranch,
      maxHash: rightPair.k.hash,
      minHash: leftPair.k.hash,
      left: leftPair.v,
      middle: middlePair.v,
      right: rightPair.v,
    )
  else:
    let divided = divideTernarySizes(size)

    let left = initTernaryTreeMap(divided.left, offset, xs)
    let middle = initTernaryTreeMap(divided.middle, offset + divided.left, xs)
    let right = initTernaryTreeMap(divided.right, offset + divided.left + divided.middle,  xs)

    TernaryTreeMap[K, T](
      kind: ternaryTreeBranch,
      maxHash: right.getMax,
      minHash: left.getMin,
      left: left, middle: middle, right: right
    )

proc initTernaryTreeMap[K, T](xs: seq[TernaryTreeMapKeyValuePair[K, T]]): TernaryTreeMap[K, T] =
  var leavesList = xs.map(
    proc(pair: TernaryTreeMapKeyValuePair[K, T]): TernaryTreeMapKeyValuePairOfLeaf[K, T] =
      return (pair.k, createLeaf[K, T](pair))
  )
  initTernaryTreeMap(leavesList.len, 0, leavesList)

proc initTernaryTreeMap*[K, T](t: Table[K, T]): TernaryTreeMap[K, T] =
  var xs = newSeq[TernaryTreeMapKeyValuePair[K, T]](t.len)

  var idx = 0
  for k, v in t:
    xs[idx] = (k,v)
    idx = idx + 1

  let ys = xs.sorted(proc(x, y: TernaryTreeMapKeyValuePair[K, T]): int =
    let hx = x.k.hash
    let hy = y.k.hash
    cmp(hx, hy)
  )

  initTernaryTreeMap(ys)

proc `$`*(tree: TernaryTreeMap): string =
  fmt"TernaryTreeMap[{tree.len}, ...]"

proc len*(tree: TernaryTreeMap): int =
  if tree.isNil:
    return 0
  case tree.kind
  of ternaryTreeLeaf:
    return 1
  of ternaryTreeBranch:
    return tree.left.len + tree.middle.len + tree.right.len

proc formatInline*(tree: TernaryTreeMap, withHash: bool = false): string =
  if tree.isNil:
    return "_"
  case tree.kind
  of ternaryTreeLeaf:
    if withHash:
      fmt"{tree.hash}->{tree.elements[0].k}:{tree.elements[0].v}" # TODO show whole list
    else:
      fmt"{tree.elements[0].k}:{tree.elements[0].v}"
  of ternaryTreeBranch:
    "(" & tree.left.formatInline(withHash) & " " & tree.middle.formatInline(withHash) & " " & tree.right.formatInline(withHash) & ")"

proc isEmpty*(tree: TernaryTreeMap): bool =
  if tree.isNil:
    return true
  case tree.kind
  of ternaryTreeLeaf:
    false
  of ternaryTreeBranch:
    tree.left.isNil and tree.middle.isNil and tree.right.isNil

proc collectHashSortedSeq[K, T](tree: TernaryTreeMap[K, T], acc: var seq[TernaryTreeMapKeyValuePair[K, T]], idx: RefInt): void =
  if tree.isNil or tree.isEmpty:
    discard
  else:
    case tree.kind
    of ternaryTreeLeaf:
      for item in tree.elements:
        acc[idx[]] = item
        idx[] = idx[] + 1
    of ternaryTreeBranch:
      tree.left.collectHashSortedSeq(acc, idx)
      tree.middle.collectHashSortedSeq(acc, idx)
      tree.right.collectHashSortedSeq(acc, idx)

# sorted by hash(tree.key)
proc toHashSortedSeq*[K, T](tree: TernaryTreeMap[K, T]): seq[TernaryTreeMapKeyValuePair[K, T]] =
  var acc = newSeq[TernaryTreeMapKeyValuePair[K, T]](tree.len)
  var idx = new RefInt
  idx[] = 0
  collectHashSortedSeq(tree, acc, idx)
  return acc

proc collectHashSortedSeqOfLeaf[K, T](tree: TernaryTreeMap[K, T], acc: var seq[TernaryTreeMapKeyValuePairOfLeaf[K, T]], idx: RefInt): void =
  if tree.isNil or tree.isEmpty:
    discard
  else:
    case tree.kind
    of ternaryTreeLeaf:
      for pair in tree.elements:
        acc[idx[]] = (pair.k, TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: tree.hash, elements: @[pair]))
        idx[] = idx[] + 1
    of ternaryTreeBranch:
      tree.left.collectHashSortedSeqOfLeaf(acc, idx)
      tree.middle.collectHashSortedSeqOfLeaf(acc, idx)
      tree.right.collectHashSortedSeqOfLeaf(acc, idx)

# for reusing leaves during rebalancing
proc toHashSortedSeqOfLeaves*[K, T](tree: TernaryTreeMap[K, T]): seq[TernaryTreeMapKeyValuePairOfLeaf[K, T]] =
  var acc = newSeq[TernaryTreeMapKeyValuePairOfLeaf[K, T]](tree.len)
  let idx = new RefInt
  idx[] = 0
  collectHashSortedSeqOfLeaf(tree, acc, idx)
  return acc

proc contains*[K, T](tree: TernaryTreeMap[K, T], item: K): bool =
  if tree.isNil:
    return false

  if tree.kind == ternaryTreeLeaf:
    for pair in tree.elements:
      if pair.k == item:
        return true
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

proc loopGet*[K, T](originalTree: TernaryTreeMap[K, T], item: K): Option[T] =
  let hx = item.hash

  var tree = originalTree

  while tree.isNil.not:

    if tree.kind == ternaryTreeLeaf:
      for pair in tree.elements:
        if pair.k == item:
          return some(pair.v)
      return none(T)

    # echo "looking for: ", hx, " ", item, " in ", tree.formatInline

    if not tree.left.isNil:
      if tree.left.kind == ternaryTreeLeaf:
        if tree.left.hash == hx:
          for pair in tree.left.elements:
            if pair.k == item:
              return some(pair.v)
          return none(T)
      elif hx >= tree.left.minHash and hx <= tree.left.maxHash:
        tree = tree.left
        continue

    if not tree.middle.isNil:
      if tree.middle.kind == ternaryTreeLeaf:
        if tree.middle.hash == hx:
          for pair in tree.middle.elements:
            if pair.k == item:
              return some(pair.v)
          return none(T)
      elif hx >= tree.middle.minHash and hx <= tree.middle.maxHash:
        tree = tree.middle
        continue

    if not tree.right.isNil:
      if tree.right.kind == ternaryTreeLeaf:
        if tree.right.hash == hx:
          for pair in tree.right.elements:
            if pair.k == item:
              return some(pair.v)
          return none(T)
      elif hx >= tree.right.minHash and hx <= tree.right.maxHash:
        tree = tree.right
        continue

    return none(T)

  return none(T)


proc `[]`*[K, T](tree: TernaryTreeMap[K, T], key: K): Option[T] =
  tree.loopGet(key)

# leaves on the left has smaller hashes
# TODO check sizes, hashes
proc checkStructure*(tree: TernaryTreeMap): bool =

  if tree.kind == ternaryTreeLeaf:
    for pair in tree.elements:
      if tree.hash != pair.k.hash:
        raise newException(TernaryTreeError, fmt"Bad hash at leaf node {tree}")

    if tree.len != 1:
      raise newException(TernaryTreeError, fmt"Bad len at leaf node {tree}")

  else:
    if not tree.left.isNil and not tree.middle.isNil:
      if tree.left.getMax >= tree.middle.getMin:
        raise newException(TernaryTreeError, fmt"Wrong hash order at left/middle branches {tree.formatInline(true)}")

    if not tree.left.isNil and not tree.right.isNil:
      if tree.left.getMax >= tree.right.getMin:
        echo tree.left.getMax, " ", tree.right.getMin
        raise newException(TernaryTreeError, fmt"Wrong hash order at left/right branches {tree.formatInline(true)}")

    if not tree.middle.isNil and not tree.right.isNil:
      if tree.middle.getMax >= tree.right.getMin:
        raise newException(TernaryTreeError, fmt"Wrong hash order at middle/right branches {tree.formatInline(true)}")

    if not tree.left.isNil:
      discard tree.left.checkStructure
    if not tree.middle.isNil:
      discard tree.middle.checkStructure
    if not tree.right.isNil:
      discard tree.right.checkStructure

  return true

proc rangeContainsHash*[K, T](tree: TernaryTreeMap[K, T], thisHash: Hash): bool =
  if tree.isNil:
    false
  elif tree.kind == ternaryTreeLeaf:
    tree.hash == thisHash
  else:
    thisHash >= tree.minHash and thisHash <= tree.maxHash

proc assocExisted*[K, T](tree: TernaryTreeMap[K, T], key: K, item: T): TernaryTreeMap[K, T] =
  if tree.isNil or tree.isEmpty:
    raise newException(TernaryTreeError, "Cannot call assoc on nil")

  let thisHash = key.hash

  if tree.kind == ternaryTreeLeaf:
    var newPairs = newSeq[TernaryTreeMapKeyValuePair[K, T]](tree.elements.len)
    var replaced = false
    for idx, pair in tree.elements:
      if pair.k == key:
        newPairs[idx] = (key, item)
        replaced = true
      else:
        newPairs[idx] = pair
    if replaced:
      return TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: thisHash, elements: newPairs)
    else:
      raise newException(TernaryTreeError, "Unexpected missing hash in assoc, invalid branch")

  if thisHash < tree.minHash:
    raise newException(TernaryTreeError, "Unexpected missing hash in assoc, hash too small")

  elif thisHash > tree.maxHash:
    raise newException(TernaryTreeError, "Unexpected missing hash in assoc, hash too large")

  if not tree.left.isNil:
    if tree.left.rangeContainsHash(thisHash):
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch,
        maxHash: tree.maxHash,
        minHash: tree.minHash,
        left: tree.left.assocExisted(key, item),
        middle: tree.middle,
        right: tree.right
      )

  if not tree.middle.isNil:
    if tree.middle.rangeContainsHash(thisHash):
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch,
        maxHash: tree.maxHash,
        minHash: tree.minHash,
        left: tree.left,
        middle: tree.middle.assocExisted(key, item),
        right: tree.right
      )

  if not tree.right.isNil:
    if tree.right.rangeContainsHash(thisHash):
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch,
        maxHash: tree.maxHash,
        minHash: tree.minHash,
        left: tree.left,
        middle: tree.middle,
        right: tree.right.assocExisted(key, item)
      )
  else:
    raise newException(TernaryTreeError, "Unexpected missing hash in assoc, found not branch")

proc isSome*[K, T](tree: TernaryTreeMap[K, T]): bool =
  if tree.isNil:
    false
  else:
    true

proc assocNew*[K, T](tree: TernaryTreeMap[K, T], key: K, item: T): TernaryTreeMap[K, T] =
  # echo fmt"assoc new: {key} to {tree.formatInline}"
  if tree.isNil or tree.isEmpty:
    return createLeaf(key, item)

  let thisHash = key.hash

  if tree.kind == ternaryTreeLeaf:
    if thisHash == tree.hash:
      for pair in tree.elements:
        if pair.k == key:
          raise newException(TernaryTreeError, "Unexpected existed key in assoc")
      var newPairs = newSeq[TernaryTreeMapKeyValuePair[K, T]](tree.elements.len + 1)
      for idx, pair in tree.elements:
        newPairs[idx] = pair
      newPairs[tree.elements.len] = (key, item)
    else:
      if thisHash > tree.hash:
        return TernaryTreeMap[K, T](
          kind: ternaryTreeBranch, maxHash: thisHash, minHash: tree.hash,
          left: nil,
          middle: tree,
          right: TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: thisHash, elements: @[(key, item)])
        )
      else:
        return TernaryTreeMap[K, T](
          kind: ternaryTreeBranch, maxHash: tree.hash, minHash: thisHash,
          left: TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: thisHash, elements: @[(key, item)]),
          middle: tree,
          right: nil,
        )

  if thisHash < tree.minHash:
    if tree.left.isNil:
      if tree.middle.isNil:
        return TernaryTreeMap[K, T](
          kind: ternaryTreeBranch,
          maxHash: tree.maxHash, minHash: thisHash,
          left: nil,
          middle: TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: thisHash, elements: @[(key, item)]),
          right: tree.right,
        )
      else:
        return TernaryTreeMap[K, T](
          kind: ternaryTreeBranch,
          maxHash: tree.maxHash, minHash: thisHash,
          left: TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: thisHash, elements: @[(key, item)]),
          middle: tree.middle,
          right: tree.right,
        )
    elif tree.right.isNil:
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch,
        maxHash: tree.maxHash, minHash: thisHash,
        left: TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: thisHash, elements: @[(key, item)]),
        middle: tree.left,
        right: tree.middle,
      )
    else:
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch,
        maxHash: tree.maxHash, minHash: thisHash,
        left: TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: thisHash, elements: @[(key, item)]),
        middle: tree,
        right: nil,
      )

  if thisHash > tree.maxHash:
    if tree.right.isNil:
      if tree.middle.isNil:
        return TernaryTreeMap[K, T](
          kind: ternaryTreeBranch,
          maxHash: thisHash, minHash: tree.minHash,
          left: tree.left,
          middle: TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: thisHash, elements: @[(key, item)]),
          right: nil,
        )
      else:
        return TernaryTreeMap[K, T](
          kind: ternaryTreeBranch,
          maxHash: thisHash, minHash: tree.minHash,
          left: tree.left,
          middle: tree.middle,
          right: TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: thisHash, elements: @[(key, item)]),
        )
    elif tree.left.isNil:
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch,
        maxHash: thisHash, minHash: tree.minHash,
        left: tree.middle,
        middle: tree.right,
        right: TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: thisHash, elements: @[(key, item)]),
      )
    else:
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch,
        maxHash: thisHash, minHash: tree.minHash,
        left: nil,
        middle: tree,
        right: TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: thisHash, elements: @[(key, item)]),
      )

  if tree.left.rangeContainsHash(thisHash):
    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch,
      maxHash: tree.maxHash,
      minHash: tree.minHash,
      left: tree.left.assocNew(key, item),
      middle: tree.middle,
      right: tree.right
    )
  if tree.middle.rangeContainsHash(thisHash):
    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch,
      maxHash: tree.maxHash,
      minHash: tree.minHash,
      left: tree.left,
      middle: tree.middle.assocNew(key, item),
      right: tree.right
    )
  if tree.middle.rangeContainsHash(thisHash):
    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch,
      maxHash: tree.maxHash,
      minHash: tree.minHash,
      left: tree.left,
      middle: tree.middle,
      right: tree.right.assocNew(key, item)
    )

  if tree.middle.isSome:
    if thisHash < tree.middle.getMin:
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch,
        maxHash: tree.maxHash,
        minHash: tree.minHash,
        left: tree.left.assocNew(key, item),
        middle: tree.middle,
        right: tree.right
      )
    else:
      return TernaryTreeMap[K, T](
        kind: ternaryTreeBranch,
        maxHash: tree.maxHash,
        minHash: tree.minHash,
        left: tree.left,
        middle: tree.middle,
        right: tree.right.assocNew(key, item)
      )

  # not outbound, not at any branch, and middle is empty, so put in middle
  return TernaryTreeMap[K, T](
    kind: ternaryTreeBranch,
    maxHash: tree.maxHash,
    minHash: tree.minHash,
    left: tree.left,
    middle: tree.middle.assocNew(key, item),
    right: tree.right
  )

proc assoc*[K, T](tree: TernaryTreeMap[K, T], key: K, item: T, disableBalancing: bool = false): TernaryTreeMap[K, T] =
  if tree.isNil or tree.isEmpty:
    return createLeaf(key, item)

  if tree.contains(key):
    result = tree.assocExisted(key, item)
  else:
    result = tree.assocNew(key, item)

proc dissocExisted*[K, T](tree: TernaryTreeMap[K, T], key: K): TernaryTreeMap[K, T] =
  if tree.isNil:
    raise newException(TernaryTreeError, "Unexpected missing key in dissoc")

  if tree.kind == ternaryTreeLeaf:
    if tree.hash == key.hash:
      var newPairs: seq[TernaryTreeMapKeyValuePair[K, T]]
      for pair in tree.elements:
        if pair.k != key:
          newPairs.add pair
      if newPairs.len > 0:
        return TernaryTreeMap[K, T](kind: ternaryTreeLeaf, hash: tree.hash, elements: newPairs)
      else:
        return nil

    else:
      raise newException(TernaryTreeError, "Unexpected missing key in dissoc on leaf")

  if tree.len == 1:
    if not tree.contains(key):
      raise newException(TernaryTreeError, "Unexpected missing key in dissoc single branch")
    return nil

  let thisHash = key.hash

  if tree.left.rangeContainsHash(thisHash):
    let changedBranch = tree.left.dissocExisted(key)
    var minHash: int
    if not changedBranch.isNil:
      minHash = changedBranch.getMin
    elif not tree.middle.isNil:
      minHash = tree.middle.getMin
    else:
      minHash = tree.right.getMin

    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch,
      maxHash: tree.maxHash,
      minHash: minHash,
      left: changedBranch,
      middle: tree.middle,
      right: tree.right
    )

  if tree.middle.rangeContainsHash(thisHash):
    let changedBranch = tree.middle.dissocExisted(key)

    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch,
      maxHash: tree.getMax,
      minHash: tree.minHash,
      left: tree.left,
      middle: changedBranch,
      right: tree.right
    )

  if tree.right.rangeContainsHash(thisHash):
    let changedBranch = tree.right.dissocExisted(key)

    var maxHash: int
    if not changedBranch.isNil:
      maxHash = changedBranch.getMax
    elif not tree.middle.isNil:
      maxHash = tree.middle.getMax
    else:
      maxHash = tree.left.getMax

    return TernaryTreeMap[K, T](
      kind: ternaryTreeBranch,
      maxHash: maxHash,
      minHash: tree.minHash,
      left: tree.left,
      middle: tree.middle,
      right: changedBranch
    )

  raise newException(TernaryTreeError, "Cannot find branch in dissoc")


proc dissoc*[K, T](tree: TernaryTreeMap[K, T], key: K): TernaryTreeMap[K, T] =
  if tree.contains(key):
    tree.dissocExisted(key)
  else:
    tree

proc each*[K, T](tree: TernaryTreeMap[K, T], f: proc(k: K, v: T): void): void =
  if tree.isNil:
    return
  if tree.kind == ternaryTreeLeaf:
    for pair in tree.elements:
      f(pair.k, pair.v)
  else:
    tree.left.each(f)
    tree.middle.each(f)
    tree.right.each(f)

proc toPairs*[K, T](tree: TernaryTreeMap[K, T]): seq[TernaryTreeMapKeyValuePair[K, T]] =
  if tree.isNil:
    return @[]
  if tree.kind == ternaryTreeLeaf:
    for pair in tree.elements:
      result.add pair
  else:
    for item in tree.left.toPairs:
      result.add item
    for item in tree.middle.toPairs:
      result.add item
    for item in tree.right.toPairs:
      result.add item

iterator pairs*[K, T](tree: TernaryTreeMap[K, T]): TernaryTreeMapKeyValuePair[K, T] =
  let seqItems = tree.toHashSortedSeq()

  for x in seqItems:
    yield (x.k, x.v)

proc keys*[K, T](tree: TernaryTreeMap[K, T]): seq[K] =
  if tree.isNil:
    return @[]
  if tree.kind == ternaryTreeLeaf:
    for pair in tree.elements:
      result.add(pair.k)
  else:
    for item in tree.left.keys:
      result.add item
    for item in tree.middle.keys:
      result.add item
    for item in tree.right.keys:
      result.add item

iterator items*[K, T](tree: TernaryTreeMap[K, T]): K =
  let seqItems = tree.keys()

  for x in seqItems:
    yield x

proc `$`*[K,V](p: TernaryTreeMapKeyValuePair[K, V]): string =
  fmt"{p.k}:{p.v}"

proc identical*[K,V](xs: TernaryTreeMap[K, V], ys: TernaryTreeMap[K, V]): bool =
  cast[pointer](xs) == cast[pointer](ys)

proc `==`*[K,V](xs: TernaryTreeMap[K, V], ys: TernaryTreeMap[K, V]): bool =
  if xs.len != ys.len:
    return false

  if xs.isEmpty:
    return true

  if xs.identical(ys):
    return true

  let keys = xs.keys
  for key in keys:

    if xs.loopGet(key) != ys.loopGet(key):
      return false
  return true

proc merge*[K, T](xs: TernaryTreeMap[K, T], ys: TernaryTreeMap[K, T]): TernaryTreeMap[K, T] =
  var ret = xs
  var acc = 0
  ys.each(proc(key: K, item: T): void =
    ret = ret.assoc(key, item)
    # TODO pickd loop by experience
    if acc > 700:
      ret.forceInplaceBalancing()
      acc = 0
    else:
      acc = acc + 1
  )
  return ret

# this function mutates original tree to make it more balanced
proc forceInplaceBalancing*[K,T](tree: TernaryTreeMap[K,T]): void =
  # echo "Force inplace balancing of list"
  var xs = tree.toHashSortedSeqOfLeaves
  let newTree = initTernaryTreeMap(xs.len, 0, xs)
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

  if xs.kind != ys.kind:
    return false

  if xs.kind == ternaryTreeLeaf:
    if xs.elements != ys.elements:
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
