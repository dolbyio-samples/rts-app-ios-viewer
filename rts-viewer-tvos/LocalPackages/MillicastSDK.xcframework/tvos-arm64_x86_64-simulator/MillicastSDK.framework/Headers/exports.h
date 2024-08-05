#ifndef MILLICAST_EXPORTS_H
#define MILLICAST_EXPORTS_H

#ifdef __APPLE__
#include <TargetConditionals.h>
#if defined(TARGET_OS_IOS) && TARGET_OS_IOS == 1
#ifndef MILLICAST_SDK_IOS
#define MILLICAST_SDK_IOS
#endif  // !MILLICAST_SDK_IOS
#elif defined(TARGET_OS_TV) && TARGET_OS_TV == 1
#ifndef MILLICAST_SDK_TVOS
#define MILLICAST_SDK_TVOS
#endif  // !MILLICAST_SDK_TVOS
#elif (defined(TARGET_OS_OSX) && TARGET_OS_OSX == 1) || \
    (defined(TARGET_OS_MAC) && TARGET_OS_MAC == 1)
#ifndef MILLICAST_SDK_MAC
#define MILLICAST_SDK_MAC
#endif  // !MILLICAST_SDK_MAC
#endif  // iOS, tvOS, or macos
#elif defined(__ANDROID__)
#ifndef MILLICAST_SDK_ANDROID
#define MILLICAST_SDK_ANDROID
#endif  // !MILLICAST_SDK_ANDROID
#elif defined(__linux__)
#ifndef MILLICAST_SDK_LINUX
#define MILLICAST_SDK_LINUX
#endif  // !MILLICAST_SDK_LINUX
#elif defined(_WIN32)
#ifndef MILLICAST_SDK_WIN
#define MILLICAST_SDK_WIN
#endif  // !MILLICAST_SDK_WIN
#endif

#ifdef MILLICAST_API_EXPORT

#if defined MILLICAST_SDK_WIN
#define MILLICAST_API __declspec(dllexport)
#define MILLICAST_TEMPLATE_API
#else  // !Windows
#define MILLICAST_API __attribute__((visibility("default")))
#define MILLICAST_TEMPLATE_API MILLICAST_API
#endif  // !Windows

#else  // !MILLICAST_API_EXPORT

#define MILLICAST_TEMPLATE_API

#ifdef MILLICAST_SDK_WIN
#define MILLICAST_API __declspec(dllimport)
#else
#define MILLICAST_API
#endif

#endif  // !MILLICAST_API_EXPORT

#endif  // EXPORTS_H
