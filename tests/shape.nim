
import ternary_tree

proc tryShape(): void =
  var data = initTernaryTreeList[int](@[])

  for i in 0..<82:
    data = data.append i
    echo data.getDepth, " : ", data.formatInline


tryShape()
