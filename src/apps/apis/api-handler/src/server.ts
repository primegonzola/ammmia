import app from './app'
import { Sdk, TopicOptions } from "./sdk";

const port = parseInt(process.env.PORT || '3000')

const server = new app().Start(port)
  .then(port => {
    console.log(`Server running on port ${port}`);

    try {
      console.log("Creating SDK")
      // create sdk
      const sdk = new Sdk();

      // set up to receive
      sdk.receive(TopicOptions.Process, (message) => {
        console.log("receiving message: " + message)

        // mark as handled
        return true;
      });

      console.log("Disposing SDK")
      // dispose all
      sdk.dispose();
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