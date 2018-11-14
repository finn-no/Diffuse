# FINN Diffuse

## Description
**Diffuse** is library that aims to simplify the diffing of two collections. After diffing you get to know:

- ❇️ indices where **insertion** has happened
- 💔 indices that has been **removed**
- 🚚 indices that has **moved**
- ♻️ indices that has been **updated**

🎁 We've also included an extension for `UITableView` so you can easily reload it with the changes from the diff!

Currently we have two different methods, each with their own algorithm. They both have pros and cons, depending on your usecase. See the description of both in section [`Differences in algorithms`](#differences-in-algorithms).

## Installation
`Diffuse` is available through [Carthage](https://github.com/Carthage/Carthage). Append this line to your `Cartfile`:

```ruby
github "finn-no/Diffuse"
```

## Usage
As mentioned, we have two different methods/algorithms:
- `diff<T: Hashable>(old: [T], new: [T]) -> CollectionChanges`
- `diff<T: Equatable>(old: [T], new: [T], comparator: (T, T) -> Bool) -> CollectionChanges`

They both diff two lists, but they compare elements differently and has a different view on how to interpret an updated element. The first one is faster and implicit, while the second is slower but explicit. See a detailed overview in section [`Differences in algorithms`](#differences-in-algorithms).

### `Diffuse.diff(old:new:)`
The elements in each collection must implement `Hashable`.  Each element will be compared using their `hashValue`.

```swift
let old = [1, 2, 3, 4]
let new = [1, 3, 4, 5]

let changes = Diffuse.diff(old: old, new: new)
```

### `Diffuse.diff(old:new:comparator)`
The elements in each collection must implement `Equatable`. Each element will be compared by the closure you provide through the parameter `comparator: (T, T) -> Bool`.

```swift
struct Object: Equatable {
    let id: Int
    let name: String
}

let a = Object(id: 1, name: "A")
let b = Object(id: 2, name: "B")
let c = Object(id: 3, name: "C")

let old = [a, b, c]

let new = [a, c, b]
let changes = Diffuse.diff(old: old, new: new, comparator: { $0.id == $1.id })
```

### Updating your tableView
This extension lets you reload your `UITableView` with the changes given by the outcome of the diff. The parameter `updateDataSource` lets you update your tableView's datasource.

Note that this method also has a parameter for selecting which section within the tableView these changes should be applied to. If not specified it uses section `0`.

```swift
let old = dataSource.models
let new = [3, 2, 1]
let changes = Diffuse.diff(old: old, new: new)

// Reload items in section 0.
tableView.reload(with: changes, updateDataSource: { dataSource.models = new })

// Reload items in section 1.
tableView.reload(with: changes, section: 1, updateDataSource: { dataSource.models = new })
```

## Differences in algorithms
### `Diffuse.diff(old: [T], new: [T])`
This one is *faaaaast*! 🏎🔥 You could say its compexity is `O(damn that's swift)`😮 Jokes aside, it's actually `O(n)`.

This algorithm is usable for both Swift "primitives" and more complex structures, and uses `hashValue` for comparison. This means element in your collections must implement the `Hashable` protocol. 

#### Caveats
Since we're using the elements `hashValue` for comparison, this algorithm won't be directly able to figure out updates to an element. An updated element will have a different `hashValue` than the old element. This makes the algorithm think the old element is removed and the updated element is inserted, given that the index is the same.

Luckily we've decided that a removal and an insert on the same index is considered an update 🙌

All examples below uses the `struct` and list of elements below:

```swift
struct Object: Hashable {
    let id: Int
    var name: String
}

let a = Object(id: 1, name: "A")
var b = Object(id: 2, name: "B")
let c = Object(id: 3, name: "C")
```

###### Example: Let's update a single element

An update to an object on the same index will result in an update, even though the algorithm initially thinks it's a removal and an insert. As mentioned: a removal and an insert to the same index is considered to be an update.

```swift
// Your old list.
let old = [a, b, c]

// Update `B` and keep it at the same index.
b.name = "New name"
let new = [a, b, c]

// Diff the collections, and print the indices that has been updated.
let changes = Diffuse.diff(old: old, new: new)

print(changes.updated) // [1]                  <- Element B
```

###### Example: Let's remove `B` and insert `D` instead

As seen below a removal and an insertion results in an update.

```swift
// Your old list.
let old = [a, b, c]

// Replace `B` with `D`.
let d = Object(id: 4, name: "D")
let new = [a, d, c]

// Diff the collections, and print the indices that has been updated.
let changes = Diffuse.diff(old: old, new: new)

print(changes.updated) // [1]                  <- Element B/D
```

###### Example: Let's update and move `B` and insert `D`

```swift
// Your old list.
let old = [a, b, c]

// Insert `D` where `B` used to be.
// Update `B` and insert it at the end.
let d = Object(id: 4, name: "D")
b.name = "New name"
let new = [a, d, c, b]

// Diff the collections.
let changes = Diffuse.diff(old: old, new: new)

// Note that index 3 (`B`) is marked as inserted and index 1 (now `D`, previously `B`).
// is marked as updated.
print(changes.count)     // 2
print(changes.inserted)  // [3]                  <- Element B
print(changes.updated)   // [1]                  <- Element B/D
```

### `Diffuse.diff(old: [T], new: [T], comparator: (T, T) -> Bool)`

The algorithm this method uses isn't as fast as `diff(old:new)`, but it gives you more control when comparing complex elements. It takes a closure as one of its parameters, so you can control how you would like to compare the elements. This is useful if you explicitly need to know which elements has been updated. This works best if your elements has some form of unique identifier, like `id`. 

Note that all elements must implement `Equatable`.

#### Caveats
##### Swift "primitives"

Don't use this method if your collections consists of "primitives", such as `Int`, `String`, `Double` or `Float`. Neither of these types have any real unique identifier, and you should rather rely on their `hashValue`s instead. **Use `diff(old:new)` instead.**

##### Difference from `diff(old:new)`

The algorithm used in this method is more explicit than `diff(old:new)`, and will not consider an insertion and removal on the same index as an update, but instead as one insertion and one removal. Depending on your use case, this may be what you need.

Let's use the same examples as above.

###### Example: Let's update a single element

```swift
// Your old list.
let old = [a, b, c]

// Update `B` and keep it at the same index.
b.name = "New name"
let new = [a, b, c]

// Diff the collections.
// Compare using the elements ids.
let changes = Diffuse.diff(old: old, new: new, comparator: { $0.id == $1.id })

print(changes.updated) // [1]                  <- Element B
```

###### Example: Let's remove `B` and insert `D` instead

As seen below a removal and an insertion results in an update.

```swift
// Your old list.
let old = [a, b, c]

// Replace `B` with the new object `D`.
let d = Object(id: 4, name: "D")
let new = [a, d, c]

// Diff the collections.
// Compare using the elements ids.
let changes = Diffuse.diff(old: old, new: new, comparator: { $0.id == $1.id })

print(changes.inserted) // [1]                  <- Element D
print(changes.removed)  // [1]                  <- Element B
```

###### Example: Let's update and move `B` and insert `D`

```swift
// Your old list.
let old = [a, b, c]

// Insert `D` where `B` used to be.
// Update `B` and insert it at the end.
let d = Object(id: 4, name: "D")
b.name = "New name"
let new = [a, d, c, b]

// Diff the collections.
// Compare using the elements ids.
let changes = Diffuse.diff(old: old, new: new, comparator: { $0.id == $1.id })

print(changes.inserted) // [1]                  <- Element D
print(changes.moved)    // [(from: 1, to: 3)]   <- Element B
print(changes.updated)  // [3]                  <- Element B
```
