import ballerina/http;
import ballerina/log;

// By default, Ballerina assumes that the service is to be exposed via HTTP/1.1.
service<http:Service> hello bind { port: 8081 } {

    // All resources are invoked with arguments of server connector and request.
    @http:ResourceConfig {
        methods: ["GET"],
        path:"serviceB"
    }
    sayHello(endpoint caller, http:Request req) {
        string textValue = check req.getTextPayload();

        //ommit IO operations
        //log:printInfo(textValue);

        http:Response res = new;

        // A util method that can be used to set a string payload.
        res.setPayload(untaint textValue);

        // Sends the response back to the caller.
        _ = caller -> respond(res);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path:"testB"
    }
    sayHellow(endpoint caller, http:Request req) {
        string textValue = check req.getTextPayload();
        //ommit IO operations
        //log:printInfo(textValue);
        http:Response res = new;
        // A util method that can be used to set a string payload.
        res.setPayload(untaint textValue);
        // Sends the response back to the caller.
        _ = caller -> respond(res);
    }
}
