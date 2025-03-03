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
        if(limit > 6) {
            console.log(`intervalQueue.js - Warning - setConcurrency(${limit}) may exceed browser limit of 6`);
        }
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
        let promise = new Promise((resolve, reject) => {
            interval = setInterval(function() {
                while (loading <= maxConcurrent
                    && queue.length > 0) {
                    
                    loading++;
                    let item = queue.shift();
                    workerFunction(item).then(
                        function(result) { // fulfilled
                            loaded++;
                            loading--;
                        },
                        function(reason) {
                            loaded++;
                            loading--;
                            if(typeof workerErrorFunction == 'function') {
                                workerErrorFunction(item, reason);
                            }
                        } // rejected
                    );
                }
    
                // When finished
                if (queue.length == 0
                    && loading == 0) {
                    clearInterval(interval);
    
                    if(typeof onCompleteCallback == 'function') {
                        resolve(onCompleteCallback());
                    }
                    else {
                        resolve('Complete');
                    }
                }
            }, 100);
        });
        return promise;
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
