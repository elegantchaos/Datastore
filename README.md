#  An asynchronous schema-less object store

A flexible object store which supports asynchronous usage patterns.

In fact, it forces asynchronous usage patterns by not supplying synchronous ones! 

The goal is that it has a lightweight API which is reasonably easy to use, but can be implemented efficiently. 

It also supports versioning at the property level, by retaining every value that a property has ever had. 

This is partly useful in its own right, but is primarily intended to make the database resilient when synchronise between devices, since individual property values are only ever added to, and never modified.



## Structure

The datastore contains *entities*, which have *properties* and *relationships*.

### Entities

For housekeeping purposes, all entities have three fixed properties:  `type`, `datestamp` and `identifier`.

The entity `type` is just a label that indicates what kind of thing the entity is. It's up to you whether it also implies what properties the entity will have - the datastore doesn't enforce any structure on a particular entity type.

The entity `identifier` is unique across all entities, regardless of type.

The entity `datestamp` indicates the time that it was first added to the store.

### Properties

In addition to these fixed properties, entities also have any number of custom properties.

Each of these is stored in the database as a separate  `(key, value, datestamp, type)` tuple. 

The `key` of a property is just a label ("name", "address", etc).

The `value` of a property is a primitive type (string, number, etc), or a reference to another entity. 

The `datestamp` indicates the time that the property value was set.

The `type` of a property is a label that indicates the *semantic* type of the property. You can think of this as a way of indicating how the raw `value` of the property should be interpreted or displayed.

### Relationships

Properties can form relationships between entities. 

Relationships are just properties that tie together two entities in some way; the `value` is the related entity, and the `type` indicates the kind of relationship.

### Versioning

Property values have a `datestamp`. 

An entity can have more than one entry for the same property. 

When a property is changed, a new entry is added, with the updated value, and a newer datestamp.

Thus the multiple entries for a property are a record of its history, with the newest entry being the current value.


## Access

All access operations are asynchronous, and backing-store neutral.

Entities are passed in and returned as opaque references. 

Properties are passed in and returned as immutable dictionaries. 

Results are delivered using callback blocks, which pass back entity references and property dictionaries. 

The API is designed for bulk operations; it takes a list of entities/properties to operate on, and returns lists or dictionaries of the combined results.

### References & On-Demand Creation

Entity references can be specified by `identifier` or by matching a particular property (eg `name`).

These are lightweight structures which can be passed around safely in the client, and are not tied to a particular thread or database context.

Internally, an entity reference is resolved to an actual `EntityRecord`.

Sometimes your client code knows (or expects) that an entity exists, and if resolution fails it's either a programming error or you simply want to do nothing. 

Other times you want to specify an entity by name or identifier, and create if it wasn't already there.  

Entity references support this pattern by allowing you to provide a type and set of initial properties along with the search keys. When the entity is resolved, if the reference doesn't match an existing object, a new object is created using supplied type and properties.


## Backing Store

Current backing store is CoreData, but the intention is to make this completely opaque.

The main reason for using CoreData initially is to allow leverage of other solutions which provide automatic synchronisation of CoreData across devices.


## Interchange

The store can be read from, and written to, a dictionary-based interchange format. This only uses JSON-legal types, hence can be easily converted into JSON/XML/whatever.


## Efficiency

Some of the aspects of the design make it expensive to implement using a traditional database. 

Each property for each entity is stored as a separate record in a different table from the entity itself.
Multiple entries can exist for the same property on the same entity.
Thus a simple property lookup requires quite a bit of work filtering and/or sorting entries.

Right now I'm not too worried about this - I'm more interested in other aspects of how this design works.

I'm fairly sure that a custom implementation could greatly improve efficiency if required.


## Future

Combine support is being considered.

I've got a proof of concept test in `DatastoreCombineTests.swift`, but I need to think a little bit about whether it's a natural fit.

All suggestions on this front gratefully received.


## To Do

- implement special modified property for entities (read-only, date of most recently modified property)
- support reading/writing arrays (and dictionaries?)
- add compact interchange output: drops older values, writes simplified properties when possible
- optimise interchange writing for compact values
- add prototypes?
