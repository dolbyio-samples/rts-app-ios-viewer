//
//  SubscribeButton.swift
//  

import SwiftUI
import DolbyIOUIKit
import RTSComponentKit

struct SubscribeButton: View {
    @State private var buttonState: DolbyIOUIKit.Button.ButtonState = .default

    private let dataStore: RTSDataStore
    private let text: LocalizedStringKey
    private let streamName: String
    private let accountID: String
    private let completion: (Bool) -> Void

    init(text: LocalizedStringKey, streamName: String, accountID: String, dataStore: RTSDataStore, completion: @escaping (Bool) -> Void) {
        self.text = text
        self.streamName = streamName
        self.accountID = accountID
        self.dataStore = dataStore
        self.completion = completion
    }

    var body: some View {
        Button(
            action: {
                Task {
                    let success = await dataStore.connect(streamName: streamName, accountID: accountID)
                    await MainActor.run {
                        completion(success)
                    }
                }
            },
            text: text,
            buttonState: $buttonState
        )
    }
}

#if DEBUG
struct SubscribeButton_Previews: PreviewProvider {
    static var previews: some View {
        SubscribeButton(text: "Play", streamName: "", accountID: "", dataStore: .init(), completion: { _ in })
    }
}
#endif
