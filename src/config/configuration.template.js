module.exports = {
    connection: "<SB_CONNECTION_STRING>",
    topics: {
        send: "<SB_SEND_TOPIC>",
        receive: "<SB_RECEIVE_TOPIC>",
        process: "<SB_PROCESS_TOPIC>",
        transform: "<SB_TRANSFORM_TOPIC>"
    },
    subscriptions: {
        send: "<SB_SEND_TOPIC_SUBSCRIPTION>",
        receive: "<SB_RECEIVE_TOPIC_SUBSCRIPTION>",
        process: "<SB_PROCESS_TOPIC_SUBSCRIPTION>",
        transform: "<SB_TRANSFORM_TOPIC_SUBSCRIPTION>"
    }
}