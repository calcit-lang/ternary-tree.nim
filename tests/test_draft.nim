
import unittest
import options

import ternary_tree

test "init list":
  # check ($initTernaryTreeDraft[int](@[1,2,3,4]) == "TernaryTreeList[4, 3]")

  echo initTernaryTreeDraft[int](@[1,2,3,4])
  echo initTernaryTreeDraft[int](@[1,2,3,4]).get(@[pickLeft])
