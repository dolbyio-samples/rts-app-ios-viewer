//
//  SwiftUIView.swift
//  
//
//  Created by Raveendran, Aravind on 7/1/2023.
//

import SwiftUI
import DolbyIOUIKit

public struct PublishButton: View {
    @State private var buttonState: DolbyIOUIKit.Button.ButtonState = .default
    @ObservedObject private var viewModel: PublishButtonViewModel = .init()
    
    public var text: String
    public var completion: () -> Void
    
    public init(text: String, completion: @escaping () -> Void) {
        self.text = text
        self.completion = completion
    }

    public var body: some View {
        Button(
            action: {
                buttonState = .loading
                let success = viewModel
                    .subscribe(streamName: "lb5mbgci", accountID: "7rQPut")
                completion()
                buttonState = success ? .success : .default
            },
            text: text,
            buttonState: $buttonState
        )
    }
}

struct PublishButton_Previews: PreviewProvider {
    static var previews: some View {
        PublishButton(text: "Play", completion: {})
    }
}
