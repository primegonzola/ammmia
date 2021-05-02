import { AzureFunction, Context } from "@azure/functions";
import {Sdk, TopicOptions, RelayMessage} from "../common/sdk";

const serviceBusTopicTrigger: AzureFunction = async function(context: Context, message: any): Promise<void> {
    // log for debugging
    context.log('received send-topic message:', message);

    // create sdh
    const sdk = new Sdk();

    // relay message to dispatch
    await sdk.relay(new RelayMessage(
        TopicOptions.Send,
        TopicOptions.Dispatch,
        message
    ));

    // done
    sdk.dispose();
};

export default serviceBusTopicTrigger;
