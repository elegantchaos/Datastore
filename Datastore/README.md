#  An asynchronous schema-less object store

The goal is for a flexible object store which can be implemented efficiently using threading. 

It forces asynchronous usage patterns by no supplying synchronous ones! 

## Structure

The datastore contains *entities*, which have *properties* and *relationships*.

For housekeeping purposes, all entities have three fixed properties:  `type`, `datestamp` and `uuid`.

Entities also have any number of custom properties stored as `key, value, date, type` tuples. 

Entities are tagged as being of a particular *type*, but it's just a tag, it's up to you whether it implies structure.

Properties values are stored as primitive types (string, number, etc), but are tagged as being of a particular semantic *type*. 

Relationships are just properties that tie together two entities in some way; the `value` is the related entity, and the `type` indicates the kind of relationship.

Property values have a datestamp. An entity can have more than one entry for the same property. 

What multiple entries for the same property means is up to interpretation - it can either indicate a change history (with the newest entry being the current value),
or it can indicate that the entity does indeed have multiple values for that property. 

## Access

All access operations are asynchronous, and backing-store neutral.

Entities are passed in and returned as opaque references. 

Properties are passed in and returned as dictionaries. 

Results are returned using callback blocks.

The API is designed for bulk operations; it takes a list of entities/properties to operate on, and returns lists or dictionaries of the combined results. 

## Backing Store

Current backing store is CoreData, but the intention is to make this completely opaque.

The main reason for using CoreData is to allow leverage of other solutions which provide automatic synchronisation of CoreData across devices.

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

## To Do

- add data property type
- implement special modified property for entities (read-only, date of most recently modified property)
- support reading/writing arrays (and dictionaries?)
- add compact interchange output: drops older values, writes simplified properties when possible
- optimise interchange writing for compact values
- encoding/decoding relationships
