//
//  ConnectSDKModule.m
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
#import "ConnectSDKObjects.h"

#import "ConnectSDK-Lite/AirPlayService.h"
#import "ConnectSDK-Lite/CapabilityFilter.h"
#import "ConnectSDK-Lite/DeviceServiceDelegate.h"
#pragma mark - Helper types

@interface JSDeviceState : NSObject

@property (nonatomic, strong) id device;
@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, strong) NSString *callbackId;
@property (nonatomic, strong) RCTResponseSenderBlock success;
@property (nonatomic, strong) RCTResponseSenderBlock error;
@property (nonatomic, strong) JSCommandDispatcher* dispatcher;

@end

@implementation JSDeviceState {
}

+ (JSDeviceState *) stateFromDevice:(ConnectableDevice*)device
{
    JSDeviceState *state = [JSDeviceState new];
    state.device = device;
    state.deviceId = [device id];
    state.callbackId = nil;
    state.success = nil;
    state.error = nil;
    
    return state;
}

@end


@interface ConnectSDKModule ()

    /// A @c DeviceServicePairingType value that is passed when displaying a device
    /// picker and then automagically set to a selected device.
@property (nonatomic, strong, nullable) NSNumber /*<DeviceServicePairingType>*/ *automaticPairingTypeNumber;

@end

@implementation ConnectSDKModule {
    DiscoveryManager* _discoveryManager;
    NSMapTable* _deviceStateById; // map device id to device
    NSMapTable* _deviceStateByDevice; // map device to device id
    
    NSMapTable* _objectWrappers;
    
    RCTResponseSenderBlock _discoverySuccessCallback;
    RCTResponseSenderBlock _discoveryErrorCallback;
    RCTResponseSenderBlock _showPickerSuccessCallback;
    RCTResponseSenderBlock _showPickerErrorCallback;
    NSMutableArray *_supportedEvents;
}

RCT_EXPORT_MODULE(ConnectSDK);

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(getName)
{
    return [[UIDevice currentDevice] name];
}
- (UIView *)view
{
    return [[UIView alloc] init];
}

- (instancetype)init
{
    [self moduleInitialize];
    return self;
}

- (void)invalidate
{
    if (_discoverySuccessCallback) {
        _discoverySuccessCallback = 0;
    }
    if (_discoveryErrorCallback) {
        _discoveryErrorCallback = 0;
    }
    [self stopDiscovery:nil];
    [super invalidate];
}

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

#pragma mark - Setup methods

- (void) moduleInitialize
{
    _deviceStateById = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
    _deviceStateByDevice = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
    _objectWrappers = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
    _discoverySuccessCallback = 0;
    _discoveryErrorCallback = 0;
    _showPickerSuccessCallback = 0;
    _showPickerErrorCallback = 0;
    _supportedEvents = [[NSMutableArray alloc] init];
    [_supportedEvents addObjectsFromArray:[NSArray arrayWithObjects:@"devicefound",@"deviceupdated",@"devicelost", nil]];
}

- (void) setupDiscovery: (NSDictionary*)config
{
    if (!_discoveryManager) {
        _discoveryManager = [DiscoveryManager sharedManager];
    }
    
    if (config) {
        NSString* pairingLevel = config[@"pairingLevel"];
        
        if (pairingLevel != nil) {
            if ([pairingLevel isEqualToString:@""] || [pairingLevel isEqualToString:@"off"]) {
                [_discoveryManager setPairingLevel:DeviceServicePairingLevelOff];
            } else if ([pairingLevel isEqualToString:@"on"]) {
                [_discoveryManager setPairingLevel:DeviceServicePairingLevelOn];
            }
        }
        
        NSString* airPlayServiceMode = config[@"airPlayServiceMode"];
        if (airPlayServiceMode) {
            if ([airPlayServiceMode isEqualToString:@"webapp"]) {
                [AirPlayService setAirPlayServiceMode:AirPlayServiceModeWebApp];
            } else if ([airPlayServiceMode isEqualToString:@"media"]) {
                [AirPlayService setAirPlayServiceMode:AirPlayServiceModeMedia];
            }
        }
        
        NSArray* filterObjs = config[@"capabilityFilters"];
        if (filterObjs) {
            NSMutableArray* capFilters = [NSMutableArray array];
            
            for (NSArray* filterArray in filterObjs) {
                CapabilityFilter* capFilter = [CapabilityFilter filterWithCapabilities:filterArray];
                [capFilters addObject:capFilter];
            }
            
            [_discoveryManager setCapabilityFilters:capFilters];
        }
    }
}

