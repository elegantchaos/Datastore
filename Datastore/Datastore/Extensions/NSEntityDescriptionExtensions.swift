// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

extension NSEntityDescription {
    
    /**
     Returns a predicate to compare a string against all suitable attributes,
     and return true if they all match.
     */
    
    public func allAttributesPredicate(comparing object: CVarArg, using comparison: String) -> NSPredicate {
        let predicates = textAttributePredicates(comparing: object, using: comparison)
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    /**
     Returns a predicate to compare a string against all suitable attributes,
     and return true if some of them match.
     */
    
    public func anyAttributesPredicate(comparing object: CVarArg, using comparison: String) -> NSPredicate {
        let predicates = textAttributePredicates(comparing: object, using: comparison)
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }
    
    /**
     Returns predicates for all attributes that can be matched against a text string.
    */
    
    public func textAttributePredicates(comparing object: CVarArg, using comparison: String) -> [NSPredicate] {
        var results: [NSPredicate] = []
        for (name, attribute) in attributesByName {
            switch attribute.attributeType {
            case .stringAttributeType:
                results.append(NSPredicate(format: "\(name) \(comparison) %@", object))
                
            default:
                break
            }
        }
        return results
    }
}
