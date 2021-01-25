# Package

version       = "0.1.30"
author        = "jiyinyiyong"
description   = "Ternary tree of list data structure"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.2.6"

task t, "Runs the test suite":
  # exec "nim c --hints:off -r tests/test_revision"
  exec "nim c --hints:off -r tests/test_list"
  exec "nim c --hints:off -r tests/test_map"

task perf, "try large file":
  exec "nim compile --verbosity:0 --profiler:on --stackTrace:on --hints:off -r tests/costs"
