<!--
[![Build Package](https://github.com/dolbyio-samples/template-repo/actions/workflows/build-package.yml/badge.svg)](https://github.com/dolbyio-samples/template-repo/actions/workflows/build-package.yml)
[![Publish Package](https://github.com/dolbyio-samples/template-repo/actions/workflows/publish-package.yml/badge.svg)](https://github.com/dolbyio-samples/template-repo/actions/workflows/publish-package.yml)
[![npm](https://img.shields.io/npm/v/dolbyio-samples/template-repo)](https://www.npmjs.com/package/dolbyio-samples/template-repo)
[![License](https://img.shields.io/github/license/dolbyio-samples/template-repo)](LICENSE)

Adding shields would also be amazing -->

# Dolby.io Real-time Streaming UIKit for iOS

## Overview

The [Dolby.io Real-time Streaming](https://dolby.io/products/real-time-streaming/) UIKit for iOS is designed to help iOS developers reduce the complexity of building a Dolby.io Real-time Streaming (RTS) monitor applications for iOS.

This package consists of three kinds of components:  

* `DolbyIORTSUIKit`: The high-level UI components that can be used to develop a real-time streaming monitoring app for iOS with Dolby.io.  
* `DolbyIORTSCore`: The logic between `DolbyIORTSUIKit` and Dolby.io [Real-time Streaming iOS SDK](https://docs.dolby.io/streaming-apis/docs/ios).
* `DolbyIOUIKit`: The basic UI components used by `DolbyIORTSUIKit`.  

> **_Note:_** There are two parties in RTS - a publisher and a viewer. A publisher is one who broadcasts the stream. A viewer is one who consumes the stream. This UIKit is meant for viewer/monitor applications. Please refer to this [blog post](https://dolby.io/blog/real-time-streaming-with-dolby-io/) to understand the ecosystem.

## Requirements

This setup guide is validated on both Intel and Apple Silicon based MacBook Pro machines running macOS 13.4.

* Xcode Version 14.3.1 (14E300c)
* iPhone device or simulator running iOS 15.0
* Familiarity with iOS development using Swift and Swift UI

## Getting Started

This guide demostrates how to use the RTS UI components to quickly build a streaming monitor app for iOS devices.

### Build a Sample App

To get started with building your own app with the RTS UI kit, see below.

* Create a new Xcode project.
* Choose the `iOS App` as template.
* Fill in the Product Name.
* Select "SwiftUI" as `Interface`.
* Select "Swift" as `Language`.
* Create the project in a folder.
* Add this UIKit as dependencies to the newly created project.  
  * Go to `File` > `Add Package`.
  * Put the [URL of this repo](https://github.com/DolbyIO/rts-uikit-ios) in the pop-up window's top-right corner text field.
  * Use `Up to Next Major Version` in the `Dependency Rule`.
  * Click the `Add Package` button.
  * Choose and add these packages `DolbyIORTSCore`,  `DolbyIORTSUIKit`, and `DolbyIOUIKit` to the target.
  * Click the `Add Package` button.
* Copy and replace the code in `ContentView.swift` with the code snippet below.
* Compile and Run on an iOS target.

```swift
import SwiftUI

// 1. Include Dolby.io UIKit and related packages
import DolbyIORTSCore
import DolbyIORTSUIKit

struct ContentView: View {
    // 2. State to show if the stream is live or not
    @State private var showStream = false

    var body: some View {
        NavigationView {
            ZStack {
                
                // 3. Navigation link to the streaming screen if `showStream` is true
                NavigationLink(destination: StreamingScreen(isShowingStreamView: $showStream), isActive: $showStream) { EmptyView() }
                Button ("Start Stream") {
                
                    // 4. Async task connects the viewer with the given stream name and account ID. The stream name and 
                    // account ID pair here is from a demo stream. It can be replaced by a pair being given by a publisher who has 
                    // signed-up up to the Dolby.io service. See the next section below to set up your own streams.
                    Task {
                        let success = await StreamOrchestrator.shared.connect(streamName: "simulcastmultiview", accountID: "k9Mwad")
                        
                        // 5. Show the real-time streaming if connect successfully
                        await MainActor.run { showStream = success }
                    }
                }
            }.preferredColorScheme(.dark)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
```

This app has a `Start stream` button which starts playing a demo stream in the app. The streaming screen contains all the components you need to build your experience - including a settings menu where you can select different video layouts, audio source selection, and stream sort order.

## Sign up for a Dolby.io account

A Dolby.io account is necessary to publish your own RTS stream. To set up your Dolby.io account, go to [Dolby.io dashboard](https://dashboard.dolby.io) and complete the form. After confirming your email address, you will be logged in.

## Installation

This UIKit package uses Swift Packages. You can add this package site URL as a dependency in your app. Details can be found [here](https://developer.apple.com/documentation/xcode/swift-packages)

> **_Info:_** The main branch is constantly under active development. Get a tagged branch for a stable release.

## Starting your own stream

To start your own video stream broadcast using the Dolby.io dashboard, see [this guide](https://docs.dolby.io/streaming-apis/docs/how-to-broadcast-in-dashboard). To set up your own stream that can be consumed in this app, follow [this guide](https://docs.dolby.io/streaming-apis/docs/managing-your-tokens#creating-a-publishing-token) and copy over the stream name and stream ID into the app.

## License

The Dolby.io Real-time UIKit for iOS and its repository are licensed under the MIT License. Before using this, please review and accept the [Dolby Software License Agreement](LICENSE).

# About Dolby.io

Using decades of Dolby's research in sight and sound technology, Dolby.io provides APIs to integrate real-time streaming, voice & video communications, and file-based media processing into your applications. [Sign up for a free account](https://dashboard.dolby.io/signup/) to start building the next generation of immersive, interactive, and social apps.

&copy; Dolby, 2023

<div align="center">
  <a href="https://dolby.io/" target="_blank"><img src="https://img.shields.io/badge/Dolby.io-0A0A0A?style=for-the-badge&logo=dolby&logoColor=white"/></a>
&nbsp; &nbsp; &nbsp;
  <a href="https://docs.dolby.io/" target="_blank"><img src="https://img.shields.io/badge/Dolby.io-Docs-0A0A0A?style=for-the-badge&logoColor=white"/></a>
&nbsp; &nbsp; &nbsp;
  <a href="https://dolby.io/blog/category/developer/" target="_blank"><img src="https://img.shields.io/badge/Dolby.io-Blog-0A0A0A?style=for-the-badge&logoColor=white"/></a>
</div>

<div align="center">
&nbsp; &nbsp; &nbsp;
  <a href="https://youtube.com/@dolbyio" target="_blank"><img src="https://img.shields.io/badge/YouTube-red?style=flat-square&logo=youtube&logoColor=white" alt="Dolby.io on YouTube"/></a>
&nbsp; &nbsp; &nbsp; 
  <a href="https://twitter.com/dolbyio" target="_blank"><img src="https://img.shields.io/badge/Twitter-blue?style=flat-square&logo=twitter&logoColor=white" alt="Dolby.io on Twitter"/></a>
&nbsp; &nbsp; &nbsp;
  <a href="https://www.linkedin.com/company/dolbyio/" target="_blank"><img src="https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white" alt="Dolby.io on LinkedIn"/></a>
</div>


