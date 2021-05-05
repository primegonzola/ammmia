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
const instruction = process.argv.length > 2 ? process.argv[2] : undefined;
const service = process.argv.length > 3 ? process.argv[3] : undefined;
const command = process.argv.length > 4 ? process.argv[4] : undefined;
const payload = process.argv.length > 5 ? process.argv[5] : undefined;
console.log("executing client command: " + instruction);
function main() {
    return __awaiter(this, void 0, void 0, function* () {
        // create sdk
        const sdk = new sdk_1.Sdk(configuration_1.default);
        // check command
        switch (instruction) {
            case "send":
                // send the message
                console.log("send client message");
                yield sdk.batch(sdk_1.TopicOptions.Send, [
                    new sdk_1.ClientMessage(undefined, undefined, service || "process-api", command || "validate", payload || "aaaaaa")
                ]);
                // dispose
                yield sdk.dispose();
                break;
            case "receive":
                // start receiver
                yield sdk.receive(sdk_1.TopicOptions.Receive, (message) => __awaiter(this, void 0, void 0, function* () {
                    // receiveing client message
                    console.log("receiving client message: " + message.id);
                    console.log(message);
                    // mark as handled
                    return true;
                }));
                break;
        }
    });
}
// call the main function
main().catch((err) => {
    console.log("Error occurred: ", err);
    process.exit(1);
});