#pragma mark - Cordova command handlers
- (void) startDiscovery: (NSArray*)command
               successCallback:(RCTResponseSenderBlock)successCallback
               errorCallback:(RCTResponseSenderBlock)errorCallback
{
    NSLog(@"starting discovery");
    
    NSDictionary* config = [command objectAtIndex:0];
    
    [self setupDiscovery:config];
    
    if (_discoverySuccessCallback) {
        _discoverySuccessCallback = 0;
    }
    
    if (_discoveryErrorCallback) {
        _discoveryErrorCallback = 0;
    }

    _discoverySuccessCallback = successCallback;
    _discoveryErrorCallback = errorCallback;
    _discoveryManager.delegate = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_discoveryManager registerDefaultServices];
        [self->_discoveryManager startDiscovery];
    });
}

- (void) stopDiscovery:(NSArray*)command
{
    if (_discoveryManager) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_discoveryManager stopDiscovery];
        });
    }
}

- (void) setDiscoveryConfig:(NSArray*)command
{
    NSDictionary* config = [command objectAtIndex:0];
    [self setupDiscovery:config];
}

- (void) pickDevice:(NSArray*)command
           successCallback:(RCTResponseSenderBlock)successCallback
           errorCallback:(RCTResponseSenderBlock)errorCallback
{
    [self setupDiscovery:nil];
    
    _showPickerSuccessCallback = successCallback;
    _showPickerErrorCallback = errorCallback;
    
    BOOL popup = NO;
    NSDictionary* options = [command objectAtIndex:0];
    
    if (options.count > 0) {
        NSString* format = options[@"format"];
        
        if (format && [format isEqualToString:@"full"]) {
            popup = NO;
        } else if (format && [format isEqualToString:@"popup"]) {
            popup = YES;
        }
        
        NSString *pairingTypeString = options[@"pairingType"];
        self.automaticPairingTypeNumber = pairingTypeString ?
        [self parsePairingType:pairingTypeString] :
        nil;
    }
    
    DevicePicker *picker = [_discoveryManager devicePicker];
    picker.delegate = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *view = [[[RCTSharedApplication() delegate] window] rootViewController];
        
        if (popup) {
            [picker showActionSheet:view];
        } else {
            [picker showPicker:view];
        }
    });
}

- (NSArray<NSString *> *)supportedEvents
{
    return _supportedEvents;
}

- (void) addSupportedEvent: (NSString*)event
{
    [_supportedEvents addObject:event];
}

- (void) removeSupportedEvent: (NSString*)event
{
    [_supportedEvents removeObject:event];
}

- (void) sendCommand:(NSArray*)command
             successCallback:(RCTResponseSenderBlock)successCallback
             errorCallback:(RCTResponseSenderBlock)errorCallback
{
    NSString* deviceId = (NSString *)[command objectAtIndex:0];
    
    JSDeviceState* deviceState = [self getDeviceStateById:deviceId];
    [self setCallback:successCallback errorCallback:errorCallback forDeviceState:deviceState];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!deviceState.dispatcher) {
            [deviceState setDispatcher:[JSCommandDispatcher dispatcherWithModule:self device:deviceState.device]];
        }
        
        [deviceState.dispatcher dispatch:command];
    });
}

- (void) cancelCommand:(NSDictionary*)command
{
    NSString* deviceId = (NSString *)[command objectForKey:@"deviceId"];
    NSString* commandId = (NSString *)[command objectForKey:@"commandId"];
    
    JSDeviceState* deviceState = [self getDeviceStateById:deviceId];
    
    @synchronized(deviceState) {
        if (deviceState.dispatcher) {
            [deviceState.dispatcher cancelCommand:commandId];
        }
    }
}

- (void) setCallback:(RCTResponseSenderBlock)successCallback errorCallback:(RCTResponseSenderBlock)errorCallback forDeviceState:(JSDeviceState*)deviceState
{
    [deviceState setSuccess:successCallback];
    [deviceState setError:errorCallback];
}
    // Routes device events to this callback without connecting
