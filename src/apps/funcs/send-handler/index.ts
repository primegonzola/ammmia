import { AzureFunction, Context } from "@azure/functions";
import {Sdk, TopicOptions} from "../common/sdk";

const serviceBusTopicTrigger: AzureFunction = async function(context: Context, message: any): Promise<void> {
    context.log('received send-topic message:', message);

    // create sdh
    const sdk = new Sdk();

    // send message to dispatch
    await sdk.relay(TopicOptions.Send, TopicOptions.Dispatch, message);
};

export default serviceBusTopicTrigger;
