module.exports = {
    connection: "<SB_CONNECTION_STRING>",
    topics: {
        send: "<SB_SEND_TOPIC>",
        receive: "<SB_RECEIVE_TOPIC>",
        dispatch: "<SB_DISPATCH_TOPIC>",
        process: "<SB_PROCESS_TOPIC>",
        transform: "<SB_TRANSFORM_TOPIC>"
    },
    subscriptions: {
        send: "<SB_SEND_SUBSCRIPTION>",
        receive: "<SB_RECEIVE_SUBSCRIPTION>",
        dispatch: "<SB_DISPATCH_SUBSCRIPTION>",
        process: "<SB_PROCESS_SUBSCRIPTION>",
        transform: "<SB_TRANSFORM_SUBSCRIPTION>"
    }
}