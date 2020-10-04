
type
  TernaryTreeKind* = enum
    ternaryTreeBranch,
    ternaryTreeLeaf

  TernaryTreeList*[T] = ref object
    depth*: int
    size*: int
    case kind*: TernaryTreeKind
    of ternaryTreeBranch:
      left*: TernaryTreeList[T]
      middle*: TernaryTreeList[T]
      right*: TernaryTreeList[T]
    of ternaryTreeLeaf:
      value*: T

  TernaryTreeMap*[K, T] = ref object
    depth*: int
    size*: int
    case kind*: TernaryTreeKind
    of ternaryTreeBranch:
      maxHash*: int
      minHash*: int
      left*: TernaryTreeMap[K, T]
      middle*: TernaryTreeMap[K, T]
      right*: TernaryTreeMap[K, T]
    of ternaryTreeLeaf:
      hash*: int
      key*: K
      value*: T

  TernaryTreeSet*[T] = ref object
    depth*: int
    size*: int
    case kind*: TernaryTreeKind
    of ternaryTreeBranch:
      max*: int
      min*: int
      left*: TernaryTreeSet[T]
      middle*: TernaryTreeSet[T]
      right*: TernaryTreeSet[T]
    of ternaryTreeLeaf:
      hash*: int
      value*: T

  TernaryTreeDraft*[T] = ref object
    case kind*: TernaryTreeKind
    of ternaryTreeBranch:
      left*: TernaryTreeDraft[T]
      middle*: TernaryTreeDraft[T]
      right*: TernaryTreeDraft[T]
    of ternaryTreeLeaf:
      value*: T

  PickBranch* = enum
    pickLeft, pickMiddle, pickRight
