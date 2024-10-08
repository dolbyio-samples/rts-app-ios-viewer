//
//  StreamDetailInputScreen.swift
//

import DolbyIOUIKit
import MillicastSDK
import RTSCore
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
    @State private var useCustomServerURL: Bool = false
    @State private var showMaxBitrate: Bool = false
    @State private var showPlayoutDelay: Bool = false
    @State private var showMonitorDuration: Bool = false
    @State private var showRateChangePercentage: Bool = false
    @State private var showUpwardsLayerWaitTime: Bool = false
    @State private var subscribeAPI: String = SubscriptionConfiguration.Constants.developmentSubscribeURL
    @State private var disableAudio: Bool = false
    @State private var saveLogs: Bool = false
    @State private var jitterBufferDelayInMs = Float(SubscriptionConfiguration.Constants.jitterMinimumDelayMs)
    @State private var primaryVideoQuality: VideoQuality = .auto
    @State private var maxBitrateString: String = "0"
    @State private var isShowingSettingsView: Bool = false
    @State private var minPlayoutDelay = Float(SubscriptionConfiguration.Constants.jitterMinimumDelayMs)
    @State private var maxPlayoutDelay = Float(SubscriptionConfiguration.Constants.jitterMinimumDelayMs)
    @State private var forceSmooth: Bool = SubscriptionConfiguration.Constants.forceSmooth
    @State private var monitorDurationString: String = "\(SubscriptionConfiguration.Constants.bweMonitorDurationUs)"
    @State private var rateChangePercentage: Float = SubscriptionConfiguration.Constants.bweRateChangePercentage
    @State private var upwardsLayerWaitTimeString: String = "\(SubscriptionConfiguration.Constants.upwardsLayerWaitTimeMs)"

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
                                let api = useCustomServerURL ? subscribeAPI : SubscriptionConfiguration.Constants.productionSubscribeURL
                                let videoJitterMinimumDelayInMs = UInt(jitterBufferDelayInMs)
                                let minPlayoutDelay = showPlayoutDelay ? UInt(minPlayoutDelay) : UInt(SubscriptionConfiguration.Constants.playoutDelay.minimum)
                                let maxPlayoutDelay = showPlayoutDelay ? UInt(maxPlayoutDelay) : UInt(SubscriptionConfiguration.Constants.playoutDelay.maximum)
                                let maxBitrate: UInt = .init(maxBitrateString) ?? 0
                                let duration: UInt = UInt(self.monitorDurationString) ?? SubscriptionConfiguration.Constants.bweMonitorDurationUs
                                let waitTime: UInt = UInt(self.upwardsLayerWaitTimeString) ?? SubscriptionConfiguration.Constants.upwardsLayerWaitTimeMs

                                let success = viewModel.validateAndSaveStream(
                                    streamName: streamName,
                                    accountID: accountID,
                                    subscribeAPI: api,
                                    videoJitterMinimumDelayInMs: videoJitterMinimumDelayInMs,
                                    minPlayoutDelay: minPlayoutDelay,
                                    maxPlayoutDelay: maxPlayoutDelay,
                                    maxBitrate: maxBitrate,
                                    forceSmooth: self.forceSmooth,
                                    monitorDuration: duration,
                                    rateChangePercentage: self.rateChangePercentage,
                                    upwardLayerWaitTime: waitTime,
                                    disableAudio: disableAudio,
                                    primaryVideoQuality: primaryVideoQuality,
                                    saveLogs: saveLogs,
                                    persistStream: true
                                )
                                guard success else {
                                    showAlert = true
                                    return
                                }

                                let configuration = viewModel.configuration(
                                    subscribeAPI: api,
                                    videoJitterMinimumDelayInMs: videoJitterMinimumDelayInMs,
                                    minPlayoutDelay: minPlayoutDelay,
                                    maxPlayoutDelay: maxPlayoutDelay,
                                    maxBitrate: maxBitrate,
                                    disableAudio: disableAudio,
                                    primaryVideoQuality: primaryVideoQuality,
                                    saveLogs: saveLogs
                                )
                                streamingScreenContext = StreamingView.Context(
                                    streamName: streamName,
                                    accountID: accountID,
                                    listViewPrimaryVideoQuality: primaryVideoQuality,
                                    configuration: configuration
                                )
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
                Toggle(isOn: $useCustomServerURL) {
                    Text(
                        "stream-detail-input.development-placeholder-label",
                        font: .streamConfigurationItemsFont
                    )
                }

                if useCustomServerURL {
                    DolbyIOUIKit.TextField(text: $subscribeAPI, placeholderText: "stream-detail-server-url-label")
                        .accessibilityIdentifier("InputScreen.ServerURL")
                        .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))
                        .submitLabel(.next)
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
                    in: 0...2000,
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
                        in: 0...2000,
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
                        in: 0...2000,
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

                Toggle(isOn: $forceSmooth) {
                    Text(
                        "stream-detail-input.force-smooth-placeholder-label",
                        font: .streamConfigurationItemsFont
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
                        ForEach(VideoQuality.allCases) {
                            Text($0.displayText)
                                .tag($0)
                        }
                    }
                    .pickerStyle(.automatic)
                }

                Toggle(isOn: $showMaxBitrate) {
                    Text(
                        "stream-detail-input.set-max-bitrate-label",
                        font: .streamConfigurationItemsFont
                    )
                }

                if showMaxBitrate {
                    DolbyIOUIKit.TextField(text: $maxBitrateString, placeholderText: "stream-detail-input.max-bitrate-label")
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("InputScreen.MaximumBitrate")
                        .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))
                        .submitLabel(.next)
                }

                Toggle(isOn: $showMonitorDuration) {
                    Text(
                        "stream-detail-input.set-monitor-duration-toggle-label",
                        font: .streamConfigurationItemsFont
                    )
                }

                if showMonitorDuration {
                    DolbyIOUIKit.TextField(text: $monitorDurationString, placeholderText: "stream-detail-input.set-monitor-duration-label")
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("InputScreen.MonitorDuration")
                        .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))
                        .submitLabel(.next)
                }

                Toggle(isOn: $showUpwardsLayerWaitTime) {
                    Text(
                        "stream-detail-input.set-upwards-layer-wait-time-toggle-label",
                        font: .streamConfigurationItemsFont
                    )
                }

                if showUpwardsLayerWaitTime {
                    DolbyIOUIKit.TextField(text: $upwardsLayerWaitTimeString, placeholderText: "stream-detail-input.set-upwards-layer-wait-time-label")
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("InputScreen.WaitTime")
                        .font(.avenirNextRegular(withStyle: .caption, size: FontSize.caption1))
                        .submitLabel(.next)
                }

                Toggle(isOn: $showRateChangePercentage) {
                    Text(
                        "stream-detail-input.rate-change-percentage-toggle-label",
                        font: .streamConfigurationItemsFont
                    )
                }

                if showRateChangePercentage {
                    Text(
                        "\(String(localized: "stream-detail-input.rate-change-percentage-label")) - \(Int(rateChangePercentage * 100))%",
                        style: .labelMedium,
                        font: .custom("AvenirNext-Regular", size: FontSize.body, relativeTo: .body)
                    )
                    Slider(
                        value: $rateChangePercentage,
                        in: 0...1,
                        step: 0.05,
                        label: {},
                        minimumValueLabel: {
                            Text("0")
                        },
                        maximumValueLabel: {
                            Text("100%")
                        }
                    )
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

    @ViewBuilder
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

            demoButton
        }
    }

    @ViewBuilder
    var demoButton: some View {
        let streamName = Constants.streamName
        let accountID = Constants.accountID
        let productionSubscribeURL = SubscriptionConfiguration.Constants.productionSubscribeURL
        let jitterMinimumDelayMs = SubscriptionConfiguration.Constants.jitterMinimumDelayMs
        let disableAudio = false
        let videoQuality = VideoQuality.auto
        let saveLogs = false
        let forceSmooth = SubscriptionConfiguration.Constants.forceSmooth
        let duration = SubscriptionConfiguration.Constants.bweMonitorDurationUs
        let rateChange = SubscriptionConfiguration.Constants.bweRateChangePercentage
        let waitTime = SubscriptionConfiguration.Constants.upwardsLayerWaitTimeMs

        RecentStreamCell(streamDetail: SavedStreamDetail(
            accountID: accountID,
            streamName: streamName,
            subscribeAPI: productionSubscribeURL,
            videoJitterMinimumDelayInMs: jitterMinimumDelayMs,
            minPlayoutDelay: UInt(minPlayoutDelay),
            maxPlayoutDelay: UInt(maxPlayoutDelay),
            disableAudio: disableAudio,
            primaryVideoQuality: videoQuality,
            maxBitrate: 0,
            forceSmooth: forceSmooth,
            monitorDuration: UInt(duration),
            rateChangePercentage: rateChange,
            upwardsLayerWaitTimeMs: UInt(waitTime),
            saveLogs: saveLogs
        )) {
            let success = viewModel.validateAndSaveStream(
                streamName: streamName,
                accountID: accountID,
                subscribeAPI: productionSubscribeURL,
                videoJitterMinimumDelayInMs: jitterMinimumDelayMs,
                minPlayoutDelay: UInt(minPlayoutDelay),
                maxPlayoutDelay: UInt(maxPlayoutDelay),
                maxBitrate: 0,
                forceSmooth: forceSmooth,
                monitorDuration: duration,
                rateChangePercentage: rateChange,
                upwardLayerWaitTime: waitTime,
                disableAudio: disableAudio,
                primaryVideoQuality: videoQuality,
                saveLogs: saveLogs,
                persistStream: false
            )

            guard success else {
                showAlert = true
                return
            }

            let configuration = SubscriptionConfiguration(
                subscribeAPI: productionSubscribeURL,
                jitterMinimumDelayMs: jitterMinimumDelayMs,
                disableAudio: disableAudio,
                rtcEventLogPath: nil,
                sdkLogPath: nil
            )
            streamingScreenContext = StreamingView.Context(
                streamName: streamName,
                accountID: accountID,
                listViewPrimaryVideoQuality: .auto,
                configuration: configuration
            )
        }
    }

    func resetStreamConfigurationState() {
        useCustomServerURL = false
        showPlayoutDelay = false
        disableAudio = false
        jitterBufferDelayInMs = Float(SubscriptionConfiguration.Constants.jitterMinimumDelayMs)
        primaryVideoQuality = .auto
        saveLogs = false
        minPlayoutDelay = 0
        maxPlayoutDelay = 0
        maxBitrateString = "0"
        forceSmooth = SubscriptionConfiguration.Constants.forceSmooth
        rateChangePercentage = SubscriptionConfiguration.Constants.bweRateChangePercentage
        upwardsLayerWaitTimeString = "\(SubscriptionConfiguration.Constants.upwardsLayerWaitTimeMs)"
        monitorDurationString = "\(SubscriptionConfiguration.Constants.bweMonitorDurationUs)"
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
