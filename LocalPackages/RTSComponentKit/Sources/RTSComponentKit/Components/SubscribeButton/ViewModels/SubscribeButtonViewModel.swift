//
//  SubscribeButtonViewModel.swift
//

import Foundation
import MillicastSDK

final class SubscribeButtonViewModel: ObservableObject {
    private let dataStore: RTSDataStore
        
    init(dataStore: RTSDataStore) {
        self.dataStore = dataStore
    }
    
    func subscribe(streamName: String, accountID: String) async -> Bool {
        let success = await dataStore.connect(streamName: streamName, accountID: accountID)
        return success
    }
}
