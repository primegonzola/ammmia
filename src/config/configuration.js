module.exports = {
    connection: "Endpoint=sb://ammmia-sbns-1619558457.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=4cuvcjRnQ1NObztnpRs8KXW/0oExGrXo4VnmByO/tt0=",
    topics: {
        send: "send-topic-1619558457",
        receive: "receive-topic-1619558457",
        process: "process-topic-1619558457",
        transform: "transform-topic-1619558457"
    },
    subscriptions: {
        send: "send-topic-subscription-1619558457",
        receive: "receive-topic-subscription-1619558457",
        process: "process-topic-subscription-1619558457",
        transform: "transform-topic-subscription-1619558457"
    }
}