'use strict'

const server = require(`websocket`).server;
const httpServer = require(`http`).createServer();
const redis = require(`redis`);
const osu = require(`node-os-utils`);
const moment = require(`moment`);
const app = require(`express`)();
const {
    redis: { port: redisPort, host: redisHost },
    websocket: { port: websocketPort },
    express: { port: expressPort },
    updateTimeout
} = require(`./settings`);

const socketListeners = {};
const listenersDevices = {};
const serverData = { start: new Date(), freeCPU: 100, freeRAM: 100 };
const redisData = {};

// Redis

const redisClient = redis.createClient(redisPort, redisHost);
redisClient.on(`connect`, redisConnectHandler);
redisClient.on(`reconnecting`, redisReconnectingHandler);
redisClient.on(`error`, redisErrorHandler);
redisClient.on(`message`, redisMessageHandler);
redisClient.subscribe("datatube");

// Redis обработчики

function redisConnectHandler() {
    redisData.status = `connected`;
    redisData.start = new Date();
}

function redisReconnectingHandler() {
    redisData.status = `reconnection...`;
    redisData.start = new Date();
}

function redisErrorHandler() {
    redisData.status = `error`;
}

function redisMessageHandler(channel, message) {
    if (!message) return;
    const {
        channelName, data: result, status = 1, errorCode = 0, callback = null
    } = JSON.parse(message);
    if (!socketListeners[channelName]) return;
    socketListeners[channelName].forEach((listener) => {
        let sendData;
        try {
            sendData = JSON.stringify({ result, status, errorCode, callback });
        } catch (error) {
            sendData = JSON.stringify({ message: result, callback });
        }
        listener.send(sendData);
    });
}

// WebSocket

const socketServer = new server({
    httpServer: httpServer.listen(websocketPort),
    keepalive: false
});
socketServer.on(`request`, socketRequestHandler);

// WebSocket обработчики

function socketRequestHandler(request) {
    const connection = request.accept(null, request.origin);
    const { resourceURL: { query: { channelName, type }}} = request;
    connection.on(`close`, socketCloseHandler(channelName, type, connection));
    addSocketConnection(channelName, connection);
    addSocketType(type);
}

function socketCloseHandler(channelName, type, connection) {
    return () => {
        deleteSocketConnection(channelName, connection);
        deleteSocketType(type);
    };
}

function addSocketConnection(channelName, connection) {
    if (!socketListeners[channelName]) {
        socketListeners[channelName] = new Set;
    }
    socketListeners[channelName].add(connection);
}

function deleteSocketConnection(channelName, connection) {
    socketListeners[channelName].delete(connection);
    if (!socketListeners[channelName].size) {
        delete socketListeners[channelName];
    }
}

function addSocketType(type) {
    if (!listenersDevices[type]) {
        listenersDevices[type] = 0;
    }
    listenersDevices[type] += 1;
}

function deleteSocketType(type) {
    listenersDevices[type] -= 1;
    if (!listenersDevices[type]) {
        delete listenersDevices[type];
    }
}

// Express

app.route([`/`, `/index`]).get(getExpressHandler);
app.listen(expressPort);

// Express обработчики

function getExpressHandler(request, response) {
    response.send(JSON.stringify(createSendData()))
}

function createSendData() {
    let channelsCount = 0, listenersCount = 0;
    for (const channel in socketListeners) {
        if (!socketListeners.hasOwnProperty(channel)) continue;
        channelsCount ++;
        listenersCount += socketListeners[channel].size;
    }
    return {
        status: (redisData.status === `connected`) ? `ok` : `error`,
        channels: channelsCount,
        listeners: {
            count: listenersCount,
            devices: listenersDevices
        },
        server: {
            start: serverData.start,
            duration: moment(serverData.start).locale("ru").fromNow(),
            freeCPU: serverData.freeCPU,
            freeRAM: serverData.freeRAM
        },
        redis: {
            status: redisData.status,
            start: redisData.start,
            duration: moment(redisData.start).locale("ru").fromNow()
        }
    }
}

function updateServerResource() {
    osu.cpu.free().then((cpuPercentage) => {
        serverData.freeCPU = cpuPercentage;
    });
    osu.mem.info().then(({ freeMemPercentage }) => {
        serverData.freeRAM = freeMemPercentage;
    });
}
setInterval(updateServerResource, updateTimeout);
