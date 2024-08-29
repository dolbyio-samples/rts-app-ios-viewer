//
//  V2MigrationPolicy.swift
//

import CoreData
import RTSCore

class V2MigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Get the source attribute keys and values
        let sourceAttributeKeys = sInstance.entity.attributesByName.keys
        let sourceAttributeValues = sInstance.dictionaryWithValues(forKeys: sourceAttributeKeys.map { $0 as String })

        // Create the destination Note instance
        let destinationInstance = NSEntityDescription.insertNewObject(forEntityName: mapping.destinationEntityName!, into: manager.destinationContext)

        // Get the destination attribute keys
        let destinationAttributeKeys = destinationInstance.entity.attributesByName.keys.map { $0 as String }

        // Set all those attributes of the destination instance which are the same as those of the source instance
        for key in destinationAttributeKeys {
          if let value = sourceAttributeValues[key] {
            destinationInstance.setValue(value, forKey: key)
          }
        }

        // Set the value for field names that got changed
        if let useDevelopmentServer = sInstance.value(forKey: "useDevelopmentServer") as? Bool {
            let subscribeAPI = useDevelopmentServer ? SubscriptionConfiguration.Constants.developmentSubscribeURL
            : SubscriptionConfiguration.Constants.productionSubscribeURL
            destinationInstance.setValue(subscribeAPI, forKey: "subscribeAPI")
        }

        // Set the default values for fields that are new
        destinationInstance.setValue(0, forKey: "maxBitrate")
        destinationInstance.setValue(0, forKey: "maxPlayoutDelay")
        destinationInstance.setValue(0, forKey: "minPlayoutDelay")
        destinationInstance.setValue(150000, forKey: "bweMonitorDurationUs")
        destinationInstance.setValue(0.05, forKey: "bweRateChangePercentage")
        destinationInstance.setValue(true, forKey: "forceSmooth")
        destinationInstance.setValue(0, forKey: "upwardsLayerWaitTimeMs")

        manager.associate(sourceInstance: sInstance, withDestinationInstance: destinationInstance, for: mapping)
    }
}
