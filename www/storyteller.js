var exec = require('cordova/exec');

var Storyteller = {
    // Inicializar o SDK
    initialize: function(apiKey, userId, successCallback, errorCallback) {
        exec(successCallback, errorCallback, 'Storyteller', 'initializeSDK', [apiKey, userId]);
    },

    // Exibir a View nativa do Storyteller
    showStorytellerView: function(successCallback, errorCallback) {
        exec(successCallback, errorCallback, 'Storyteller', 'showStorytellerView', []);
    }
};

// Abre um story pelo id ou externalId.
// Retorna uma Promise; também aceita callbacks (success, error) para compatibilidade.
Storyteller.openStoryById = function(id, successCallback, errorCallback) {
    if (typeof id !== 'string' || id.length === 0) {
        const err = 'Story ID is required';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }

    const promise = new Promise(function(resolve, reject) {
        exec(function(res) {
            if (typeof successCallback === 'function') successCallback(res);
            resolve(res);
        }, function(err) {
            if (typeof errorCallback === 'function') errorCallback(err);
            reject(err);
        }, 'Storyteller', 'openStoryById', [id]);
    });

    return promise;
};

module.exports = Storyteller;