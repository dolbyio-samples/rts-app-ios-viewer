# Dolby.io Interactive Player - iOS App

## Readme

This project demonstrates what a simple Realtime Streaming monitor experience is like when built for an iOS device.

| Use cases                        | Features                                                         | Tech Stack |
| -------------------------------- | ---------------------------------------------------------------- | ---------- |
| Multisource video stream monitor | Start a stream monitoring with a stream name and account ID pair | Swift, iOS |

## Pre-requisites

This setup guide is validated on both Intel/M1-based MacBook Pro running macOS 13.4.1.

### Apple

* Xcode Version 14.3.1 (14E300c)
* iPhone simulator running iOS 15.0

### Other

* A [Dolby.io](https://dashboard.dolby.io/signup/) account
* Start a video streaming broadcasting, see [here](https://docs.dolby.io/streaming-apis/docs/how-to-broadcast-in-dashboard) 
* The Stream name and Account ID pair from the video streaming above

### How to get a Dolby.io account

To setup your Dolby.io account, go to the [Dolby.io dashboard](https://dashboard.dolby.io/signup/) and complete the form. After confirming your email address, you will be logged in.  

## Cloning the repo

The Dolby.io Realtime Streaming Monitor sample app is hosted in an Xcode project.

Get the code by cloning this repo using git.

> **_Info:_** The main branch is constantly under development. Get a tagged branch for a stable release.

```bash
git clone git@github.com:dolbyio-samples/rts-app-ios-viewer.git
```

## Building and running the app

Go to the project directory, and open the Xcode project - `RTSViewer.xcodeproj` by either double-clicking on it or from the Xcode directly.

From the top of the Xcode, Select either the scheme `InteractivePlayer`.

From the top of the Xcode, select the actual target to be run on.

> **_Info:_** To run on a real device you need to have an **Apple Developer Account**. For more information, see Apple documentation.

If a real device is selected, you shall connect or pair the device with your Xcode first. This is not necessary if a simulator is selected. The Xcode shall start the simulator and connect with the selected simulator automatically in the next step.

Click on the `Start` ► button on top of the Xcode to start running and debugging the app.

## Known Issues

The known issues of this sample app can be found [here](KNOWN-ISSUES.md).

## License

The Dolby.io Realtime Streaming Monitor sample and its repository are licensed under the MIT License.

## More resources

Looking for more sample apps and projects? Head to the [Project Gallery](https://docs.dolby.io/communications-apis/page/gallery).
