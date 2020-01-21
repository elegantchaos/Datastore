#  An asynchronous schema-less object store

A flexible object store which supports asynchronous usage patterns.

In fact, it forces asynchronous usage patterns by not supplying synchronous ones! 

The goal is that it has a lightweight API which is reasonably easy to use, but can be implemented efficiently. 

It also supports versioning at the property level, by retaining every value that a property has ever had. 

This is partly useful in its own right, but is primarily intended to make the database resilient when synchronise between devices, since individual property values are only ever added to, and never modified.



## Structure

The datastore contains *entities*, which have *properties* and *relationships*.

### Entities

For housekeeping purposes, all entities have three guaranteed properties:  `type`, `datestamp` and `identifier`.

The entity `type` is just a label that indicates what kind of thing the entity is. It's up to you whether it also implies what properties the entity will have - the datastore doesn't enforce any structure on a particular entity type.

The entity `identifier` is unique across all entities, regardless of type.

The entity `datestamp` indicates the time that it was first added to the store.

### Properties

In addition to the guaranteed properties, entities also have any number of custom properties.

Each of these is stored in the database as a  `(key, value, datestamp, type)` tuple. 

The `key` of a property is just a label ("name", "address", etc).

The `value` of a property is a primitive type (int, double, bool, string, date, binary blob), or a reference to another entity. 

The `datestamp` indicates the time that the property value was set.

The `type` of a property is a label that indicates the *semantic* type of the property. You can think of this as a way of indicating how the raw `value` of the property should be interpreted or displayed.

### Relationships

Properties can form relationships between entities. 

Relationships are just properties that tie together two entities in some way; the `value` is the related entity, and the `type` can be used to indicate the kind of relationship.

### Versioning

Property values have a `datestamp`. 

An entity can have more than one entry for the same property. 

When a property is changed, a new entry is added, with the updated value, and a newer datestamp.

Thus the multiple entries for a property are a record of its history, with the newest entry being the current value.


## Access Patterns

All access operations are asynchronous, and backing-store neutral.

Entities are passed in and returned as opaque reference types which hide the database implementation.

The API is designed for bulk operations; it takes a list of entities/properties to operate on, and returns lists or dictionaries of the combined results.

### Input

On input, a reference consists of a *resolver* to find the entity, and some optional properties used by the operation that is being performed. 

An input reference can be *unresolved*, meaning that they may not refer to a valid entity. It will be resolved as part of executing the operation that was requested. 

### Output

Results are delivered using callback blocks, which pass back entity references. 

On output, a reference will always be *resolved*. It still has a *resolver* internally, but it is guaranteed to be an instance of `CachedResolver` or `NullResolver`. 

An output reference contains a dictionary with fetched properties of the entity. The dictionary is not guaranteed to contain all of the entity's properties - only the ones that were requested by the operation performed. 
Properties are passed in and returned as immutable dictionaries. 


### References & On-Demand Creation

References are relatively lightweight structures which can be passed around safely in the client, and are not tied to a particular thread, database context, or even datastore.

References can be created by client code, by specifying an entity `identifier` to look for, or a value to match against an entity property  (eg `name == "test"`).

Internally, an unresolved reference is resolved to an actual `EntityRecord`. If you pass in a reference that was the output of a previous operation, it will already be resolved.

Sometimes your client code knows (or expects) that an entity exists, and if resolution fails it's either a programming error or you simply want to do nothing. 

Other times you want to specify an entity by name or identifier, and create if it wasn't already there.  

Entity references support this pattern by allowing you to provide a type and set of initial properties along with the search keys. 

When the entity is resolved, if the reference doesn't match an existing object, a new object is created using supplied type and properties.


### Custom Reference Classes

You can register custom reference classes that inherit from `CustomReference`.

Each of these is associated with a particular entity type. 

If you create the in client code and pass them in requesting creation, an entity of the associated type will be created. This saves you having to specify the type explicitly.

When you receive entity results, any entity type which has a corresponding custom reference class registered will be returned as an instance of that class. This allows you to write dynamic code, rather than having to test the `type` property of the returned reference.

This facility allows your client code to define classes for the model entities you are storing and Datastore, and to associate business logic and other code with them. Most of the client code should be able to operate in terms of those classes - passing them to datastore and retrieving them from datastore as necessary.

It's worth bearing in mind however that these classes are often just a partial-representation of the entity in the store. The properties that an entity reference has available to it are entirely dependant on what was requested when it was created. This is somewhat analogous to an un-faulted `NSManagedObject`, but only somewhat. Unlike core data objects, entity reference do not have a faulting concept, and need to be explicitly re-fetched in order to be updated with additional properties. 

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
