# Package

version       = "0.1.3"
author        = "jiyinyiyong"
description   = "Ternary tree of list data structure"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.2.6"

task t, "Runs the test suite":
  # exec "nim c --hints:off -r tests/testList"
  exec "nim c --hints:off -r tests/testMap"
