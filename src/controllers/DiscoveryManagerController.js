//
//  Connect SDK React Native API Sampler by LG Electronics
//
//  To the extent possible under law, the person who associated CC0 with
//  this sample app has waived all copyright and related or neighboring rights
//  to the sample app.
//
//  You should have received a copy of the CC0 legalcode along with this
//  work. If not, see http://creativecommons.org/publicdomain/zero/1.0/.
//
const ConnectSDK = require('../ConnectSDK');
const App = require('../App');
const requestPairing = true; // if true, ask for capabilities that require pairing
const airPlayMirror = true; // if true, use mirroring for displaying content on AirPlay
const deviceController = App.deviceController;
var NULL = function () {};

function requestPairingChanged() {
	// restart discovery with new setting
	this.stopDiscovery();
	this.startDiscovery();
}

function airPlayMirrorChanged() {
	// SDK currently doesn't support changing this at runtime
	this.app.showMessage("Notice", "Please restart the app for the AirPlay mirror mode setting to take effect.");
}

function startDiscovery() {
	ConnectSDK.discoveryManager.startDiscovery({
		pairingLevel: requestPairing ? ConnectSDK.PairingLevel.ON : ConnectSDK.PairingLevel.OFF,
		airPlayServiceMode: airPlayMirror ? ConnectSDK.AirPlayServiceMode.WEBAPP :
			ConnectSDK.AirPlayServiceMode.MEDIA
	}, NULL);

    App.eventEmitter.addListener('devicefound', deviceFound);
	App.eventEmitter.addListener('deviceupdated', deviceUpdated);
	App.eventEmitter.addListener('devicelost', deviceLost);
}

function stopDiscovery() {
	ConnectSDK.discoveryManager.stopDiscovery();
	App.eventEmitter.removeListener('devicefound');
	App.eventEmitter.removeListener('deviceupdated');
	App.eventEmitter.removeListener('devicelost');
}

function deviceFound(device) {
	var arrDevice = ['devicefound', device];
	ConnectSDK.discoveryManager._handleDiscoveryUpdate(arrDevice);
}

function deviceUpdated(device) {
	var arrDevice = ['deviceupdated', device];
	ConnectSDK.discoveryManager._handleDiscoveryUpdate(arrDevice);
}

function deviceLost(device) {
	var arrDevice = ['devicelost', device];
	ConnectSDK.discoveryManager._handleDiscoveryUpdate(arrDevice);
}

function showPicker() {
	this.justStartedApp = false;
	this.picker = ConnectSDK.discoveryManager.pickDevice();

	this.picker.success(this.pickerSuccess, this);
	this.picker.error(function (err) {
		if (err) {
			console.log("picker error: " + JSON.stringify(err));
		} else {
			// if err is undefined, then picker was cancelled
			console.log("picker cancelled");
		}
	}, this);
}

function pickerSuccess(device) {
	console.log("pickerSuccess " + device.getId());

	if (deviceController.getDevice()) {
		deviceController.setDevice(null);
	}

	console.log("selected device in picker");
	deviceController.setDevice(device);
	console.log(device.getFriendlyName());
}

module.exports = { startDiscovery, stopDiscovery, showPicker, pickerSuccess };