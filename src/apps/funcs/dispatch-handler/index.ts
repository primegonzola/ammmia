import { AzureFunction, Context } from "@azure/functions"

const serviceBusTopicTrigger: AzureFunction = async function(context: Context, message: any): Promise<void> {
    context.log('Dispatching message', message);
    const instance = JSON.parse(message);
};

export default serviceBusTopicTrigger;
