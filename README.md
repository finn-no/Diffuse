# FINN Diffuse

## Description
**Diffuse** is library that aims to simplify the diffing of two collections. After diffing you get to know:

- indices where **insertion** has happened
- indices that has been **removed**
- indices that has **moved**
- indices that has been **updated**

Note that elements in the collections must be of same type and implement the `Equatable` protocol.


## Usage
### Comparing "primitives"

Comparing "primitives" should be compared using `==` operator to find changes. This means that we have no way of finding elements that has been updated in the list.

```swift
let old = [1, 2, 3]
let updated = [1, 3, 4]

let changes = Diffuse.diff(old: old, updated: updated)

// Result
changes.allChanges 	// [.insert(at: 2), .remove(from: 1), .move(from: 2, to: 1)]

changes.inserted 	// [.insert(at: 2)]
changes.removed 	// [.remove(from: 1)]
changes.moved 		// [.move(from: 2, to: 1)]
changes.updated 	// []
```


### Comparing complex structures

Complex structures may have some form of unique identifier you can use to check for equality. In these cases you can provide your own comparator through the parameter `comparator: (T, T) -> Bool`.

```swift
// Your datamodel, where `id` is the unique identifier.
struct Object: Equatable {
	let id: Int
	var title: String
}

// Your old array of objects.
let old = [Object(id: 0, title: "A"), Object(id: 1, title: "B"), Object(id: 2, title: "C")]

// After some time you decide to change the title of the first Object.
// You also remove Object with title 'B' and append a new one with title 'D'.
let updated = [Object(id: 0, title: "New title"), Object(id: 2, title: "C"), Object(id: 3, title: "D")]

// Find changes, where you check for equality by comparing the Objects `id`'s.
let changes = Diffuse.diff(old: old, updated: updated, comparator: { $0.id == $1.id })

// Result
changes.allChanges 	// [.insert(at: 2), .remove(from: 1), .move(from: 2, to: 1), .updated(at: 0)]

changes.inserted 	// [.insert(at: 2)]
changes.removed 	// [.remove(from: 1)]
changes.moved 		// [.move(from: 2, to: 1)]
changes.updated 	// [.updated(at: 0)]
```
