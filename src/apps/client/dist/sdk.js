"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Sdk = exports.TopicOptions = exports.RelayMessage = exports.ClientMessage = exports.Utils = void 0;
const perf_hooks_1 = require("perf_hooks");
const service_bus_1 = require("@azure/service-bus");
class Utils {
    static uuid() {
        //Timestamp
        let d = new Date().getTime();
        //Time in microseconds since page-load or 0 if unsupported        
        let d2 = (perf_hooks_1.performance && perf_hooks_1.performance.now && (perf_hooks_1.performance.now() * 1000)) || 0;
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
            let r = Math.random() * 16; //random number between 0 and 16
            if (d > 0) { //Use timestamp until depleted
                r = (d + r) % 16 | 0;
                d = Math.floor(d / 16);
            }
            else { //Use microseconds since page-load if supported
                r = (d2 + r) % 16 | 0;
                d2 = Math.floor(d2 / 16);
            }
            return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
        });
    }
}
exports.Utils = Utils;
class ClientMessage {
    constructor(id, invoke, service, command, data) {
        this.id = id || Utils.uuid();
        this.invoke = invoke || Utils.uuid();
        this.service = service;
        this.command = command;
        this.data = data;
    }
    static serialize(instance) {
        return JSON.stringify({
            id: instance.id,
            invoke: instance.invoke,
            service: instance.service,
            command: instance.command,
            data: instance.data
        });
    }
    static deserialize(data) {
        // read incoming
        const instance = JSON.parse(data);
        // construct
        return new ClientMessage(instance.id, instance.invoke, instance.service, instance.dommand, instance.data);
    }
}
exports.ClientMessage = ClientMessage;
class RelayMessage {
    constructor(id, from, to, data) {
        this.id = id || Utils.uuid();
        this.from = from;
        this.to = to;
        this.data = data;
    }
    static serialize(instance) {
        return JSON.stringify({
            id: instance.id,
            from: instance.from,
            to: instance.to,
            data: instance.data
        });
    }
    static read(instance) {
        // construct
        return new RelayMessage(instance.id, instance.from, instance.to, instance.data);
    }
    static deserialize(data) {
        // read incoming
        const instance = JSON.parse(data);
        // construct
        return new RelayMessage(instance.id, instance.from, instance.to, instance.data);
    }
}
exports.RelayMessage = RelayMessage;
var TopicOptions;
(function (TopicOptions) {
    TopicOptions["Send"] = "send";
    TopicOptions["Receive"] = "receive";
    TopicOptions["Dispatch"] = "dispatch";
    TopicOptions["Process"] = "process";
    TopicOptions["Transform"] = "transform";
})(TopicOptions = exports.TopicOptions || (exports.TopicOptions = {}));
class Sdk {
    constructor(configuration) {
        // init
        this.configuration = configuration;
        this.client = new service_bus_1.ServiceBusClient(process.env.SB_CONNECTION_STRING || this.configuration.connection);
    }
    resolveTopic(topic) {
        switch (topic) {
            case TopicOptions.Send:
                return process.env.SB_SEND_TOPIC || this.configuration.topics.send;
            case TopicOptions.Receive:
                return process.env.SB_RECEIVE_TOPIC || this.configuration.topics.receive;
            case TopicOptions.Dispatch:
                return process.env.SB_DISPATCH_TOPIC || this.configuration.topics.dispatch;
            case TopicOptions.Transform:
                return process.env.SB_TRANSFORM_TOPIC || this.configuration.topics.transform;
            case TopicOptions.Process:
                return process.env.SB_PROCESS_TOPIC || this.configuration.topics.process;
            default:
                throw new Error("invalid-topic");
        }
    }
    resolveSubscription(topic) {
        switch (topic) {
            case TopicOptions.Send:
                return process.env.SB_SEND_SUBSCRIPTION || this.configuration.subscriptions.send;
            case TopicOptions.Receive:
                return process.env.SB_RECEIVE_SUBSCRIPTION || this.configuration.subscriptions.receive;
            case TopicOptions.Dispatch:
                return process.env.SB_DISPATCH_SUBSCRIPTION || this.configuration.subscriptions.dispatch;
            case TopicOptions.Transform:
                return process.env.SB_TRANSFORM_SUBSCRIPTION || this.configuration.subscriptions.transform;
            case TopicOptions.Process:
                return process.env.SB_PROCESS_SUBSCRIPTION || this.configuration.subscriptions.process;
            default:
                throw new Error("invalid-subscription");
        }
    }
    relay(message) {
        return __awaiter(this, void 0, void 0, function* () {
            // sanity check
            if (message.from === message.to)
                throw new Error("invalied-from-to: " + message.id);
            // create our sender
            const sender = this.client.createSender(this.resolveTopic(message.to));
            // log
            console.log("relaying message from " +
                message.from + " to " +
                message.to + " with id " +
                message.id);
            // send our message
            yield sender.sendMessages({
                body: message
            });
            // all done
            yield sender.close();
        });
    }
    send(topic, message) {
        return __awaiter(this, void 0, void 0, function* () {
            // create our sender
            const sender = this.client.createSender(this.resolveTopic(topic));
            console.log(this.resolveTopic(topic));
            // send our message
            yield sender.sendMessages({
                body: message
            });
            // all done
            yield sender.close();
        });
    }
    batch(topic, messages) {
        return __awaiter(this, void 0, void 0, function* () {
            // create sender
            const sender = this.client.createSender(this.resolveTopic(topic));
            // create a batch object
            let batch = yield sender.createMessageBatch();
            // populate
            for (let i = 0; i < messages.length; i++) {
                // try to add the message to the batch
                if (!batch.tryAddMessage({
                    body: messages[i]
                })) {
                    // if it fails to add the message to the current batch
                    // send the current batch as it is full
                    yield sender.sendMessages(batch);
                    // then, create a new batch 
                    batch = yield sender.createMessageBatch();
                    // now, add the message failed to be added to the previous batch to this batch
                    if (!batch.tryAddMessage({
                        body: messages[i]
                    })) {
                        // if it still can't be added to the batch, the message is probably too big to fit in a batch
                        throw new Error("Message too big to fit in a batch");
                    }
                }
            }
            // Send the last created batch of messages to the topic
            yield sender.sendMessages(batch);
            /// outpu
            console.log(`Sent a batch of messages to the topic: ${topic}`);
            // Close the sender
            yield sender.close();
        });
    }
    receive(topic, handler, count = 1, duration = 5000) {
        return __awaiter(this, void 0, void 0, function* () {
            // check if any handler
            if (handler) {
                // create our receiver
                const receiver = this.client.createReceiver(this.resolveTopic(topic), this.resolveSubscription(topic));
                // routine too execute
                const rfx = (rx, rh) => __awaiter(this, void 0, void 0, function* () {
                    // get messages
                    const messages = yield rx.receiveMessages(count, {
                        maxWaitTimeInMs: duration
                    });
                    // check if anythinh received
                    if (messages && messages.length > 0) {
                        // check if any received
                        const handlers = [];
                        const handled = [];
                        // loop 
                        messages.forEach(message => {
                            // log
                            console.log("receiving message for topic " + topic);
                            handlers.push(rh(message.body));
                        });
                        // execute handlers
                        const completes = yield Promise.all(handlers);
                        for (let i = 0; i < messages.length; i++) {
                            if (completes[i] === true)
                                handled.push(receiver.completeMessage(messages[i]));
                        }
                        // complete handled ones
                        if (handled.length > 0)
                            yield Promise.all(handled);
                    }
                    // set next loop
                    setTimeout(() => __awaiter(this, void 0, void 0, function* () { return yield rfx(receiver, handler); }), 100);
                });
                // execute
                yield rfx(receiver, handler);
                // all one o fix later
                // receiver.close();
            }
        });
    }
    dispose() {
        return __awaiter(this, void 0, void 0, function* () {
            if (this.client) {
                yield this.client.close();
            }
        });
    }
}
exports.Sdk = Sdk;
