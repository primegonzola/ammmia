import * as express from 'express'
import Message from './models/message'
import { v4 as uuid } from 'uuid';
import cors from 'cors'

class Router {

    constructor(server: express.Express) {
        const router = express.Router()

        const messages = new Map<string, Message>();
        messages[uuid()] = {
            id: uuid(),
            command: "valiedate", 
            data: "test-data-" + uuid()
        }
        messages[uuid()] = {
            id: uuid(),
            command: "valiedate", 
            data: "test-data-" + uuid()
        }

        router.get('/', (req: express.Request, res: express.Response) => {
            res.json({
                message: `Nothing to see here.`
            })
        })

        //get all messages
        router.get('/messages', cors(), (req: express.Request, res: express.Response) => {
            res.json({
                messages
            })
        })

        //create new Message
        router.post('/messages', cors(), (req: express.Request, res: express.Response) => {
            try {
                console.log("posting")
                let message: Message = {} as Message;
                Object.assign(message, req.body)
                const newUUID = uuid();
                messages[newUUID] = message;
                res.json({
                    id: newUUID
                })
            } catch (e) {
                res.status(400).send(JSON.stringify({ "error": "problem with posted data" }));
            }
        })

        //get Message by id
        router.get('/messages/:id', cors(), (req: express.Request, res: express.Response) => {
            if (!!messages[req.params.id]) {
                res.json({
                    message: messages[req.params.id]
                })
            } else {
                res.status(404).send(JSON.stringify({ "error": "no such message" }));
            }
        })

        //update message
        router.put('/messages/:id', cors(), (req: express.Request, res: express.Response) => {
            try {
                if (!!messages[req.params.id]) {
                    let message: Message = {} as Message;
                    Object.assign(message, req.body)
                    messages[req.params.id] = message;
                    res.json({
                        message: messages[req.params.id]
                    })
                } else {
                    res.status(404).send(JSON.stringify({ "error": "no such message" }));
                }
            } catch (e) {
                res.status(400).send(JSON.stringify({ "error": "problem with posted data" }));
            }
        })

        //delete Message
        router.delete('/messages/:id', cors(), (req: express.Request, res: express.Response) => {
            if (!!messages[req.params.id]) {
                delete messages[req.params.id]
                res.json({
                    uuid: req.params.id
                })
            } else {
                res.status(404).send(JSON.stringify({ "error": "no such message" }));
            }
        });

        router.options('*', cors());

        server.use('/', router)
    }
}

export default Router;