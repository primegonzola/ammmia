const { delay, ServiceBusClient, ServiceBusMessage } = require("@azure/service-bus");

const config = require("../../../config/configuration");

// retrieve config settings
const connectionString = config.connection;
const topicName = config.topics.send;
const subscriptionName = config.subscriptions.send;

async function main() {
    // output
    console.log("cli-receive");
    console.log("using topic: " + topicName);
    console.log("using subscription: " + subscriptionName);
    console.log("using connection: " + connectionString);

    // create a Service Bus client using the connection string to the Service Bus namespace
    const sbClient = new ServiceBusClient(connectionString);

    // createReceiver() can also be used to create a receiver for a queue.
    const receiver = sbClient.createReceiver(topicName, subscriptionName);

    // // function to handle messages
    // const myMessageHandler = async(messageReceived) => {
    //     console.log(`Received message: ${messageReceived.body}`);
    // };

    // // function to handle any errors
    // const myErrorHandler = async(error) => {
    //     console.log(error);
    // };

    // // subscribe and specify the message and error handlers
    // receiver.subscribe({
    //     processMessage: myMessageHandler,
    //     processError: myErrorHandler
    // });

    try {
        for (let i = 0; i < 10; i++) {
            const messages = await receiver.receiveMessages(1, {
                maxWaitTimeInMs: 5000
            });
            if (!messages.length) {
                console.log("No more messages to receive");
                break;
            }
            console.log(`Received message #${i}: ${messages[0].body}`);
            await receiver.completeMessage(messages[0]);
        }
        await receiver.close();
    } finally {
        await sbClient.close();
    }

    // Waiting long enough before closing the sender to send messages
    // await delay(5000);
    // while (true);

    // await receiver.close();
    // await sbClient.close();
}

// call the main function
main().catch((err) => {
    console.log("Error occurred: ", err);
    process.exit(1);
});