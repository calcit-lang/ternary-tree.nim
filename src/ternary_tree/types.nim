
type
  TernaryTreeKind* = enum
    ternaryTreeBranch,
    ternaryTreeLeaf

  TernaryTreeList*[T] = ref object
    size*: int
    case kind*: TernaryTreeKind
    of ternaryTreeBranch:
      depth*: int
      left*: TernaryTreeList[T]
      middle*: TernaryTreeList[T]
      right*: TernaryTreeList[T]
    of ternaryTreeLeaf:
      value*: T

  TernaryTreeMapKeyValuePair*[K, V] = tuple
    k: K
    v: V

  TernaryTreeMap*[K, T] = ref object
    case kind*: TernaryTreeKind
    of ternaryTreeBranch:
      depth*: int
      maxHash*: int
      minHash*: int
      left*: TernaryTreeMap[K, T]
      middle*: TernaryTreeMap[K, T]
      right*: TernaryTreeMap[K, T]
    of ternaryTreeLeaf:
      hash*: int
      elements*: seq[TernaryTreeMapKeyValuePair[K, T]] # handle hash collapsing

  TernaryTreeRevision*[T] = ref object
    case kind*: TernaryTreeKind
    of ternaryTreeBranch:
      left*: TernaryTreeRevision[T]
      middle*: TernaryTreeRevision[T]
      right*: TernaryTreeRevision[T]
    of ternaryTreeLeaf:
      value*: T

  PickBranch* = enum
    pickLeft, pickMiddle, pickRight

  RefInt* = ref int