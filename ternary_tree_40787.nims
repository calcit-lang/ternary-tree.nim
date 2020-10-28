import system except getCommand, setCommand, switch, `--`,
  packageName, version, author, description, license, srcDir, binDir, backend,
  skipDirs, skipFiles, skipExt, installDirs, installFiles, installExt, bin, foreignDeps,
  requires, task, packageName
import nimscriptapi, strutils
# Package

version       = "0.1.23"
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

onExit()
