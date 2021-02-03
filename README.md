
Ternary Tree
----

> Structural sharing data structure of lists and maps.

Intro [ternary-tree: structure sharing data for learning purpose](https://clojureverse.org/t/ternary-tree-structure-sharing-data-for-learning-purpose/6760).

If you know Clojure, then you know what I want to build.
However ternary tree may have issues in performance and memory size(see the holes below). So this project is experimental.

Compact tree representatin of `[1 2 3 4 5 6 7 8 9 0 11]`, where `_` is for empty holes in the tree:

```cirru
((1 (2 _ 3) 4) (5 6 7) (8 (9 _ 10) 11))
```

Compact tree representatin of map:

```cirru
((2:12 3:13 7:17) ((_ 9:19 _) (6:16 _ 5:15) (_ 1:2222 _)) (8:18 0:10 4:14))
```

### Usages

Add in nimble file:

```nim
requires "ternary_tree >= 0.1.27"
```

* List

```nim
import ternary_tree
let data = initTernaryTreeList[int](@[1,2,3,4]

data.len
data.get(0)
data[0]
data.first()
data.last()
data.rest()
data.butlast()
data.slice()
data.reverse()

data.dissoc(0)
data.assoc(0, 10)
data.assocBefore(2, 10)
data.assocAfter(2, 10)
data.prepend(10)
data.append(10)
data.concat(data)
data.indexOf(1)
data.findIndex(proc(x: int): bool = x == 1)
data.mapValues(proc(x: int): int = x + 1)

data == data
data.identical(data) # compare by reference
```

* Map

```nim
var dict: Table[string, int]
for idx in 0..<10:
  dict[fmt"{idx}"] = idx + 10

let data = initTernaryTreeMap(dict)

data.len
data.contains("1")
data.get("1")
data["1"]
data.toPairs()
data.keys()

data.assoc("1", 10)
data.dissoc("1")
data.merge(data)
data.mergeSkip(data, v) # skip a value, mostly for nil
data.mapValues(proc(x: int): int = x + 1)

data == data
data.identical(data) # compare by reference

data.each(proc(x: int) =
  echo x
)
```

* Revision

Idea came from CRDT and [bisection-key](https://github.com/Cirru/bisection-key). Each element has its unique key(based on structure of current tree representation). When a new element is inserted based on an existing key, it will be in the right when `toSeq` is called.

```nim
let data = initTernaryTreeRevision[int](@[1,2,3,4,5,6,7,8,9])

data.len
data.toSeq
data.keys
data.get("j")
data.contains("j")

for k, v in data:
  echo k, v

data.dissoc "j"
data.assoc "j", 11
data.assocBefore "j", 11
data.assocAfter "j", 11
data.formatInline

data.each(proc(k: string, v: int): void =
  # echo fmt"{k}-{v}"
)
```

- Sets

_TODO_

### License

MIT
