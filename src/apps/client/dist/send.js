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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const service_bus_1 = require("@azure/service-bus");
const configuration_1 = __importDefault(require("../../../config/configuration"));
// retrieve config settings
const connectionString = configuration_1.default.connection;
const topicName = configuration_1.default.topics.send;
const json_message = {
    id: "",
    service: "http://iban-validator",
    command: "validate",
    invoke: "0",
    data: "AAAA-BBBB-CCCC-DDDD-EEEE"
};
// const messages = [
//     { body: "Albert Einstein" },
//     { body: "Werner Heisenberg" },
//     { body: "Marie Curie" },
//     { body: "Steven Hawking" },
//     { body: "Isaac Newton" },
//     { body: "Niels Bohr" },
//     { body: "Michael Faraday" },
//     { body: "Galileo Galilei" },
//     { body: "Johannes Kepler" },
//     { body: "Nikolaus Kopernikus" }
// ];
const messages = [
    { body: "Albert Einstein" }
];
function main() {
    return __awaiter(this, void 0, void 0, function* () {
        // output
        console.log("cli-send");
        console.log("using topic: " + topicName);
        console.log("using connection string: " + connectionString);
        // create a Service Bus client using the connection string to the Service Bus namespace
        const sbClient = new service_bus_1.ServiceBusClient(connectionString);
        // createSender() can also be used to create a sender for a queue.
        const sender = sbClient.createSender(topicName);
        try {
            // Tries to send all messages in a single batch.
            // Will fail if the messages cannot fit in a batch.
            // await sender.sendMessages(messages);
            // create a batch object
            let batch = yield sender.createMessageBatch();
            for (let i = 0; i < messages.length; i++) {
                // for each message in the array			
                json_message.id = "aaaaa-aababba-sjsjsjs-" + Date.now();
                json_message.invoke = i.toString();
                json_message.data = "aaaaaa-" + i.toString();
                // set message
                const message = {
                    body: json_message
                };
                // try to add the message to the batch
                if (!batch.tryAddMessage(message)) {
                    // if it fails to add the message to the current batch
                    // send the current batch as it is full
                    yield sender.sendMessages(batch);
                    // then, create a new batch 
                    batch = yield sender.createMessageBatch();
                    // now, add the message failed to be added to the previous batch to this batch
                    if (!batch.tryAddMessage(message)) {
                        // if it still can't be added to the batch, the message is probably too big to fit in a batch
                        throw new Error("Message too big to fit in a batch");
                    }
                }
            }
            // Send the last created batch of messages to the topic
            yield sender.sendMessages(batch);
            console.log(`Sent a batch of messages to the topic: ${topicName}`);
            // Close the sender
            yield sender.close();
        }
        finally {
            yield sbClient.close();
        }
    });
}
// call the main function
main().catch((err) => {
    console.log("Error occurred: ", err);
    process.exit(1);
});
