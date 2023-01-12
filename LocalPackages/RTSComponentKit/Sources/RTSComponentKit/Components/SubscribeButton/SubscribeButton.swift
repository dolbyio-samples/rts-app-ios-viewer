//
//  SubscribeButton.swift
//  

import SwiftUI
import DolbyIOUIKit

public struct SubscribeButton: View {
    @State private var buttonState: DolbyIOUIKit.Button.ButtonState = .default
    @ObservedObject private var viewModel: SubscribeButtonViewModel

    public var text: LocalizedStringKey
    public var streamName: String
    public var accountID: String

    public var completion: (Bool) -> Void

    public init(text: LocalizedStringKey, streamName: String, accountID: String, dataStore: RTSDataStore, completion: @escaping (Bool) -> Void) {
        self.text = text
        self.streamName = streamName
        self.accountID = accountID
        self.completion = completion
        self.viewModel = SubscribeButtonViewModel(dataStore: dataStore)
    }

    public var body: some View {
        Button(
            action: {
                Task {
                    let success = await viewModel
                        .subscribe(streamName: streamName, accountID: accountID)
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
