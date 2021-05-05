"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const sdk_1 = require("./sdk");
const configuration_1 = __importDefault(require("../../../config/configuration"));
const command = process.argv[2];
console.log("executing client command: " + command);
function main() {
    return __awaiter(this, void 0, void 0, function* () {
        // create sdk
        const sdk = new sdk_1.Sdk(configuration_1.default);
        // check command
        switch (command) {
            case "send":
                // send the message
                console.log("send client message");
                yield sdk.send(sdk_1.TopicOptions.Send, new sdk_1.ClientMessage(undefined, "process-api", "validate", "aaaaaa"));
                break;
            case "receive":
                // start receiver
                yield sdk.receive(sdk_1.TopicOptions.Receive, (message) => __awaiter(this, void 0, void 0, function* () {
                    // receiveing client message
                    console.log("receiving client message: " + message);
                    // mark as handled
                    return true;
                }));
                break;
        }
        // dispose
        sdk.dispose();
    });
}
// call the main function
main().catch((err) => {
    console.log("Error occurred: ", err);
    process.exit(1);
});
