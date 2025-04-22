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

module.exports = Storyteller;