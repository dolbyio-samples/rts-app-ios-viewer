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
    @Binding private var streamingScreenContext: StreamingView.Context?

    @State private var streamName: String = ""
    @State private var accountID: String = ""
    @State private var showAlert = false
    @State private var isDev: Bool = false
    @State private var disableAudio: Bool = false
    @State private var saveLogs: Bool = false
    @State private var jitterBufferDelayInMs: Float = Float(SubscriptionConfiguration.Constants.jitterMinimumDelayMs)
    @State private var primaryVideoQuality: DolbyIORTSUIKit.VideoQuality = .auto
    @State private var isShowingSettingsView: Bool = false
    @State private var showPlayoutDelay: Bool = false
    @State private var minPlayoutDelay: Float = Float(SubscriptionConfiguration.Constants.jitterMinimumDelayMs)
    @State private var maxPlayoutDelay: Float = Float(SubscriptionConfiguration.Constants.jitterMinimumDelayMs)

    @FocusState private var inputFocus: InputFocusable?

    @StateObject private var viewModel: StreamDetailInputViewModel = .init()

    @ObservedObject private var themeManager = ThemeManager.shared

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.presentationMode) private var presentationMode

    @AppConfiguration(\.showDebugFeatures) var showDebugFeatures

    init(streamingScreenContext: Binding<StreamingView.Context?>) {
        _streamingScreenContext = streamingScreenContext
    }

    var body: some View {
        ZStack {
            NavigationLink(
                destination: SettingsScreen(mode: .global, moreSettings: {
                    AppSettingsView()
                }),
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
                            .accessibilityIdentifier("InputScreen.StreamNameInput")
                            .focused($inputFocus, equals: .streamName)
                            .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))
                            .submitLabel(.next)
                            .onReceive(streamName.publisher) { _ in
                                streamName = String(streamName.prefix(64))
                            }

                        DolbyIOUIKit.TextField(text: $accountID, placeholderText: "stream-detail-accountid-placeholder-label")
                            .accessibilityIdentifier("InputScreen.AccountIDInput")
                            .focused($inputFocus, equals: .accountID)
                            .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))
                            .submitLabel(.done)
                            .onReceive(accountID.publisher) { _ in
                                accountID = String(accountID.prefix(64))
                            }

                        Button(
                            action: {
                                let success = viewModel.connect(
                                    streamName: streamName,
                                    accountID: accountID,
                                    useDevelopmentServer: isDev,
                                    videoJitterMinimumDelayInMs: UInt(jitterBufferDelayInMs),
                                    minPlayoutDelay: showPlayoutDelay ? UInt(minPlayoutDelay) : nil,
                                    maxPlayoutDelay: showPlayoutDelay ? UInt(maxPlayoutDelay) : nil,
                                    disableAudio: disableAudio,
                                    primaryVideoQuality: primaryVideoQuality,
                                    saveLogs: saveLogs,
                                    saveStream: true
                                )
                                showAlert = !success
                                if success {
                                    streamingScreenContext = .init(
                                        streamName: streamName,
                                        accountID: accountID,
                                        listViewPrimaryVideoQuality: primaryVideoQuality,
                                        subscriptionManager: viewModel.subscriptionManager
                                    )
                                }
                            },
                            text: "stream-detail-input.play.button"
                        )

                        if showDebugFeatures {
                            additionalConfigurationView
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
                    .accessibilityIdentifier("InputScreen.BackIconButton")
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if presentationMode.wrappedValue.isPresented {
                    IconButton(iconAsset: .settings, action: {
                        isShowingSettingsView = true
                    })
                    .accessibilityIdentifier("InputScreen.SettingButton")
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
        .onChange(of: showPlayoutDelay) { _ in
            resetPlayoutDelays()
        }
        .onChange(of: minPlayoutDelay) { _ in
            syncMaxPlayoutDelay()
        }
        .onChange(of: maxPlayoutDelay) { _ in
            syncMinPlayoutDelay()
        }
    }

    var additionalConfigurationView: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: Layout.spacing2x) {
                Toggle(isOn: $isDev) {
                    Text(
                        "stream-detail-input.development-placeholder-label",
                        font: .streamConfigurationItemsFont
                    )
                }
                Toggle(isOn: $disableAudio) {
                    Text(
                        "stream-detail-input.disable-audio-placeholder-label",
                        font: .streamConfigurationItemsFont
                    )
                }

                Toggle(isOn: $saveLogs) {
                    Text(
                        "stream-detail-input.save-logs-placeholder-label",
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

                Toggle(isOn: $showPlayoutDelay) {
                    Text(
                        "stream-detail-input.show-playout-delay-label",
                        font: .streamConfigurationItemsFont
                    )
                }

                if showPlayoutDelay {
                    Text(
                        "\(String(localized: "stream-detail-input.minimum-playout-delay-placeholder-label")) - \(Int(minPlayoutDelay))ms",
                        style: .labelMedium,
                        font: .custom("AvenirNext-Regular", size: FontSize.body, relativeTo: .body)
                    )

                    Slider(
                        value: $minPlayoutDelay,
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

                    Text(
                        "\(String(localized: "stream-detail-input.maximum-playout-delay-placeholder-label")) - \(Int(maxPlayoutDelay))ms",
                        style: .labelMedium,
                        font: .custom("AvenirNext-Regular", size: FontSize.body, relativeTo: .body)
                    )

                    Slider(
                        value: $maxPlayoutDelay,
                        in: (0...2000),
                        step: 50,
                        label: {},
                        minimumValueLabel: {
                            Text("\(Int(minPlayoutDelay))")
                        },
                        maximumValueLabel: {
                            Text("2sec")
                        }
                    )
                }

                HStack {
                    Text("stream-detail-input.primary-video-quality-label",
                         style: .labelMedium,
                         font: .custom("AvenirNext-Regular", size: FontSize.body, relativeTo: .body))

                    Picker(
                        "Primary video quality: \(primaryVideoQuality.displayText.uppercased())",
                        selection: $primaryVideoQuality
                    ) {
                        ForEach(DolbyIORTSUIKit.VideoQuality.allCases) {
                            Text($0.displayText)
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
                videoJitterMinimumDelayInMs: SubscriptionConfiguration.Constants.jitterMinimumDelayMs,
                minPlayoutDelay: SubscriptionConfiguration.Constants.minPlayoutDelay,
                maxPlayoutDelay: SubscriptionConfiguration.Constants.maxPlayoutDelay,
                disableAudio: false,
                primaryVideoQuality: .auto,
                saveLogs: false
            )
            RecentStreamCell(streamDetail: streamDetail) {
                let success = viewModel.connect(
                    streamName: streamName,
                    accountID: accountID,
                    useDevelopmentServer: false,
                    videoJitterMinimumDelayInMs: SubscriptionConfiguration.Constants.jitterMinimumDelayMs,
                    minPlayoutDelay: SubscriptionConfiguration.Constants.minPlayoutDelay,
                    maxPlayoutDelay: SubscriptionConfiguration.Constants.maxPlayoutDelay,
                    disableAudio: false,
                    primaryVideoQuality: .auto,
                    saveLogs: false,
                    saveStream: false
                )
                showAlert = !success
                if success {
                    streamingScreenContext = .init(
                        streamName: streamName,
                        accountID: accountID,
                        listViewPrimaryVideoQuality: .auto,
                        subscriptionManager: viewModel.subscriptionManager
                    )
                }
            }
        }
    }

    func resetStreamConfigurationState() {
        self.isDev = false
        self.showPlayoutDelay = false
        self.disableAudio = false
        self.jitterBufferDelayInMs = Float(SubscriptionConfiguration.Constants.jitterMinimumDelayMs)
        self.primaryVideoQuality = .auto
        self.saveLogs = false
        self.minPlayoutDelay = 0
        self.maxPlayoutDelay = 0
    }

    func syncMaxPlayoutDelay() {
        if minPlayoutDelay > maxPlayoutDelay {
            maxPlayoutDelay = minPlayoutDelay
        }
    }

    func syncMinPlayoutDelay() {
        if minPlayoutDelay > maxPlayoutDelay {
            minPlayoutDelay = maxPlayoutDelay
        }
    }

    func resetPlayoutDelays() {
        minPlayoutDelay = 0
        maxPlayoutDelay = 0
    }
}
// swiftlint:enable type_body_length

extension Font {
    static let streamConfigurationItemsFont = Font.custom("AvenirNext-Regular", size: FontSize.body, relativeTo: .body)
}

struct StreamDetailInputScreen_Previews: PreviewProvider {
    static var previews: some View {
        StreamDetailInputScreen(streamingScreenContext: .constant(nil))
    }
}
