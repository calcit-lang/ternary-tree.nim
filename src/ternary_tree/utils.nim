
proc roughIntPow*(x: int, times: int): int =
  if times < 1:
    return x

  result = 1
  for idx in 0..<times:
    result = result * x
