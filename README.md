# connectsdk-react-native

Connect SDK is an open source framework that unifies device discovery and connectivity by providing one set of methods that work across multiple television platforms and protocols.

For more information, visit our [website](http://www.connectsdk.com/).

* [General information about Connect SDK](http://www.connectsdk.com/discover/)
* [Platform documentation & FAQs](http://www.connectsdk.com/docs/cordova/)
* [API documentation](http://www.connectsdk.com/apis/cordova/)

## Dependencies

These steps assume you have a basic working knowledge of development for Android, iOS React. For these steps to work, you will need the following:

- Xcode & Command Line Tools
- Android SDK
If you are only developing for one platform, feel free to ignore the steps & requirements for the irrelevant platform.

## Installation for React Native

#### 1. Install React Native

Follow [these instructions](https://reactnative.dev/docs/environment-setup) to install React Native Elements.

#### 2. Add module to app

    npm install connectsdk-react-native —save-exact

#### 3. Add native code to app
iOS:

    npx pod-install

Android:

    cd android
    git clone https://github.com/ConnectSDK/Connect-SDK-Android-Core

Thats it! Dependencies will be downloaded and set up automatically.

**Dependencies will not be downloaded automatically for versions older than 1.6.0. You'll need to check the README from that branch and follow any manual set up steps.**

## Contact
* Twitter [@ConnectSDK](https://www.twitter.com/ConnectSDK)
* Ask a question with the "tv" tag on [Stack Overflow](http://stackoverflow.com/tags/tv)
* General Inquiries info@connectsdk.com
* Developer Support support@connectsdk.com
* Partnerships partners@connectsdk.com

## License

Copyright (c) 2013-2021 LG Electronics.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

> http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
