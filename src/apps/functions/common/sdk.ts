import {performance} from "perf_hooks";
import { ServiceBusClient, ServiceBusReceiver } from "@azure/service-bus";

export class Utils {
    public static uuid(): string {
        //Timestamp
        let d = new Date().getTime();
        //Time in microseconds since page-load or 0 if unsupported        
        let d2 = (performance && performance.now && (performance.now() * 1000)) || 0;
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
            let r = Math.random() * 16;//random number between 0 and 16
            if (d > 0) {//Use timestamp until depleted
                r = (d + r) % 16 | 0;
                d = Math.floor(d / 16);
            } else {//Use microseconds since page-load if supported
                r = (d2 + r) % 16 | 0;
                d2 = Math.floor(d2 / 16);
            }
            return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
        });
    }
}

export class ClientMessage {
    public readonly id: string;
    public readonly service: string;
    public readonly command: string;
    public readonly data: unknown;

    constructor(id: string, service: string, command: string, data?: unknown) {
        this.id = id || Utils.uuid();
        this.service = service;
        this.command = command;
        this.data = data;
    }

    public static serialize(instance: ClientMessage): any {
        return JSON.stringify({
            id: instance.id,
            service: instance.service,
            command: instance.command,
            data: instance.data
        });
    }

    public static deserialize(data: string): ClientMessage {
        // read incoming
        const instance = JSON.parse(data);
        // construct
        return new ClientMessage(
            instance.id,
            instance.service,
            instance.dommand,
            instance.data
        );
    }
}

export class RelayMessage {
    public readonly id: string;
    public readonly from: TopicOptions;
    public readonly to: TopicOptions;
    public readonly data: unknown;

    constructor(id: string, from: TopicOptions, to: TopicOptions, data?: unknown) {
        this.id = id || Utils.uuid();
        this.from = from;
        this.to = to;
        this.data = data;
    }

    public static serialize(instance: RelayMessage): any {
        return JSON.stringify({
            id: instance.id,
            from: instance.from,
            to: instance.to,
            data: instance.data
        });
    }
    public static read(instance: any): RelayMessage {
        // construct
        return new RelayMessage(
            instance.id,
            instance.from,
            instance.to,
            instance.data
        );
    }

    public static deserialize(data: string): RelayMessage {
        // read incoming
        const instance = JSON.parse(data);
        // construct
        return new RelayMessage(
            instance.id,
            instance.from,
            instance.to,
            instance.data
        );
    }
}

export type SdkConfiguration = {
    connection: string,
    topics: {
        send: string,
        receive: string,
        dispatch: string,
        process: string,
        transform: string
    },
    subscriptions: {
        send: string,
        receive: string,
        dispatch: string,
        process: string,
        transform: string
    }
};

export enum TopicOptions {
    Send = "send",
    Receive = "receive",
    Dispatch = "dispatch",
    Process = "process",
    Transform = "transform"
}

export class Sdk {
    public readonly client: ServiceBusClient;
    private readonly configuration: SdkConfiguration;

    constructor(configuration?: SdkConfiguration) {
        // init
        this.configuration = configuration;
        this.client = new ServiceBusClient(process.env.SB_CONNECTION_STRING || this.configuration.connection);
    }

    private resolveTopic(topic: TopicOptions): string {
        switch (topic) {
            case TopicOptions.Send:
                return process.env.SB_SEND_TOPIC || this.configuration.subscriptions.send;
            case TopicOptions.Receive:
                return process.env.SB_RECEIVE_TOPIC || this.configuration.subscriptions.receive;
            case TopicOptions.Dispatch:
                return process.env.SB_DISPATCH_TOPIC || this.configuration.subscriptions.dispatch;
            case TopicOptions.Transform:
                return process.env.SB_TRANSFORM_TOPIC || this.configuration.subscriptions.transform;
            case TopicOptions.Process:
                return process.env.SB_PROCESS_TOPIC || this.configuration.subscriptions.process;
            default:
                throw new Error("invalid-topic");
        }
    }

    private resolveSubscription(topic: TopicOptions): string {
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

    public async relay(message: RelayMessage): Promise<void> {
        // sanity check
        if (message.from === message.to)
            throw new Error("invalied-from-to: " + message.id);
        // create our sender
        const sender = this.client.createSender(
            this.resolveTopic(message.to));
        // log
        console.log("relaying message from " +
            message.from + " to " +
            message.to + " with id " +
            message.id);
        // send our message
        await sender.sendMessages({
            body: message
        });

        // all done
        sender.close();
    }

    public async send(topic: TopicOptions, message: any): Promise<void> {
        // create our sender
        const sender = this.client.createSender(
            this.resolveTopic(topic));
        // log
        console.log("sending message for topic " + topic);
        // send our message
        await sender.sendMessages({
            body: message
        });

        // all done
        sender.close();
    }

    public async receive(topic: TopicOptions, handler: (message: any) => Promise<boolean>,
        count = 1, duration = 5000): Promise<void> {
        // check if any handler
        if (handler) {
            // create our receiver
            const receiver = this.client.createReceiver(
                this.resolveTopic(topic),
                this.resolveSubscription(topic))

            // routine too execute
            const rfx = async (rx: ServiceBusReceiver, rh: (message: any) => Promise<boolean>) => {
                // get messages
                const messages = await rx.receiveMessages(count, {
                    maxWaitTimeInMs: duration
                });
                // check if anythinh received
                if (messages && messages.length > 0) {
                    // check if any received
                    const handlers = [];
                    const handled: Promise<void>[] = [];
                    // loop 
                    messages.forEach(message => {
                        // log
                        console.log("receiving message for topic " + topic);
                        handlers.push(rh(message));
                    });
                    // execute handlers
                    const completes = await Promise.all(handlers) as boolean[];
                    for (let i = 0; i < messages.length; i++) {
                        if (completes[i] === true)
                            handled.push(receiver.completeMessage(messages[i]))
                    }
                    // complete handled ones
                    if (handled.length > 0)
                        await Promise.all(handled);
                }

                // set next loop
                setTimeout(async () => await rfx(receiver, handler), 100);
            };
            // execute
            await rfx(receiver, handler);
            // all one o fix later
            // receiver.close();
        }
    }

    public dispose(): void {
        if (this.client) {
            this.client.close();
        }
    }
}