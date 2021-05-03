import { AzureFunction, Context } from "@azure/functions";
import { Sdk, TopicOptions, RelayMessage } from "../common/sdk";

const serviceBusTopicTrigger: AzureFunction = async function (context: Context, message: any): Promise<void> {
    // log for debugging
    context.log('received dispatch-topic message:', message);

    // create sdh
    const sdk = new Sdk();

    // get source
    const source = RelayMessage.read(message);

    // check the from
    switch (source.from) {
        case TopicOptions.Send: {
            // relay message to transform
            await sdk.relay(new RelayMessage(
                undefined,
                TopicOptions.Dispatch,
                TopicOptions.Transform,
                source.data
            ));
            break;
        }
        case TopicOptions.Transform: {
            // relay message to transform
            await sdk.relay(new RelayMessage(
                undefined,
                TopicOptions.Dispatch,
                TopicOptions.Process,
                source.data
            ));
            break;
        }
        case TopicOptions.Process: {
            // relay message to transform
            await sdk.relay(new RelayMessage(
                undefined,
                TopicOptions.Dispatch,
                TopicOptions.Receive,
                source.data
            ));
            break;
        }
        default:
            throw new Error("unsupported from: " + source.from);
    }

    // done
    sdk.dispose();
};

export default serviceBusTopicTrigger;