- (void) setDeviceListener:(NSArray*)command successCallback:(RCTResponseSenderBlock)successCallback errorCallback:(RCTResponseSenderBlock)errorCallback
{
    NSString* deviceId = (NSString *)[command objectAtIndex:0];
    
    NSLog(@"setting listener for device %@", deviceId);
    
    JSDeviceState* deviceState = [self getDeviceStateById:deviceId];
    
    if (deviceState) {
        [self setCallback:successCallback errorCallback:errorCallback forDeviceState:deviceState];
        
        ConnectableDevice* device = [deviceState device];
        device.delegate = self;
    }
}

- (void) sendModuleResult:(NSArray*)command deviceId:(NSString*)deviceId
{
    JSDeviceState* deviceState = [self getDeviceStateById:deviceId];
    if (deviceState) {
        NSArray* array = @[command];
        NSString* temp = [command objectAtIndex:0];
        @try {
            if ([temp isEqualToString :@"success"]){
                if (deviceState.success) {
                    deviceState.success(array);
                    deviceState.success = 0;
                }
            }
            else if (deviceState.error) {
                deviceState.error(array);
                deviceState.error = 0;
            }
        } @catch (NSException *ex) {
            NSLog(@"exception while callback %@", ex);
        }
    }
}

- (void) sendModuleResult:(NSArray*)command callbackId:(NSString*)callbackId deviceId:(NSString*)deviceId
{
    @try {
        NSArray* array = @[command];
        if (deviceId != nil){
            JSDeviceState* deviceState = [self getDeviceStateById:deviceId];
            if (deviceState.success) {
                deviceState.success(array);
                deviceState.success = 0;
            }
        }
        [self sendEventWithName:callbackId body:array];
    } @catch (NSException *ex) {
        NSLog(@"exception while sendModuleResult %@", ex);
    }
}

- (void) connectDevice:(NSArray*)command
       successCallback:(RCTResponseSenderBlock)successCallback
         errorCallback:(RCTResponseSenderBlock)errorCallback
{
    NSString* deviceId = (NSString *)[command objectAtIndex:0];
    
    NSLog(@"connecting to device %@", deviceId);
    
    JSDeviceState* deviceState = [self getDeviceStateById:deviceId];
    
    if (deviceState) {
        [self setCallback:successCallback errorCallback:errorCallback forDeviceState:deviceState];
        
        ConnectableDevice* device = [deviceState device];
        device.delegate = self;
        [device connect];
    }
}

- (void) disconnectDevice:(NSArray*)command
{
    NSString* deviceId = (NSString *)[command objectAtIndex:0];
    
    NSLog(@"disconnecting from device %@", deviceId);
    
    ConnectableDevice* device = [self getDeviceById:deviceId];
    
    if (device) {
        [device disconnect];
    }
}

- (void) setPairingType:(NSArray*)command
{
    NSString* deviceId = (NSString *)[command objectAtIndex:0];
    ConnectableDevice* device = [self getDeviceById:deviceId];
    
    NSString *pairingTypeString = [command objectAtIndex:1];
    NSNumber *pairingTypeNumber = [self parsePairingType:pairingTypeString];
    
    if (device && pairingTypeNumber) {
        [self setPairingTypeNumber:pairingTypeNumber toDevice:device];
    }
}

- (void) acquireWrappedObject:(NSArray*)command
{
    NSString* objectId = (NSString *)[command objectAtIndex:0];
    
    JSObjectWrapper* wrapper = [self getObjectWrapper:objectId];
    if (wrapper) {
//        wrapper.callbackId = command.callbackId;
    }
}

- (void) releaseWrappedObject:(NSArray*)command
{
    NSString* objectId = (NSString *)[command objectAtIndex:0];
    
    JSObjectWrapper* wrapper = [self getObjectWrapper:objectId];
    if (wrapper) {
        [self removeObjectWrapper:wrapper];
    }
}

#pragma mark - Helper methods

- (void) sendDiscoveryUpdate:(NSString*)event withDevice:(ConnectableDevice*)device
{
    [self sendDiscoveryUpdate:event withData:[NSDictionary dictionaryWithObject:[self deviceAsDict:device] forKey:@"device"] done:NO];
}

- (void) sendDiscoveryUpdate:(NSString*)event withData:(NSDictionary*)dict done:(BOOL)done
{
    if (event) {
        @try {
            [self sendEventWithName:event body:dict];
        } @catch (NSException *ex) {
            NSLog(@"exception while sendDeviceUpdate %@", ex);
        }
    }
}

