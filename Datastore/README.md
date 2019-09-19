#  An asynchronous no-schema object store

The goal is for a flexible object store which can be implemented efficiently using threading. 

It forces asynchronous usage patterns by no supplying synchronous ones! 

## Structure

The datastore contains *entities*, which have *properties* and *relationships*.

For housekeeping purposes, all entities have some fixed properties: `name`, `type`, `creation date`, `modification date`, `uuid`.

Entities also have any number of custom properties stored as `key, value, type` triples. 

Entities are tagged as being of a particular *type*, but it's just a tag, it's up to you whether it implies structure.

Properties values are stored as primitive types (string, number, etc), but are tagged as being of a particular semantic *type*. 

Relationships are just properties that tie together two entities in some way; the `value` is the related entity, and the `type` indicates the kind of relationship.

## Access

All access operations are asynchronous, and backing-store neutral.

Entities are passed in and returned as opaque references. 

Properties are passed in and returned as `[String:Any]` dictionaries. 

Results are returned using callback blocks.

The API is designed for bulk operations; it takes a list of entities/properties to operate on, and returns lists or dictionaries of the combined results. 

## Backing Store

Current backing store is CoreData, but the intention is to make this completely opaque.

The main reason for using CoreData is to allow leverage of other solutions which provide automatic synchronisation of CoreData across devices.

## Interchange

The store can be read from, and written to, a dictionary-based interchange format. This only uses JSON-legal types, hence can be easily converted into JSON/XML/whatever.

## Future

Combine support is being considered.

## To Do

- set property value and type using SemanticValue
- export type information to interchange
- read in type information from interchange
- optimise interchange reading for compact values
- optimise interchange writing for compact values
- adding relationships
- encoding/decoding relationships
- getting all properties
