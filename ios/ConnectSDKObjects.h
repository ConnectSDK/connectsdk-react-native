//
//  ConnectSDKObjects.h
//  Connect SDK
//
//  Copyright (c) 2021 LG Electronics.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ConnectSDKModule.h"
#import "ConnectSDKDispatcher.h"
#import <ConnectSDK-Lite/ConnectSDK.h>

@interface JSObjectWrapper : NSObject
@property (nonatomic, strong) ConnectSDKModule* module;
@property (nonatomic, strong) NSString* objectId;
@property (nonatomic, strong) NSString* callbackId;

- (void) cleanup;
@end

@interface ConnectableDeviceWrapper : JSObjectWrapper
@property (nonatomic, strong) id device;
@property (nonatomic, strong) JSCommandDispatcher* dispatcher;
@end

@interface WebAppSessionWrapper : JSObjectWrapper<WebAppSessionDelegate>
@property (nonatomic, strong) WebAppSession* session;
- (instancetype) initWithModule:(ConnectSDKModule*)module session:(WebAppSession*)session;
- (void) webAppSession:(WebAppSession *)webAppSession didReceiveMessage:(id)message;
- (void) webAppSessionDidDisconnect:(WebAppSession *)webAppSession;
@end

@interface MediaControlWrapper : JSObjectWrapper
@property (nonatomic, strong) id<MediaControl> mediaControl;

- (instancetype) initWithModule:(ConnectSDKModule*)module mediaControl:(id<MediaControl>)mediaControl;
@end

@interface PlaylistControlWrapper : JSObjectWrapper

@property (nonatomic, strong) id<PlayListControl> playlistControl;

- (instancetype)initWithModule:(ConnectSDKModule*)module playlistControl:(id<PlayListControl>)playlistControl;

@end

@interface PowerControlWrapper : JSObjectWrapper

@property (nonatomic, strong) id<PowerControl> powerControl;

- (instancetype)initWithModule:(ConnectSDKModule*)module powerControl:(id<PowerControl>)powerControl;

@end