- (void) sendDeviceUpdate:(NSString*)event device:(ConnectableDevice*)device withData:(NSDictionary*)dict
{
    JSDeviceState* deviceState = [self getOrCreateDeviceState:device];
    
    if (!device || ![deviceState success]) {
        return;
    }
    
    NSArray* array = dict ? @[event, dict] : @[event];
    @try {
        [self sendEventWithName:@"deviceupdated" body:array];
    } @catch (NSException *ex) {
        NSLog(@"exception while sendDeviceUpdate %@", ex);
    }
}

- (void) sendServiceUpdate:(NSString*)event device:(ConnectableDevice*)device service:(DeviceService*)service withData:(NSDictionary*)dict
{
    JSDeviceState* deviceState = [self getOrCreateDeviceState:device];
    
    if (!device || ![deviceState success]) {
        return;
    }
    
    NSString* serviceName = @"";
    
    NSArray* array = dict ? @[event, serviceName, dict] : @[event, serviceName];
    @try {
        [self sendEventWithName:@"deviceupdated" body:array];
    } @catch (NSException *ex) {
        NSLog(@"exception while sendDeviceUpdate %@", ex);
    }
}

static id orNull (id obj)
{
    return obj ? obj : [NSNull null];
}

- (JSDeviceState*) getOrCreateDeviceState:(ConnectableDevice*)device
{
    @synchronized(self) {
        JSDeviceState *deviceState = (JSDeviceState*) [_deviceStateByDevice objectForKey:device];
        if (deviceState == nil) {
            deviceState = [JSDeviceState stateFromDevice:device];
            [_deviceStateByDevice setObject:deviceState forKey:device];
            [_deviceStateById setObject:deviceState forKey:[deviceState deviceId]];
        }
        return deviceState;
    }
}

- (JSDeviceState*) getDeviceStateById:(NSString*)deviceId
{
    @synchronized(self) {
        return [_deviceStateById objectForKey:deviceId];
    }
}

- (ConnectableDevice*) getDeviceById:(NSString*)deviceId
{
    return [[self getDeviceStateById:deviceId] device];
}

- (NSDictionary*) deviceAsDict:(ConnectableDevice*)device
{
    NSMutableArray* services = [NSMutableArray array];
    
    for (DeviceService* service in device.services) {
        NSDictionary* serviceDict = @{
            @"name": service.serviceName
        };
        
        [services addObject:serviceDict];
    }
    
    return @{
        @"deviceId": [[self getOrCreateDeviceState:device] deviceId],
        @"ipAddress": orNull(device.address),
        @"friendlyName": orNull(device.friendlyName),
        @"modelName": orNull(device.modelName),
        @"modelNumber": orNull(device.modelNumber),
        @"capabilities": [device capabilities],
        @"services": services
    };
}

- (NSNumber *)parsePairingType:(NSString *)typeString {
        // the PairingType values from `ConnectSDK.js`
    static NSDictionary *mapping;
    static dispatch_once_t mappingOnce;
    dispatch_once(&mappingOnce, ^{
        mapping = @{
            @"NONE": @(DeviceServicePairingTypeNone),
            @"FIRST_SCREEN": @(DeviceServicePairingTypeFirstScreen),
            @"PIN": @(DeviceServicePairingTypePinCode),
            @"MIXED": @(DeviceServicePairingTypeMixed),
            @"AIRPLAY_MIRRORING": @(DeviceServicePairingTypeAirPlayMirroring),
        };
    });
    
    NSNumber *typeNumber = mapping[typeString];
    NSAssert(typeNumber, @"Unknown pairing type string: %@", typeString);
    return typeNumber;
}

- (void)setPairingTypeNumber:(NSNumber *)pairingTypeNumber
                    toDevice:(ConnectableDevice *)device {
    DeviceServicePairingType type = (DeviceServicePairingType)
    [pairingTypeNumber unsignedIntegerValue];
    [device setPairingType:type];
}

#pragma mark - DiscoveryManager delegates

- (void) discoveryManager:(DiscoveryManager *)manager didFindDevice:(ConnectableDevice *)device
{
    [self getOrCreateDeviceState:device];
    
    [self sendDiscoveryUpdate:@"devicefound" withDevice:device];
}

- (void) discoveryManager:(DiscoveryManager *)manager didLoseDevice:(ConnectableDevice *)device
{
    JSDeviceState *deviceState = [self getOrCreateDeviceState:device];
    NSString* deviceId = [deviceState deviceId];
    
    [self sendDiscoveryUpdate:@"devicelost" withDevice:device];
    
        // Remove from maps; don't remove if device has event listener
    if (![deviceState success]) {
        @synchronized(self) {
            [_deviceStateById removeObjectForKey:deviceId];
            [_deviceStateByDevice removeObjectForKey:device];
        }
    }
}

