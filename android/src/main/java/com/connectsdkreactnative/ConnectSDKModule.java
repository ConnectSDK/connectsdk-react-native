package com.connectsdkreactnative;

// Import android modules

import static com.facebook.react.bridge.UiThreadUtil.runOnUiThread;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.connectsdk.core.JSONSerializable;
import com.connectsdk.device.ConnectableDevice;
import com.connectsdk.device.SimpleDevicePicker;
import com.connectsdk.device.SimpleDevicePickerListener;
import com.connectsdk.discovery.DiscoveryManager;
import com.connectsdk.service.DeviceService;
import com.connectsdk.service.command.ServiceCommandError;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Objects;

// Import React Native dependencies

public class ConnectSDKModule extends ReactContextBaseJavaModule implements LifecycleEventListener {
    private static final String LOG_TAG = "ConnectSDKModule";
    private final ReactApplicationContext mCtx;
    @ReactMethod
    public ConnectSDKModule(ReactApplicationContext reactContext) {
        super(reactContext);
        reactContext.addLifecycleEventListener(this);
        this.mCtx = reactContext;
        initDiscoveryManagerWrapper();
    }

    public DiscoveryManagerWrapper getDiscoveryManagerWrapper () {
        return discoveryManagerWrapper;
    }

    @NonNull
    @Override
    public String getName() {
        return "ConnectSDK";
    }
    public static final String JS_PAIRING_TYPE_FIRST_SCREEN = "FIRST_SCREEN";
    public static final String JS_PAIRING_TYPE_PIN = "PIN";
    public static final String JS_PAIRING_TYPE_MIXED = "MIXED";

    DiscoveryManager discoveryManager;
    DiscoveryManagerWrapper discoveryManagerWrapper;
    LinkedHashMap<String, ConnectableDeviceWrapper> deviceWrapperById = new LinkedHashMap<>();
    LinkedHashMap<ConnectableDevice, ConnectableDeviceWrapper> deviceWrapperByDevice = new LinkedHashMap<>();

    HashMap<String, JSObjectWrapper> objectWrappers = new HashMap<>();
    private SimpleDevicePicker picker;

    @Override
    public void onHostResume() {
    }

    @Override
    public void onHostPause() {

    }

    @Override
    public void onHostDestroy() {
        if (picker != null) {
            picker.hidePairingDialog();
            picker.hidePicker();
            picker = null;
        }
    }

    @ReactMethod
    public void addListener(String eventName) {

    }

    @ReactMethod
    public void removeListeners(Integer count) {

    }

    public ReactApplicationContext getContext() {
        return mCtx;
    }

    static class NoSuchDeviceException extends Exception {
        private static final long serialVersionUID = 1L;
    }

    synchronized ConnectableDeviceWrapper getDeviceWrapper(String deviceId) throws NoSuchDeviceException {
        ConnectableDeviceWrapper wrapper = deviceWrapperById.get(deviceId);

        if (wrapper == null) {
            throw new NoSuchDeviceException();
        }

        return wrapper;
    }

    synchronized ConnectableDeviceWrapper getDeviceWrapper(ConnectableDevice device) {
        ConnectableDeviceWrapper wrapper = deviceWrapperByDevice.get(device);

        if (wrapper == null) {
            wrapper = new ConnectableDeviceWrapper(this, device);
            deviceWrapperByDevice.put(device, wrapper);
            deviceWrapperById.put(wrapper.deviceId, wrapper);
        }

        return wrapper;
    }

    synchronized void removeDeviceWrapper(ConnectableDevice device) {
        ConnectableDeviceWrapper wrapper = deviceWrapperByDevice.get(device);

        if (wrapper != null) {
            deviceWrapperByDevice.remove(device);
            deviceWrapperById.remove(wrapper.deviceId);
        }
    }

