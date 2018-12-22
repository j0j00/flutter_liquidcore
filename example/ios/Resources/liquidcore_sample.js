/* Hello, World! Micro Service */

// A micro service will exit when it has nothing left to do.  So to
// avoid a premature exit, let's set an indefinite timer.  When we
// exit() later, the timer will get invalidated.
setInterval(function() {}, 1000)

// Listen for a request from the host for the 'ping' event
LiquidCore.on( 'ping', function(name) {
    // When we get the ping from the host, respond with "Hallo, $name!"
    // and then exit.
    LiquidCore.emit( 'pong', { message: `Hallo, ${name}!` } )
    //process.exit(0)
})

// Ok, we are all set up.  Let the host know we are ready to talk
LiquidCore.emit( 'ready' )

const vm = require('vm');
const x = 1;
const sandbox = { x: 2 };
vm.createContext(sandbox); // Contextify the sandbox.
vm.runInContext('x += 40; var y = 17;', sandbox);

// Send the results of the sandbox eval over to the host.
LiquidCore.emit( 'pong', { message: `vm sandbox.x = ${sandbox.x}` } )