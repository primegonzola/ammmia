import { ClientMessage, Sdk, TopicOptions } from "./sdk";
import config from "../../../config/configuration";

const instruction = process.argv.length > 2 ? process.argv[2] : undefined;
const service = process.argv.length > 3 ? process.argv[3] : undefined;
const command = process.argv.length > 4 ? process.argv[4] : undefined;
const payload = process.argv.length > 5 ? process.argv[5] : undefined;

console.log("executing client command: " + instruction);
async function main() {
    // create sdk
    const sdk = new Sdk(config);

    // check command
    switch (instruction) {
        case "send":
            // send the message
            console.log("send client message");
            await sdk.batch(TopicOptions.Send, [
                new ClientMessage(
                    undefined, undefined, 
                    service || "process-api", 
                    command || "validate", 
                    payload || "aaaaaa"
                )
            ]);
            // dispose
            await sdk.dispose();
            break;
        case "receive":
            // start receiver
            await sdk.receive(TopicOptions.Receive, async (message) => {
                // receiveing client message
                console.log("receiving client message: " + message.id);
                console.log(message);

                // mark as handled
                return true;
            });
            break;
    }
}

// call the main function
main().catch((err) => {
    console.log("Error occurred: ", err);
    process.exit(1);
});