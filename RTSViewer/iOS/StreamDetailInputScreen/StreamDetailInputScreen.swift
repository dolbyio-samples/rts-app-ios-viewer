//
//  StreamDetailInputScreen.swift
//

import DolbyIOUIKit
import SwiftUI
import RTSComponentKit

struct StreamDetailInputScreen: View {

    enum InputFocusable: Hashable {
      case accountID
      case streamName
    }

    @State private var streamName: String = ""
    @State private var accountID: String = ""
    @State private var isShowingStreamingView = false
    @State private var showingAlert = false
    @FocusState private var inputFocus: InputFocusable?

    @StateObject private var viewModel: StreamDetailInputViewModel

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.presentationMode) private var presentationMode

    init(dataStore: RTSDataStore = .init()) {
        _viewModel = StateObject(
            wrappedValue: StreamDetailInputViewModel(dataStore: dataStore, streamDataManager: StreamDataManager.shared)
        )
    }

    var body: some View {
        ZStack {
            NavigationLink(destination: LazyNavigationDestinationView(StreamingScreen(dataStore: viewModel.dataStore)), isActive: $isShowingStreamingView) {
                EmptyView()
            }
            .hidden()

            VStack(spacing: 0) {
                if horizontalSizeClass == .regular {
                    Spacer()
                        .frame(height: Layout.spacing5x)
                }

                Text(
                    text: "stream-detail-input.title.label",
                    mode: .primary,
                    fontAsset: .avenirNextDemiBold(
                        size: FontSize.title1,
                        style: .title
                    )
                )

                Spacer()
                    .frame(height: Layout.spacing1x)

                Text(
                    text: "stream-detail-input.subtitle.label",
                    fontAsset: .avenirNextRegular(
                        size: FontSize.subhead,
                        style: .subheadline
                    )
                )
                .multilineTextAlignment(.center)

                Spacer()
                    .frame(height: Layout.spacing3x)

                VStack(spacing: Layout.spacing3x) {
                    DolbyIOUIKit.TextField(text: $streamName, placeholderText: "stream-detail-streamname-placeholder-label")
                        .focused($inputFocus, equals: .streamName)
                        .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))
                        .submitLabel(.next)
                        .onReceive(streamName.publisher) { _ in
                            streamName = String(streamName.prefix(64))
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                self.inputFocus = .streamName
                            }
                        }

                    DolbyIOUIKit.TextField(text: $accountID, placeholderText: "stream-detail-accountid-placeholder-label")
                        .focused($inputFocus, equals: .accountID)
                        .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))
                        .submitLabel(.done)
                        .onReceive(accountID.publisher) { _ in
                            accountID = String(accountID.prefix(64))
                        }

                    RTSComponentKit.SubscribeButton(
                        text: "stream-detail-input.play.button",
                        streamName: streamName,
                        accountID: accountID,
                        dataStore: viewModel.dataStore) { success in
                            showingAlert = !success
                            isShowingStreamingView = success
                            if success {
                                // A delay is added before saving the stream.
                                Task.delayed(byTimeInterval: 1.0) {
                                    await viewModel.saveStream(streamName: streamName, accountID: accountID)
                                }
                            }
                        }
                }
                .frame(maxWidth: 400)

                Spacer()
                    .frame(minHeight: Layout.spacing2x)

                FooterView(text: "stream-detail-input.footnote.label")

                Spacer()
                    .frame(height: Layout.spacing1x)

            }
            .padding([.leading, .trailing], Layout.spacing3x)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if presentationMode.wrappedValue.isPresented {
                    IconButton(name: .chevronLeft, tintColor: .white, action: {
                        presentationMode.wrappedValue.dismiss()
                    })
                }
            }
            ToolbarItem(placement: .principal) {
                IconView(name: .dolby_logo_dd, tintColor: .white)
            }
        }
        .navigationBarBackButtonHidden()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: UIColor.Background.black))
        .alert("stream-detail-input.credentials-error.label", isPresented: $showingAlert) { }
        .onSubmit {
            if inputFocus == .streamName {
                inputFocus = .accountID
            } else if inputFocus == .accountID {
                inputFocus = nil
            }
        }
    }
}

struct StreamDetailInputScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamDetailInputScreen()
    }
}