- (void) discoveryManager:(DiscoveryManager *)manager didUpdateDevice:(ConnectableDevice *)device
{
    [self sendDiscoveryUpdate:@"deviceupdated" withDevice:device];
}

- (void) discoveryManager:(DiscoveryManager *)manager didFailWithError:(NSError*)error
{
    if (_discoveryErrorCallback) {
        NSString *errorString = error ? [error localizedDescription] : @"unknown error";
        _discoveryErrorCallback(@[@"error", errorString]);
        _discoveryErrorCallback = 0;
    }
}

#pragma mark - DevicePicker delegates

- (void) devicePicker:(DevicePicker *)picker didSelectDevice:(ConnectableDevice *)device;
{
    if (_showPickerSuccessCallback) {
        if (self.automaticPairingTypeNumber) {
            [self setPairingTypeNumber:self.automaticPairingTypeNumber
                              toDevice:device];
        }
        
        device.delegate = self;
        [device connect];
        NSDictionary* dict = [self deviceAsDict:device];
        _showPickerSuccessCallback(@[dict]);
        _showPickerSuccessCallback = 0;
    }
}

- (void) devicePicker:(DevicePicker *)picker didCancelWithError:(NSError*)error
{
    if (_showPickerErrorCallback) {
        NSString* errorString = [error localizedDescription];
        if (errorString != nil)
            _showPickerErrorCallback(@[@"error", errorString]);
        _showPickerErrorCallback = 0;
    }
}

# pragma mark - ConnectableDevice delegates

- (void) connectableDeviceReady:(ConnectableDevice *)device
{
    [self sendDeviceUpdate:@"ready" device:device withData:nil];
}

- (void) connectableDeviceDisconnected:(ConnectableDevice *)device withError:(NSError *)error;
{
    [self sendDeviceUpdate:@"disconnect" device:device withData:nil];
}

- (void) connectableDevice:(ConnectableDevice *)device capabilitiesAdded:(NSArray *)added removed:(NSArray *)removed
{
    NSDictionary* data = @{@"added": added, @"removed": removed, @"reset": [NSNumber numberWithBool:FALSE]};
    
    [self sendDeviceUpdate:@"capabilitieschanged" device:device withData:data];
}

- (void) connectableDeviceConnectionSuccess:(ConnectableDevice*)device forService:(DeviceService *)service
{
    [self sendServiceUpdate:@"serviceconnect" device:device service:service withData:nil];
}

- (void) connectableDevice:(ConnectableDevice*)device service:(DeviceService *)service disconnectedWithError:(NSError*)error
{
    NSDictionary* errorObj = error ? @{@"message": [error localizedDescription]} : nil;
    
    [self sendServiceUpdate:@"servicedisconnect" device:device service:service withData:errorObj];
}

- (void) connectableDeviceConnectionRequired:(ConnectableDevice *)device forService:(DeviceService *)service;
{
    [self sendServiceUpdate:@"serviceconnectionrequired" device:device service:service withData:nil];
}

- (void) connectableDevice:(ConnectableDevice *)device service:(DeviceService *)service didFailConnectWithError:(NSError*)error
{
    NSDictionary* errorObj = error ? @{@"message": [error localizedDescription]} : nil;
    
    [self sendServiceUpdate:@"serviceconnectionerror" device:device service:service withData:errorObj];
}

- (void) connectableDevice:(ConnectableDevice *)device service:(DeviceService *)service pairingRequiredOfType:(int)pairingType withData:(id)pairingData
{
    NSDictionary* pairingInfo = nil;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Mirroring Required" message:@"Enable AirPlay mirroring to connect to this device" preferredStyle:UIAlertControllerStyleAlert];
    id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
        if (device) { [device disconnect]; }
    }];
        
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    switch (pairingType) {
        case DeviceServicePairingTypeFirstScreen:
            pairingInfo = @{@"pairingType": @"firstScreen"};
            break;
        case DeviceServicePairingTypePinCode:
            pairingInfo = @{@"pairingType": @"pinCode"};
            break;
        case DeviceServicePairingTypeNone:
            pairingInfo = @{@"pairingType": @"none"};
            break;
        case DeviceServicePairingTypeMixed:
            pairingInfo = @{@"pairingType": @"mixed"};
            break;
        case DeviceServicePairingTypeAirPlayMirroring:
            [rootViewController presentViewController:alertController animated:YES completion:nil];
            pairingInfo = @{@"pairingType": @"airPlayMirroring"};
            break;
    }
    
    [self sendServiceUpdate:@"servicepairingrequired" device:device service:service withData:pairingInfo];
}

