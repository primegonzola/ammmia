import { ServiceBusClient } from "@azure/service-bus";
import config from "../../../config/configuration";

// retrieve config settings
const connectionString = config.connection;
const topicName = config.topics.send;

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

async function main() {
    // output
    console.log("cli-send");
    console.log("using topic: " + topicName);
    console.log("using connection string: " + connectionString);

    // create a Service Bus client using the connection string to the Service Bus namespace
    const sbClient = new ServiceBusClient(connectionString);

    // createSender() can also be used to create a sender for a queue.
    const sender = sbClient.createSender(topicName);

    try {
        // Tries to send all messages in a single batch.
        // Will fail if the messages cannot fit in a batch.
        // await sender.sendMessages(messages);

        // create a batch object
        let batch = await sender.createMessageBatch();
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
                await sender.sendMessages(batch);

                // then, create a new batch 
                batch = await sender.createMessageBatch();

                // now, add the message failed to be added to the previous batch to this batch
                if (!batch.tryAddMessage(message)) {
                    // if it still can't be added to the batch, the message is probably too big to fit in a batch
                    throw new Error("Message too big to fit in a batch");
                }
            }
        }

        // Send the last created batch of messages to the topic
        await sender.sendMessages(batch);

        console.log(`Sent a batch of messages to the topic: ${topicName}`);

        // Close the sender
        await sender.close();
    } finally {
        await sbClient.close();
    }
}

// call the main function
main().catch((err) => {
    console.log("Error occurred: ", err);
    process.exit(1);
});