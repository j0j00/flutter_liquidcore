/* Hello, World! Micro Service */

console.log('Hello World!, the Microservice is running!');

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

LiquidCore.on( 'exit', function(name) {
    process.exit(0);
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

LiquidCore.emit( 'object', 'my string' );
LiquidCore.emit( 'object', -1 );
LiquidCore.emit( 'object', 4/3 );
LiquidCore.emit( 'object', new Date() );
LiquidCore.emit( 'object', [1, 'another string', null, true, false, undefined, new Date()] );
LiquidCore.emit( 'object', {a:1, b: 2} );
LiquidCore.emit( 'object', {obj: {x:1,y:2,z:3}, func: function () {}} );
LiquidCore.emit( 'object', function() {} );
LiquidCore.emit( 'object', function() { console.log('hello') } );
LiquidCore.emit( 'object', true );
LiquidCore.emit( 'object', false );
LiquidCore.emit( 'object', [] );