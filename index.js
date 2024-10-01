/* eslint-disable no-console */
// eslint-disable-next-line import/no-unresolved, import/extensions

const fs = require("fs");
const process = require("process");
const path = require("path");
const sourcePath = path.join(__dirname, "./discord_voice.node");
const destinationPath = path.join(
    __dirname,
    "./discord_voice_screen_share.node"
);

if (!fs.existsSync(destinationPath)) {
    try {
        fs.copyFileSync(sourcePath, destinationPath);
    } catch { console.error("Unable to make copy of discord_voice.node for screenshare audio") }
}

const VoiceEngineScreenShare = require("./discord_voice_screen_share.node");

const VoiceEngine = require("./index.orig.js");

const { spawn } = require("child_process");

let audioManagerProcess;

function startAudioManager() {

    const pid = process.pid;

    audioManagerProcess = spawn(path.join(__dirname, "audio_manager.sh"), [pid], {
        detached: true,
    });

    audioManagerProcess.stdout.on("data", (data) => {
        console.log(`stdout: ${data.toString()}`);
    });
    
    audioManagerProcess.stderr.on("data", (data) => {
        console.error(`stderr: ${data.toString()}`);
    });
    
    audioManagerProcess.on("close", (code) => {
        console.log(`audio_manager.sh exited with code ${code}`);
        audioManagerProcess = null;
    });
}

function stopAudioManager() {
    if (audioManagerProcess) {
        process.kill(-audioManagerProcess.pid, "SIGKILL");
        audioManagerProcess = null;
    }
}

process.on("SIGINT", () => {
    stopAudioManager();
});

process.on("exit", () => {
    stopAudioManager();
});

