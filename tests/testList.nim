
import unittest

import ternary_tree

test "can add":
  echo initTernaryTreeList[int](@[])
  echo initTernaryTreeList[int](@[1])
  echo initTernaryTreeList[int](@[1,2])
  echo initTernaryTreeList[int](@[1,2,3])
  echo initTernaryTreeList[int](@[1,2,3,4])
  echo initTernaryTreeList[int](@[1,2,3,4,5,6])
  echo initTernaryTreeList[int](@[1,2,3,4,5,6,7,8,9])
  echo initTernaryTreeList[int](@[1,2,3,4,5,6,7,8,9,10,11])
  echo initTernaryTreeList[int](@[1,2,3,4,5,6,7,8,9,10,11]).showLinear

  for x in initTernaryTreeList[int](@[1,2,3,4,5,6,7,8,9,10,11]):
    echo "item: ", x