    @ReactMethod
    public boolean execute(String action, String arrArgs, Callback successCallback, Callback errorCallback) throws JSONException {
        try {
            JSONArray args = new JSONArray(arrArgs);
            Log.w(LOG_TAG, "execute" + arrArgs);

            if ("sendCommand".equals(action)) {
                ConnectableDeviceWrapper deviceWrapper = getDeviceWrapper(args.getString(0));

                String commandId = args.getString(1);
                String ifaceName = args.getString(2);
                String methodName = args.getString(3);
                JSONObject methodArgs = args.getJSONObject(4);
                boolean subscribe = args.getBoolean(5);
                deviceWrapper.sendCommand(commandId, ifaceName, methodName, methodArgs, subscribe, successCallback, errorCallback);
                return true;
            } else if ("cancelCommand".equals(action)) {
                ConnectableDeviceWrapper deviceWrapper = getDeviceWrapper(args.getString(0));
                String commandId = args.getString(1);

                deviceWrapper.cancelCommand(commandId);
                success(successCallback);

                return true;
            } else if ("startDiscovery".equals(action)) {
                startDiscovery(arrArgs, successCallback);
                return true;
            } else if ("stopDiscovery".equals(action)) {
                stopDiscovery(successCallback);
                return true;
            } else if ("setDiscoveryConfig".equals(action)) {
                setDiscoveryConfig(args, successCallback);
                return true;
            } else if ("pickDevice".equals(action)) {
                pickDevice(args, successCallback);
                return true;
            } else if ("setDeviceListener".equals(action)) {
                ConnectableDeviceWrapper deviceWrapper = getDeviceWrapper(args.getString(0));
                deviceWrapper.setCallbackContext(successCallback, errorCallback);
                return true;
            } else if ("connectDevice".equals(action)) {
                ConnectableDeviceWrapper deviceWrapper = getDeviceWrapper(args.getString(0));
                deviceWrapper.setCallbackContext(successCallback, errorCallback);
                deviceWrapper.connect();
                return true;
            } else if ("setPairingType".equals(action)) {
                ConnectableDeviceWrapper deviceWrapper = getDeviceWrapper(args.getString(0));
                deviceWrapper.setCallbackContext(successCallback, errorCallback);
                deviceWrapper.setPairingType(getPairingTypeFromString(args.getString(1)));
                return true;
            } else if ("disconnectDevice".equals(action)) {
                ConnectableDeviceWrapper deviceWrapper = getDeviceWrapper(args.getString(0));
                deviceWrapper.disconnect();
                return true;
            } else if ("acquireWrappedObject".equals(action)) {
                String objectId = args.getString(0);
                JSObjectWrapper wrapper = objectWrappers.get(objectId);

                return true;
            } else if ("releaseWrappedObject".equals(action)) {
                String objectId = args.getString(0);
                JSObjectWrapper wrapper = objectWrappers.get(objectId);

                if (wrapper != null) {
                    removeObjectWrapper(wrapper);
                }

                return true;
            }
        } catch (NoSuchDeviceException e) {
            error(errorCallback, "no such device");
            return true;
        } catch (JSONException e) {
            Log.d(LOG_TAG, "exception while handling " + action, e);
            error(errorCallback, e.toString());
            return true;
        }

        Log.w(LOG_TAG, "no handler for exec action " + action);
        return false;
    }

    void initDiscoveryManagerWrapper() {
        if (discoveryManagerWrapper == null) {
            DiscoveryManager.init(mCtx.getApplicationContext());
            discoveryManager = DiscoveryManager.getInstance();
            discoveryManager.registerDefaultDeviceTypes();
            discoveryManagerWrapper = new DiscoveryManagerWrapper(this, discoveryManager);
        }
    }

