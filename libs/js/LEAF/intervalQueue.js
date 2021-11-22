'use strict';

var intervalQueue = function() {
    var maxConcurrent = 2;
    var queue = [];
    var onCompleteCallback;
    var workerFunction;
    var workerErrorFunction;

    var loading = 0;
    var loaded = 0;
    var interval = null;

    function setConcurrency(limit) {
        maxConcurrent = limit;
    }

    function setWorker(func) {
        workerFunction = func;
    }

    function setOnWorkerError(func) {
        workerErrorFunction = func;
    }

    function onComplete(func) {
        onCompleteCallback = func;
    }

    function push(item) {
        queue.push(item);
    }

    function start() {
        interval = setInterval(function() {
            while (loading <= maxConcurrent
                && queue.length > 0) {
                
                loading++;
                workerFunction(queue.shift()).then(
                    function(result) { // fulfilled
                        loaded++;
                        loading--;
                    },
                    function(reason) {
                        loaded++;
                        loading--;
                        if(typeof workerErrorFunction == 'function') {
                            workerErrorFunction(reason);
                        }
                    } // rejected
                );
            }

            // When finished
            if (queue.length == 0
                && loading == 0) {
                clearInterval(interval);

                if(typeof onCompleteCallback == 'function') {
                    onCompleteCallback();
                }
            }
        }, 100);
    }

    return {
        start: start,
        push: push,
        setConcurrency: setConcurrency,
        setWorker: setWorker,
        setOnWorkerError: setOnWorkerError,
        getLoaded: function() {
            return loaded;
        },
        onComplete: onComplete
    };
};
