//
//  SwiftUIView.swift
//  
//
//  Created by Raveendran, Aravind on 7/1/2023.
//

import Foundation
import MillicastSDK

class PublishButtonViewModel: ObservableObject {
    func subscribe(streamName: String, accountID: String) -> Bool {
        let credentials = MCSubscriberCredentials()
        credentials.accountId = accountID
        credentials.streamName = streamName
        
        let subscriptionListener = SubscriptionListener()
        guard let subscriber = MCSubscriber.create() else {
            return false
        }
        subscriber.setListener(subscriptionListener)
        subscriber.setCredentials(credentials)
        return subscriber.connect()
    }
}