- (void) connectableDevicePairingSuccess:(ConnectableDevice*)device service:(DeviceService *)service
{
    [self sendDeviceUpdate:@"servicepairingsuccess" device:device withData:nil];
}

- (void) connectableDevice:(ConnectableDevice *)device service:(DeviceService *)service pairingFailedWithError:(NSError*)error
{
    NSDictionary* errorObj = @{@"message": [error localizedDescription]};
    
    [self sendDeviceUpdate:@"servicepairingerror" device:device withData:errorObj];
}

#pragma mark - Internal methods

- (void) addObjectWrapper:(JSObjectWrapper*)wrapper
{
    [_objectWrappers setObject:wrapper forKey:wrapper.objectId];
}

- (void) removeObjectWrapper:(JSObjectWrapper*)wrapper
{
    [_objectWrappers removeObjectForKey:wrapper.objectId];
    [wrapper cleanup];
}

- (JSObjectWrapper*) getObjectWrapper:(NSString*)objectId
{
    return [_objectWrappers objectForKey:objectId];
}

RCT_EXPORT_METHOD(execute: (NSString*) action
                  arrArgs: (NSString*) arrArgs
                  successCallback: (RCTResponseSenderBlock) successCallback
                  errorCallback: (RCTResponseSenderBlock) errorCallback)
{
    @try {
        NSData *data = [arrArgs dataUsingEncoding:NSUTF8StringEncoding];
        NSError *e;
        NSArray *command = [NSJSONSerialization JSONObjectWithData:data options:nil error:&e];
        if([@"sendCommand" isEqualToString:action]) {
            BOOL isSubscribe = [[command objectAtIndex:5] boolValue];
            if (isSubscribe) {
                [self addSupportedEvent:[command objectAtIndex:1]];
            }

            [self sendCommand:command successCallback:successCallback errorCallback:errorCallback];
        } else if ([@"cancelCommand" isEqualToString:action]) {
            NSString* deviceId = (NSString *)[command objectAtIndex:0];
            NSString* commandId = [command objectAtIndex:1];
            
            JSDeviceState* deviceState = [self getDeviceStateById:deviceId];
            
            @synchronized(deviceState) {
                if (!deviceState.dispatcher) {
                    [deviceState setDispatcher:[JSCommandDispatcher dispatcherWithModule:self device:deviceState.device]];
                }
                
                [deviceState.dispatcher cancelCommand:commandId];
            }
        } else if ([@"startDiscovery" isEqualToString:action]) {
            [self startDiscovery: command successCallback:successCallback errorCallback:errorCallback];
        } else if ([@"stopDiscovery" isEqualToString:action]) {
            [self stopDiscovery:command];
        } else if ([@"setDiscoveryConfig" isEqualToString:action]) {
            [self setDiscoveryConfig:command];
        } else if ([@"pickDevice" isEqualToString:action]) {
            [self pickDevice: command successCallback:successCallback errorCallback:errorCallback];
        } else if ([@"setDeviceListener" isEqualToString:action]) {
            [self setDeviceListener:command successCallback:successCallback errorCallback:errorCallback];
        } else if ([@"connectDevice" isEqualToString:action]) {
            [self connectDevice: command successCallback:successCallback errorCallback:errorCallback];
        } else if ([@"setPairingType" isEqualToString:action]) {
            [self setPairingType: command];
        } else if ([@"disconnectDevice" isEqualToString:action]) {
            [self disconnectDevice: command];
        } else if ([@"acquireWrappedObject" isEqualToString:action]) {
            [self acquireWrappedObject: command];
        } else if ([@"releaseWrappedObject" isEqualToString:action]) {
            [self releaseWrappedObject: command];
        }else {
            NSLog(@"no handler for exec action %@", action);
        }
    } @catch (NSException *ex) {
        NSLog(@"exception while handling %@ %@", action, ex);

        NSArray* result = @[@"error", ex];
        errorCallback(result);
    }
}
@end

