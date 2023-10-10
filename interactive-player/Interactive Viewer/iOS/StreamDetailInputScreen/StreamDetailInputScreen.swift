//
//  StreamDetailInputScreen.swift
//

import DolbyIOUIKit
import DolbyIORTSCore
import DolbyIORTSUIKit
import SwiftUI

struct StreamDetailInputScreen: View {

    enum InputFocusable: Hashable {
      case accountID
      case streamName
    }
    @Binding private var isShowingSettingScreenView: Bool
    @Binding private var playedStreamDetail: DolbyIORTSCore.StreamDetail?

    @State private var streamName: String = ""
    @State private var accountID: String = ""
    @State private var showingAlert = false

    @FocusState private var inputFocus: InputFocusable?

    @StateObject private var viewModel: StreamDetailInputViewModel = .init()

    @ObservedObject private var themeManager = ThemeManager.shared

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.presentationMode) private var presentationMode

    init(isShowingSettingScreenView: Binding<Bool>, playedStreamDetail: Binding<DolbyIORTSCore.StreamDetail?>) {
        _isShowingSettingScreenView = isShowingSettingScreenView
        _playedStreamDetail = playedStreamDetail
    }

    var body: some View {
        ZStack {
            NavigationLink(
                destination: LazyNavigationDestinationView(
                    SettingsScreen(mode: .global)
                ),
                isActive: $isShowingSettingScreenView
            ) {
                EmptyView()
            }
            .hidden()

            ScrollView {
                VStack(spacing: 0) {
                    if horizontalSizeClass == .regular {
                        Spacer()
                            .frame(height: Layout.spacing5x)
                    } else {
                        Spacer()
                            .frame(height: Layout.spacing3x)
                    }

                    Text(
                        "stream-detail-input.title.label",
                        style: .labelMedium,
                        font: .custom("AvenirNext-DemiBold", size: FontSize.title1, relativeTo: .title)
                    )

                    Spacer()
                        .frame(height: Layout.spacing3x)

                    Text(
                        "stream-detail-input.start-a-stream.label",
                        style: .labelMedium,
                        font: .custom("AvenirNext-DemiBold", size: FontSize.title2, relativeTo: .title)
                    )

                    Spacer()
                        .frame(height: Layout.spacing1x)

                    Text(
                        "stream-detail-input.subtitle.label",
                        font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
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

                        Button(
                            action: {
                                guard streamName.count > 0, accountID.count > 0 else {
                                    showingAlert = true
                                    return
                                }
                                Task {
                                    let success = await StreamOrchestrator.shared.connect(streamName: streamName, accountID: accountID)
                                    await MainActor.run {
                                        guard success else {
                                            showingAlert = true
                                            return
                                        }
                                        playedStreamDetail = DolbyIORTSCore.StreamDetail(
                                            streamName: streamName,
                                            accountID: accountID
                                        )
                                        if success {
                                            // A delay is added before saving the stream.
                                            Task.delayed(byTimeInterval: 1.0) {
                                                await viewModel.saveStream(streamName: streamName, accountID: accountID)
                                            }
                                        }
                                    }
                                }
                            },
                            text: "stream-detail-input.play.button"
                        )
                    }
                    .frame(maxWidth: 400)

                    Spacer()

                    VStack {
                        Spacer()

                        demoAStream

                        Spacer()
                    }
                }
                .padding([.leading, .trailing], Layout.spacing3x)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if presentationMode.wrappedValue.isPresented {
                    IconButton(iconAsset: .chevronLeft, tintColor: .white, action: {
                        presentationMode.wrappedValue.dismiss()
                    })
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if presentationMode.wrappedValue.isPresented {
                    IconButton(iconAsset: .settings, action: {
                        isShowingSettingScreenView = true
                    }).scaleEffect(0.5, anchor: .trailing)
                }
            }

            ToolbarItem(placement: .bottomBar) {
                if presentationMode.wrappedValue.isPresented {
                    FooterView(text: "stream-detail-input.footnote.label")
                }
            }
        }
        .navigationBarBackButtonHidden()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: themeManager.theme.background))
        .alert("stream-detail-input.credentials-error.label", isPresented: $showingAlert) { }
        .onSubmit {
            if inputFocus == .streamName {
                inputFocus = .accountID
            } else if inputFocus == .accountID {
                inputFocus = nil
            }
        }
        .onTapGesture {
            inputFocus = nil
        }
    }

    var demoAStream: some View {
        VStack {
            Text(
                "stream-detail-input.demo-stream.label",
                style: .labelMedium,
                font: .custom("AvenirNext-DemiBold", size: FontSize.title2, relativeTo: .title)
            )

            Spacer()
                .frame(height: Layout.spacing1x)

            Text(
                "stream-detail-input.try-a-demo.label",
                font: .custom("AvenirNext-Regular", size: FontSize.subhead, relativeTo: .subheadline)
            )

            Spacer()
                .frame(height: Layout.spacing2x)

            let streamName = Constants.streamName
            let accountID = Constants.accountID
            RecentStreamCell(streamName: streamName, accountID: accountID) {
                Task {
                    let success = await viewModel.connect(streamName: streamName, accountID: accountID)
                    guard success else {
                        showingAlert = true
                        return
                    }
                    await MainActor.run {
                        playedStreamDetail = DolbyIORTSCore.StreamDetail(
                            streamName: streamName,
                            accountID: accountID
                        )
                    }
                }
            }
        }
    }
}

struct StreamDetailInputScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamDetailInputScreen(isShowingSettingScreenView: .constant(false), playedStreamDetail: .constant(nil))
    }
}
