
import math
import strformat

proc roughIntPow*(x: int, times: int): int =
  if times < 1:
    return x

  result = 1
  for idx in 0..<times:
    result = result * x

proc divideTernarySizes*(size: int): tuple[left: int, middle: int, right: int] =
  if size < 0:
    raise newException(ValueError, "Unexpected negative size")
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
    raise newException(ValueError, fmt"Unexpected mod result {extra}")

  (left: leftSize, middle: middleSize, right: rightSize)
