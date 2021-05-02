import { Utils } from "../common/utils";
import { ServiceBusClient, ServiceBusMessage } from "@azure/service-bus";

class RelayMessage {
    public readonly id: string;
    public readonly service: string;
    public readonly command: string;
    public readonly data: unknown;

    constructor(service: string, command: string, data?: unknown) {
        this.id = Utils.uuid();
        this.service = service;
        this.command = command;
        this.data = data;
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

    public async relay(from: TopicOptions, to: TopicOptions, message: any): Promise<void> {
        // sanity check
        if (from === to)
            throw new Error("invalied-from-to");
        // create our sender
        const sender = this.client.createSender(
            this.resolveTopic(to));
        // log
        console.log("relaying message from " + from + " to " + to);
        // send our message
        await sender.sendMessages({
            body: JSON.stringify(message)
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
            body: JSON.stringify(message)
        });

        // all done
        sender.close();
    }

    public async receive(topic: TopicOptions, handler: (message: any) => boolean | undefined,
        count = 1, duration = 5000): Promise<void> {
        // check if any handler
        if (handler) {
            // create our receiver
            const receiver = this.client.createReceiver(
                this.resolveTopic(topic),
                this.resolveSubscription(topic))
            // get messages
            const messages = await receiver.receiveMessages(count, {
                maxWaitTimeInMs: duration
            });
            // check if any received
            const handled: Promise<void>[] = [];
            // loop 
            messages.forEach(message => {
                // log
                console.log("receiving message for topic " + topic);
                if (handler(message))
                    handled.push(receiver.completeMessage(message));
            });
            // complete handled ones
            if (handled.length > 0)
                await Promise.all(handled);
            // all one
            receiver.close();
        }
    }

    public dispose(): void {
        if (this.client) {
            this.client.close();
        }
    }
}