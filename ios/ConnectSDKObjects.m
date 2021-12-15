//
//  ConnectSDKObjects.m
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

#import "ConnectSDKObjects.h"

@implementation JSObjectWrapper

static int nextObjectId = 0;

- (instancetype) initWithModule:(ConnectSDKModule*)module
{
    self = [super init];
    
    if (self) {
        self.module = module;
        self.objectId = [NSString stringWithFormat:@"object_%d", ++nextObjectId];
        self.callbackId = nil;
    }
    
    return self;
}

// send [eventName, data]
- (void) sendEvent:(NSString*)event withObject:obj
{
    if (self.callbackId) {
        NSArray* payload = obj ? @[event, obj] : @[event];
        [self.module sendModuleResult:payload callbackId:_callbackId deviceId:nil];
    }
}

- (void) cleanup
{
}

@end

@implementation WebAppSessionWrapper

- (instancetype) initWithModule:(ConnectSDKModule*)module session:(WebAppSession*)session
{
    self = [super initWithModule:module];
    
    if (self) {
        self.session = session;
    }
    
    return self;
}

- (void) webAppSession:(WebAppSession *)webAppSession didReceiveMessage:(id)message
{
    if (self.callbackId != nil)
        [self sendEvent:@"message" withObject:message];
}

- (void) webAppSessionDidDisconnect:(WebAppSession *)webAppSession
{
    [self sendEvent:@"disconnect" withObject:nil];
    [self.module removeSupportedEvent:self.callbackId];
    self.callbackId = nil;
}

- (void) cleanup
{
    self.session.delegate = nil;
    self.session = nil;
    self.callbackId = nil;

    [super cleanup];
}

@end

@implementation MediaControlWrapper

- (instancetype) initWithModule:(ConnectSDKModule*)module mediaControl:(id<MediaControl>)mediaControl
{
    self = [super initWithModule:module];
    
    if (self) {
        self.mediaControl = mediaControl;
    }

    return self;
}

@end

@implementation PlaylistControlWrapper

- (instancetype)initWithModule:(ConnectSDKModule *)module
               playlistControl:(id <PlayListControl>)playlistControl {
    self = [super initWithModule:module];
    _playlistControl = playlistControl;
    return self;
}

@end
