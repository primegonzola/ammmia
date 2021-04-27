import { AzureFunction, Context } from "@azure/functions"

const serviceBusTopicTrigger: AzureFunction = async function(context: Context, message: any): Promise<void> {
    context.log('ServiceBus topic trigger function processed message', message);
    const instance = JSON.parse(message);
    context.log(instance.invoke);
};

export default serviceBusTopicTrigger;