    @ReactMethod
    void startDiscovery(String mapArgs, final Callback Callback) throws JSONException {
        JSONArray args = new JSONArray(mapArgs);
        initDiscoveryManagerWrapper();

        if (mapArgs != null && args.length() > 0) {
            for (int i=0; i< args.length(); i++) {
                JSONObject arg = args.getJSONObject(i);
                discoveryManagerWrapper.configure(arg);
            }
        }

        discoveryManagerWrapper.setCallbackContext(Callback);
        discoveryManagerWrapper.start();
    }

    void stopDiscovery(final Callback Callback) throws JSONException {
        if (discoveryManagerWrapper != null) {
            discoveryManagerWrapper.stop();
        }

        success(Callback);
    }

    void setDiscoveryConfig(JSONArray args, final Callback Callback) throws JSONException {
        initDiscoveryManagerWrapper();
        discoveryManagerWrapper.configure(args.getJSONObject(0));

        success(Callback);
    }

    void pickDevice(JSONArray args, final Callback Callback) throws JSONException {
        JSONObject options = args.optJSONObject(0);
        String pairingTypeString = null;
        if (options != null) {
            pairingTypeString = options.optString("pairingType");
        }

        if (discoveryManager != null) {
            final DeviceService.PairingType pairingType = getPairingTypeFromString(pairingTypeString);

            runOnUiThread(() -> {
                if (picker == null) {
                    picker = new SimpleDevicePicker(getCurrentActivity());
                }

                picker.setPairingType(pairingType);
                picker.setListener(new SimpleDevicePickerListener() {
                    @Override
                    public void onPrepareDevice(ConnectableDevice device) {
                    }

                    @Override
                    public void onPickDevice(ConnectableDevice device) {
                        ConnectableDeviceWrapper wrapper = getDeviceWrapper(device);
                        sendEvent(Callback, "device", wrapper.toJSONObject());
                    }

                    @Override
                    public void onPickDeviceFailed(boolean canceled) {
                    }
                });
                picker.showPicker();
            });
        } else {
            error(Callback, "discovery not started");
        }
    }

    public static WritableArray convertJsonToArray(JSONArray jsonArray) throws JSONException {
        WritableArray array = Arguments.createArray();

        for (int i = 0; i < jsonArray.length(); i++) {
            Object value = jsonArray.get(i);
            if (value instanceof JSONObject) {
                array.pushMap(convertJsonToMap((JSONObject) value));
            } else if (value instanceof  JSONArray) {
                array.pushArray(convertJsonToArray((JSONArray) value));
            } else if (value instanceof  Boolean) {
                array.pushBoolean((Boolean) value);
            } else if (value instanceof  Integer) {
                array.pushInt((Integer) value);
            } else if (value instanceof  Double) {
                array.pushDouble((Double) value);
            } else if (value instanceof String)  {
                array.pushString((String) value);
            }
        }
        return array;
    }

    public static WritableMap convertJsonToMap(JSONObject jsonObject) throws JSONException {
        WritableMap map = new WritableNativeMap();

        Iterator<String> iterator = jsonObject.keys();
        while (iterator.hasNext()) {
            String key = iterator.next();
            Object value = jsonObject.get(key);
            if (value instanceof JSONObject) {
                map.putMap(key, convertJsonToMap((JSONObject) value));
            } else if (value instanceof  JSONArray) {
                map.putArray(key, convertJsonToArray((JSONArray) value));
            } else if (value instanceof  Boolean) {
                map.putBoolean(key, (Boolean) value);
            } else if (value instanceof  Integer) {
                map.putInt(key, (Integer) value);
            } else if (value instanceof  Double) {
                map.putDouble(key, (Double) value);
            } else if (value instanceof String)  {
                map.putString(key, (String) value);
            } else {
                map.putString(key, value.toString());
            }
        }
        return map;
    }