function bindConnectionInstance(instance, isStream) {
    return {
        destroy: () => {
            instance.destroy();
            stopAudioManager();
        },

        setTransportOptions: (options) => instance.setTransportOptions(options),
        setSelfMute: (mute) => instance.setSelfMute(mute),
        setSelfDeafen: (deaf) => instance.setSelfDeafen(deaf),

        mergeUsers: (users) => instance.mergeUsers(users),
        destroyUser: (userId) => instance.destroyUser(userId),

        prepareSecureFramesTransition: (transitionId, version, callback) =>
            instance.prepareSecureFramesTransition(transitionId, version, callback),
        prepareSecureFramesEpoch: (epoch, version, groupId) =>
            instance.prepareSecureFramesEpoch(epoch, version, groupId),
        executeSecureFramesTransition: (transitionId) =>
            instance.executeSecureFramesTransition(transitionId),

        updateMLSExternalSender: (externalSenderPackage) =>
            instance.updateMLSExternalSender(externalSenderPackage),
        getMLSKeyPackage: (callback) => instance.getMLSKeyPackage(callback),
        processMLSProposals: (message, callback) =>
            instance.processMLSProposals(message, callback),
        prepareMLSCommitTransition: (transitionId, commit, callback) =>
            instance.prepareMLSCommitTransition(transitionId, commit, callback),
        processMLSWelcome: (transitionId, welcome, callback) =>
            instance.processMLSWelcome(transitionId, welcome, callback),
        getMLSPairwiseFingerprint: (version, userId, callback) =>
            instance.getMLSPairwiseFingerprint(version, userId, callback),
        setOnMLSFailureCallback: (callback) =>
            instance.setOnMLSFailureCallback(callback),
        setSecureFramesStateUpdateCallback: (callback) =>
            instance.setSecureFramesStateUpdateCallback(callback),

        setLocalVolume: (userId, volume) => instance.setLocalVolume(userId, volume),
        setLocalMute: (userId, mute) => instance.setLocalMute(userId, mute),
        fastUdpReconnect: () => instance.fastUdpReconnect(),
        setLocalPan: (userId, left, right) =>
            instance.setLocalPan(userId, left, right),
        setDisableLocalVideo: (userId, disabled) =>
            instance.setDisableLocalVideo(userId, disabled),

        setMinimumOutputDelay: (delay) => instance.setMinimumOutputDelay(delay),
        getEncryptionModes: (callback) => instance.getEncryptionModes(callback),
        configureConnectionRetries: (baseDelay, maxDelay, maxAttempts) =>
            instance.configureConnectionRetries(baseDelay, maxDelay, maxAttempts),
        setOnSpeakingCallback: (callback) =>
            instance.setOnSpeakingCallback(callback),
        setOnNativeMuteToggleCallback: (callback) =>
            instance.setOnNativeMuteToggleCallback?.(callback),
        setOnNativeMuteChangedCallback: (callback) =>
            instance.setOnNativeMuteChangedCallback?.(callback),
        setOnSpeakingWhileMutedCallback: (callback) =>
            instance.setOnSpeakingWhileMutedCallback(callback),
        setPingInterval: (interval) => instance.setPingInterval(interval),
        setPingCallback: (callback) => instance.setPingCallback(callback),
        setPingTimeoutCallback: (callback) =>
            instance.setPingTimeoutCallback(callback),
        setRemoteUserSpeakingStatus: (userId, speaking) =>
            instance.setRemoteUserSpeakingStatus(userId, speaking),
        setRemoteUserCanHavePriority: (userId, canHavePriority) =>
            instance.setRemoteUserCanHavePriority(userId, canHavePriority),

        setOnVideoCallback: (callback) => instance.setOnVideoCallback(callback),
        setOnFirstFrameCallback: (callback) =>
            instance.setOnFirstFrameCallback(callback),
        setVideoBroadcast: (broadcasting) =>
            instance.setVideoBroadcast(broadcasting),
        setDesktopSource: (id, videoHook, type) =>
            instance.setDesktopSource(id, videoHook, type),
        setDesktopSourceWithOptions: (options) => {
            if (!instance.audio && isStream) {
                instance.setGoLiveDevices({
                    videoInputDeviceId: "Strobe Video Source",
                    audioInputDeviceId: "default",
                });
                instance.clearGoLiveDevices_ = instance.clearGoLiveDevices;
                instance.clearGoLiveDevices = () => { };
                instance.audio = true;
                setTimeout(() => startAudioManager(), 0);
            }
            return instance.setDesktopSourceWithOptions(options);
        },
        setGoLiveDevices: (options) => instance.setGoLiveDevices(options),
        clearGoLiveDevices: () => { },
        clearDesktopSource: () => instance.clearDesktopSource(),
        setDesktopSourceStatusCallback: (callback) =>
            instance.setDesktopSourceStatusCallback(callback),
        setOnDesktopSourceEnded: (callback) =>
            instance.setOnDesktopSourceEnded(callback),
        setOnSoundshare: (callback) => instance.setOnSoundshare(callback),
        setOnSoundshareEnded: (callback) => instance.setOnSoundshareEnded(callback),
        setOnSoundshareFailed: (callback) =>
            instance.setOnSoundshareFailed(callback),
        setPTTActive: (active, priority) => instance.setPTTActive(active, priority),
        getStats: (callback) => instance.getStats(callback),
        getFilteredStats: (filter, callback) =>
            instance.getFilteredStats(filter, callback),
        startReplay: () => instance.startReplay(),
        setClipRecordUser: (userId, dataType, shouldRecord) =>
            instance.setClipRecordUser(userId, dataType, shouldRecord),
        setRtcLogMarker: (marker) => instance.setRtcLogMarker(marker),
        startSamplesLocalPlayback: (samplesId, options, channels, callback) =>
            instance.startSamplesLocalPlayback(
                samplesId,
                options,
                channels,
                callback
            ),
        stopSamplesLocalPlayback: (sourceId) =>
            instance.stopSamplesLocalPlayback(sourceId),
        stopAllSamplesLocalPlayback: () => instance.stopAllSamplesLocalPlayback(),
        setOnVideoEncoderFallbackCallback: (codecName) =>
            instance.setOnVideoEncoderFallbackCallback(codecName),
        presentDesktopSourcePicker: (style) =>
            instance.presentDesktopSourcePicker(style),
    };
}

VoiceEngine.createOwnStreamConnectionWithOptions = function (
    userId,
    connectionOptions,
    onConnectCallback
) {
    const patchedInstance = new VoiceEngineScreenShare.VoiceConnection(
        userId,
        connectionOptions,
        onConnectCallback
    );
    return bindConnectionInstance(patchedInstance, true);
};

delete VoiceEngineScreenShare.setVideoOutputSink;
delete VoiceEngineScreenShare.signalVideoOutputSinkReady;

const addDirectVideoOutputSink_ = VoiceEngine.addDirectVideoOutputSink;
const removeDirectVideoOutputSink_ = VoiceEngine.removeDirectVideoOutputSink;

VoiceEngine.addDirectVideoOutputSink = function (streamId) {
    addDirectVideoOutputSink_(streamId);
    VoiceEngineScreenShare.addDirectVideoOutputSink(streamId);
};
VoiceEngine.removeDirectVideoOutputSink = function (streamId) {
    removeDirectVideoOutputSink_(streamId);
    VoiceEngineScreenShare.removeDirectVideoOutputSink(streamId);
};

VoiceEngineScreenShare.platform = VoiceEngine.platform;

VoiceEngineScreenShare.initialize({
    audioSubsystem: false,
    logLevel: "debug",
    dataDirectory: "",
    useFakeVideoCapture: true,
    useFileForFakeVideoCapture: false,
    useFakeAudioCapture: false,
    useFileForFakeAudioCapture: false,
});

VoiceEngine.patched = VoiceEngineScreenShare;

module.exports = VoiceEngine;
