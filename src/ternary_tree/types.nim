
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

  TernaryTreeMap*[T] = ref object
    depth*: int
    size*: int
    case kind*: TernaryTreeKind
    of ternaryTreeBranch:
      max*: int
      min*: int
      left*: TernaryTreeMap[T]
      middle*: TernaryTreeMap[T]
      right*: TernaryTreeMap[T]
    of ternaryTreeLeaf:
      hash*: int
      key*: T
      value*: T

  TernaryTreeSet*[T] = ref object
    depth*: int
    size*: int
    case kind*: TernaryTreeKind
    of ternaryTreeBranch:
      max*: int
      min*: int
      left*: TernaryTreeMap[T]
      middle*: TernaryTreeMap[T]
      right*: TernaryTreeMap[T]
    of ternaryTreeLeaf:
      hash*: int
      value*: T
