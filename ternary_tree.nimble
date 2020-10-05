# Package

version       = "0.1.9"
author        = "jiyinyiyong"
description   = "Ternary tree of list data structure"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.2.6"

task t, "Runs the test suite":
  exec "nim c --hints:off -r tests/test_revision"
  exec "nim c --hints:off -r tests/test_list"
  exec "nim c --hints:off -r tests/test_map"