    @Nullable
    public static JSONObject convertMapToJson(ReadableMap readableMap) {
        JSONObject jsonObject = new JSONObject();
        if (readableMap == null) {
            return null;
        }
        ReadableMapKeySetIterator iterator = readableMap.keySetIterator();
        if (!iterator.hasNextKey()) {
            return null;
        }
        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            ReadableType readableType = readableMap.getType(key);
            try {
                switch (readableType) {
                    case Null:
                        jsonObject.put(key, null);
                        break;
                    case Boolean:
                        jsonObject.put(key, readableMap.getBoolean(key));
                        break;
                    case Number:
                        // Can be int or double.
                        jsonObject.put(key, readableMap.getInt(key));
                        break;
                    case String:
                        jsonObject.put(key, readableMap.getString(key));
                        break;
                    case Map:
                        jsonObject.put(key, convertMapToJson(readableMap.getMap(key)));
                        break;
                    case Array:
                        jsonObject.put(key, convertArrayToJson(Objects.requireNonNull(readableMap.getArray(key))));
                    default:
                        // Do nothing and fail silently
                }
            } catch (JSONException ex) {
                ex.printStackTrace();
            }
        }
        return jsonObject;
    }

    @Nullable
    public static JSONArray convertMapToArray(ReadableMap readableMap) {
        JSONArray jsonObject = new JSONArray();
        if (readableMap == null) {
            return null;
        }
        ReadableMapKeySetIterator iterator = readableMap.keySetIterator();
        if (!iterator.hasNextKey()) {
            return null;
        }
        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            ReadableType readableType = readableMap.getType(key);
            try {
                switch (readableType) {
                    case Null:
                        jsonObject.put(null);
                        break;
                    case Boolean:
                        jsonObject.put(readableMap.getBoolean(key));
                        break;
                    case Number:
                        // Can be int or double.
                        jsonObject.put(readableMap.getInt(key));
                        break;
                    case String:
                        jsonObject.put(readableMap.getString(key));
                        break;
                    case Map:
                        jsonObject.put(convertMapToJson(readableMap.getMap(key)));
                        break;
                    case Array:
                        jsonObject.put(convertArrayToJson(Objects.requireNonNull(readableMap.getArray(key))));
                    default:
                        // Do nothing and fail silently
                }
            } catch (JSONException ex) {
                ex.printStackTrace();
            }
        }
        return jsonObject;
    }

    public static JSONArray convertArrayToJson(ReadableArray readableArray) throws JSONException {
        JSONArray array = new JSONArray();
        for (int i = 0; i < readableArray.size(); i++) {
            switch (readableArray.getType(i)) {
                case Null:
                    break;
                case Boolean:
                    array.put(readableArray.getBoolean(i));
                    break;
                case Number:
                    array.put(readableArray.getDouble(i));
                    break;
                case String:
                    array.put(readableArray.getString(i));
                    break;
                case Map:
                    array.put(convertMapToJson(readableArray.getMap(i)));
                    break;
                case Array:
                    array.put(convertArrayToJson(readableArray.getArray(i)));
                    break;
            }
        }
        return array;
    }

    public static JSONArray listToJSON(Iterable<? extends JSONSerializable> list) {
        JSONArray arr = new JSONArray();

        try {
            for (JSONSerializable item : list) {
                arr.put(item.toJSONObject());
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return arr;
    }

    public void sendEvent(Callback callbackContext, String event, Object ... objs) {
        if (event == null) return;
        JSONObject json = new JSONObject();
        WritableNativeMap map = new WritableNativeMap();
        WritableNativeArray arr = new WritableNativeArray();
        try {
            Log.e(LOG_TAG, "sendEvent " + objs[0].toString());
            String jsonInString = objs[0].toString();
            JSONObject mJSONObject = new JSONObject(jsonInString);
            for (Iterator<String> it = mJSONObject.keys(); it.hasNext(); ) {
                String key = it.next();
                json.put(key, mJSONObject.get(key));
            }

            map = (WritableNativeMap) convertJsonToMap(json);
            if (objs.length > 1)
            {
                for (Object obj : objs) {
                    arr.pushString(obj.toString());
                }

                map.putArray(event, arr);
            }
            else
            {
                map = (WritableNativeMap) convertJsonToMap(mJSONObject);
            }
            if (callbackContext == null)
                getContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit(event, map);
            else
                callbackContext.invoke(map);
        }
        catch (RuntimeException e) {
            getContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit(event, map);
        }
        catch (Exception ex) {
            ex.printStackTrace();
        }
    }

    void sendSuccessEvent(Callback callback, Object ... objs) {
        if (callback == null) return;
        WritableNativeArray arr = new WritableNativeArray();

        try {
            JSONArray arrObj = new JSONArray(objs.toString());
            for (int i=0; i < arrObj.length(); i++) {
                JSONObject json = arrObj.getJSONObject(i);
                arr.pushMap(convertJsonToMap(json));
            }

            callback.invoke(arr);
        }
        catch (Exception ex) {
            ex.printStackTrace();
        }

    }

    public void success(Callback callback) {
        sendSuccessEvent(callback);
    }

    public void success(Callback callback,JSONObject obj) {
        sendSuccessEvent(callback, obj);
    }

    public void success(Callback callback, JSONArray arr) {
        sendSuccessEvent(callback, arr);
    }

    public void success(Callback callback,JSONSerializable obj) {
        JSONObject response = null;

        try {
            response = obj.toJSONObject();
        } catch (JSONException e) {
            e.printStackTrace();
        }

        if (response != null) {
            success(callback, response);
        }
    }

    public <T extends JSONSerializable> void success(Callback callback, List<T> list) {
        JSONArray response = listToJSON(list);

        success(callback, response);
    }

    public void success(Callback callback, Number obj) {
        sendSuccessEvent(callback, obj);
    }

    public void success(Callback callback,Boolean obj) {
        sendSuccessEvent(callback, obj);
    }

    public void error(Callback callback, String errorMessage) {
        if (callback == null) return;

        JSONObject errorObj = new JSONObject();

        try {
            errorObj.put("message", errorMessage);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        callback.invoke(errorObj);
    }

    public void error(Callback callback, Exception ex) {
        if (callback == null) return;

        JSONObject errorObj = new JSONObject();

        try {
            errorObj.put("message", ex.getMessage());
            errorObj.put("detail", ex.toString());
        } catch (JSONException e) {
            e.printStackTrace();
        }

        callback.invoke(errorObj);
    }

    public void error(Callback callback, ServiceCommandError error) {
        if (callback == null) return;

        JSONObject errorObj = new JSONObject();

        try {
            errorObj.put("code", error.getCode());
            errorObj.put("message", error.getMessage());
            errorObj.put("detail", error.getPayload());
        } catch (JSONException e) {
            e.printStackTrace();
        }

        callback.invoke(errorObj);
    }

    public void addObjectWrapper(JSObjectWrapper wrapper) {
        objectWrappers.put(wrapper.objectId, wrapper);
    }

    public JSObjectWrapper getObjectWrapper(String objectId) {
        return objectWrappers.get(objectId);
    }

    public void removeObjectWrapper(JSObjectWrapper wrapper) {
        objectWrappers.remove(wrapper.objectId);
        wrapper.cleanup();
    }

    private DeviceService.PairingType getPairingTypeFromString(String pairingTypeString) {
        if (JS_PAIRING_TYPE_FIRST_SCREEN.equalsIgnoreCase(pairingTypeString)) {
            return DeviceService.PairingType.FIRST_SCREEN;
        } else if (JS_PAIRING_TYPE_PIN.equalsIgnoreCase(pairingTypeString)) {
            return DeviceService.PairingType.PIN_CODE;
        } else if (JS_PAIRING_TYPE_MIXED.equalsIgnoreCase(pairingTypeString)) {
            return DeviceService.PairingType.MIXED;
        }
        return DeviceService.PairingType.NONE;
    }
}