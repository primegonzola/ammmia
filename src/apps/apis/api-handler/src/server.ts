import app from './app'
import { Sdk, TopicOptions, RelayMessage } from "./sdk";

const port = parseInt(process.env.PORT || '3000')

const server = new app().Start(port)
  .then(async port => {
    console.log(`Server running on port ${port}`);

    try {
      // setup sdk
      const sdk = new Sdk();

      // set up to receive
      console.log("setting up receiver");

      await sdk.receive(TopicOptions.Process, async (message) => {
        // get source
        const source = RelayMessage.read(message.body);

        // check the from
        switch (source.from) {
          case TopicOptions.Dispatch: {
            // relay message to transform
            await sdk.relay(new RelayMessage(
              undefined,
              TopicOptions.Process,
              TopicOptions.Dispatch,
              source.data
            ));
            break;
          }
          default:
            throw new Error("unsupported from: " + source.from);
        }

        // mark as handled
        return true;
      });
    }
    catch (error) {
      console.log("error starting sdk. " + error);
    }
  })
  .catch(error => {
    console.log(error)
    process.exit(1);
  });

export default server;