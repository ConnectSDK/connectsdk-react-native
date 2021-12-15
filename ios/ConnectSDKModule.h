//
//  ConnectSDKModule.h
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
#ifndef ConnectSDKModule_h
#define ConnectSDKModule_h
#import <ConnectSDK-Lite/ConnectSDK.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTViewManager.h>

@class JSObjectWrapper;

@interface ConnectSDKModule : RCTEventEmitter <RCTBridgeModule>
- (void) startDiscovery:(NSArray*)command successCallback:(RCTResponseSenderBlock)successCallback errorCallback:(RCTResponseSenderBlock)errorCallback;
- (void) stopDiscovery:(NSArray*)command;
- (void) pickDevice:(NSArray*)command successCallback:(RCTResponseSenderBlock)successCallback errorCallback:(RCTResponseSenderBlock)errorCallback;

- (void) sendCommand:(NSArray*)command successCallback:(RCTResponseSenderBlock)successCallback errorCallback:(RCTResponseSenderBlock)errorCallback;
- (void) cancelCommand:(NSArray*)command;

- (void) acquireWrappedObject:(NSArray*)command;
- (void) releaseWrappedObject:(NSArray*)command;

- (void) addObjectWrapper:(JSObjectWrapper*)wrapper;
- (void) removeObjectWrapper:(JSObjectWrapper*)wrapper;
- (id) getObjectWrapper:(NSString*)objectId;
- (void) addSupportedEvent: (NSString*)event;
- (void) removeSupportedEvent: (NSString*)event;
- (void) sendModuleResult:(NSArray*)command deviceId:(NSString*)deviceId;
- (void) sendModuleResult:(NSArray*)command callbackId:(NSString*)callbackId deviceId:(NSString*)deviceId;
@end

#endif /* ConnectSDKModule_h */
