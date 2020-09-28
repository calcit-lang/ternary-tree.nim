
Ternary Tree
----

> Structural sharing data structure of lists and maps.

If you know Clojure, then you know what I want to build.
However ternary tree may have issues in performance and memory size(see the holes below). So this project is experimental.

Compact tree representatin of `[1 2 3 4 5 6 7 8 9 0 11]`(`_` for empty holes in the tree):

```cirru
((1 (2 _ 3) 4) (5 6 7) (8 (9 _ 10) 11))
```

Compact tree representatin of map:

```cirru
((2:12 3:13 7:17) ((_ 9:19 _) (6:16 _ 5:15) (_ 1:2222 _)) (8:18 0:10 4:14))
```

TODO:

- sets

### Usages

```bash
nimble install https://github.com/Cirru/ternary-tree
```

```nim
import ternary_tree
let data = initTernaryTreeList[int](@[1,2,3,4]

data.len
data.get(0)
data.first()
data.last()
data.rest()
data.butlast()
data.slice()

data.dissoc(0)
data.assoc(0, 10)
data.assocBefore(2, 10)
data.assocAfter(2, 10)
data.prepend(10)
data.append(10)
data.concat(data)
```

```nim
var dict: Table[string, int]
for idx in 0..<10:
  dict[fmt"{idx}"] = idx + 10

let data = initTernaryTreeMap(dict)

data.len
data.contains("1")
data.get("1")
data.toPairs()
data.keys()

data.assoc("1", 10)
data.dissoc("1")
data.merge(data)
```
