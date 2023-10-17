//
//  StreamDetailInputScreen.swift
//

import DolbyIOUIKit
import DolbyIORTSCore
import DolbyIORTSUIKit
import SwiftUI

// swiftlint:disable type_body_length
struct StreamDetailInputScreen: View {

    enum InputFocusable: Hashable {
      case accountID
      case streamName
    }
    @Binding private var isShowingSettingsView: Bool
    @Binding private var streamingScreenContext: StreamingScreen.Context?

    @State private var streamName: String = ""
    @State private var accountID: String = ""
    @State private var showAlert = false
    @State private var isDev: Bool = false
    @State private var noPlayoutDelay: Bool = false
    @State private var disableAudio: Bool = false
    @State private var jitterBufferDelayInMs: Float = Float(SubscriptionConfiguration.Constants.videoJitterMinimumDelayInMs)
    @State private var primaryVideoQuality: VideoQuality = .auto

    @FocusState private var inputFocus: InputFocusable?

    @StateObject private var viewModel: StreamDetailInputViewModel = .init()

    @ObservedObject private var themeManager = ThemeManager.shared

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.presentationMode) private var presentationMode

    @AppConfiguration(\.showDebugFeatures) var showDebugFeatures

    init(isShowingSettingsView: Binding<Bool>, streamingScreenContext: Binding<StreamingScreen.Context?>) {
        _isShowingSettingsView = isShowingSettingsView
        _streamingScreenContext = streamingScreenContext
    }

    var body: some View {
        ZStack {
            NavigationLink(
                destination: LazyNavigationDestinationView(
                    SettingsScreen(mode: .global)
                ),
                isActive: $isShowingSettingsView
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

                        DolbyIOUIKit.TextField(text: $accountID, placeholderText: "stream-detail-accountid-placeholder-label")
                            .focused($inputFocus, equals: .accountID)
                            .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))
                            .submitLabel(.done)
                            .onReceive(accountID.publisher) { _ in
                                accountID = String(accountID.prefix(64))
                            }

                        Button(
                            action: {
                                Task {
                                    let success = await viewModel.connect(
                                        streamName: streamName,
                                        accountID: accountID,
                                        useDevelopmentServer: isDev,
                                        videoJitterMinimumDelayInMs: UInt(jitterBufferDelayInMs),
                                        noPlayoutDelay: noPlayoutDelay,
                                        disableAudio: disableAudio,
                                        primaryVideoQuality: primaryVideoQuality,
                                        shouldSave: true
                                    )
                                    showAlert = !success
                                    if success {
                                        await MainActor.run {
                                            streamingScreenContext = .init(
                                                streamName: streamName,
                                                accountID: accountID,
                                                listViewPrimaryVideoQuality: primaryVideoQuality
                                            )
                                        }
                                    }
                                }
                            },
                            text: "stream-detail-input.play.button"
                        )

                        if showDebugFeatures {
                            DisclosureGroup {
                                VStack(alignment: .leading, spacing: Layout.spacing2x) {
                                    Toggle(isOn: $isDev) {
                                        Text(
                                            "stream-detail-input.development-placeholder-label",
                                            font: .streamConfigurationItemsFont
                                        )
                                    }
                                    Toggle(isOn: $noPlayoutDelay) {
                                        Text(
                                            "stream-detail-input.no-playout-delay-label",
                                            font: .streamConfigurationItemsFont
                                        )
                                    }
                                    Toggle(isOn: $disableAudio) {
                                        Text(
                                            "stream-detail-input.disable-audio-placeholder-label",
                                            font: .streamConfigurationItemsFont
                                        )
                                    }

                                    Text(
                                        "\(String(localized: "stream-detail-input.jitter-buffer-delay-placeholder-label")) - \(Int(jitterBufferDelayInMs))ms",
                                        style: .labelMedium,
                                        font: .custom("AvenirNext-Regular", size: FontSize.body, relativeTo: .body)
                                    )
                                    Slider(
                                        value: $jitterBufferDelayInMs,
                                        in: (0...2000),
                                        step: 50,
                                        label: {},
                                        minimumValueLabel: {
                                            Text("0")
                                        },
                                        maximumValueLabel: {
                                            Text("2sec")
                                        }
                                    )

                                    HStack {
                                        Text("stream-detail-input.primary-video-quality-label",
                                             style: .labelMedium,
                                             font: .custom("AvenirNext-Regular", size: FontSize.body, relativeTo: .body))

                                        Picker(
                                            "Primary video quality: \(primaryVideoQuality.description)",
                                            selection: $primaryVideoQuality
                                        ) {
                                            ForEach(VideoQuality.allCases) {
                                                Text($0.description)
                                                    .tag($0)
                                            }
                                        }
                                        .pickerStyle(.automatic)
                                    }
                                }
                                .padding()
                                .background(Color(uiColor: themeManager.theme.neutral700))
                                .cornerRadius(Layout.cornerRadius6x)
                            } label: {
                                Text(
                                    "stream-detail-input.configure-stream-label",
                                    font: .streamConfigurationItemsFont
                                )
                                .frame(minHeight: Layout.spacing5x)
                            }
                            .accentColor(Color(uiColor: themeManager.theme.onBackground))
                        }
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
                        isShowingSettingsView = true
                    })
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
        .alert(isPresented: $showAlert, error: viewModel.validationError) {
            // No-actions
        }
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
        .onAppear {
            inputFocus = .streamName
        }
        .onDisappear {
            inputFocus = nil
        }
        .onChange(of: showDebugFeatures) { _ in
            resetStreamConfigurationState()
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
            let streamDetail = SavedStreamDetail(
                accountID: accountID,
                streamName: streamName,
                useDevelopmentServer: false,
                videoJitterMinimumDelayInMs: SubscriptionConfiguration.Constants.videoJitterMinimumDelayInMs,
                noPlayoutDelay: false,
                disableAudio: false,
                primaryVideoQuality: .auto
            )
            RecentStreamCell(streamDetail: streamDetail) {
                Task {
                    let success = await viewModel.connect(
                        streamName: streamName,
                        accountID: accountID,
                        useDevelopmentServer: false,
                        videoJitterMinimumDelayInMs: SubscriptionConfiguration.Constants.videoJitterMinimumDelayInMs,
                        noPlayoutDelay: false,
                        disableAudio: false,
                        primaryVideoQuality: .auto,
                        shouldSave: false
                    )
                    showAlert = !success
                    if success {
                        await MainActor.run {
                            streamingScreenContext = .init(
                                streamName: streamName,
                                accountID: accountID,
                                listViewPrimaryVideoQuality: .auto
                            )
                        }
                    }
                }
            }
        }
    }

    func resetStreamConfigurationState() {
        self.isDev = false
        self.noPlayoutDelay = false
        self.disableAudio = false
        self.jitterBufferDelayInMs = Float(SubscriptionConfiguration.Constants.videoJitterMinimumDelayInMs)
        self.primaryVideoQuality = .auto
    }
}
// swiftlint:enable type_body_length

extension Font {
    static let streamConfigurationItemsFont = Font.custom("AvenirNext-Regular", size: FontSize.body, relativeTo: .body)
}

struct StreamDetailInputScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamDetailInputScreen(isShowingSettingsView: .constant(false), streamingScreenContext: .constant(nil))
    }
}
