module.exports = {
    connection: "Endpoint=sb://ammmia-sbns-1619551024.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=h2sAmNrLTVdwC93YlCGbCuh8pX9k2E/GGRXXHUulN0c=",
    topics: {
        send: "send",
        receive: "receive-topic-1619551024",
        process: "process-topic-1619551024",
        transform: "transform-topic-1619551024"
    },
    subscriptions: {
        send: "sender",
        receive: "receive-topic-subscription-1619551024",
        process: "process-topic-subscription-1619551024",
        transform: "transform-topic-subscription-1619551024"
    }
}