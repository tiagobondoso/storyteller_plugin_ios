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

    return execPromise('openStoryById', [id], successCallback, errorCallback);
};

// Define helper to wrap exec into Promise + optional callbacks
function execPromise(action, args, successCallback, errorCallback) {
    return new Promise(function(resolve, reject) {
        exec(function(res) {
            if (typeof successCallback === 'function') successCallback(res);
            resolve(res);
        }, function(err) {
            if (typeof errorCallback === 'function') errorCallback(err);
            reject(err);
        }, 'Storyteller', action, args || []);
    });
}

// Set user locale (string or null to clear)
Storyteller.setLocale = function(locale, successCallback, errorCallback) {
    return execPromise('setLocale', [locale], successCallback, errorCallback);
};

// User custom attributes
Storyteller.setUserCustomAttribute = function(key, value, successCallback, errorCallback) {
    if (typeof key !== 'string' || key.length === 0) {
        const err = 'Attribute key is required';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }
    return execPromise('setUserCustomAttribute', [key, String(value)], successCallback, errorCallback);
};

Storyteller.removeUserCustomAttribute = function(key, successCallback, errorCallback) {
    if (typeof key !== 'string' || key.length === 0) {
        const err = 'Attribute key is required';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }
    return execPromise('removeUserCustomAttribute', [key], successCallback, errorCallback);
};

// Followed categories
Storyteller.addFollowedCategory = function(categoryId, successCallback, errorCallback) {
    if (typeof categoryId !== 'string' || categoryId.length === 0) {
        const err = 'Category id is required';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }
    return execPromise('addFollowedCategory', [categoryId], successCallback, errorCallback);
};

Storyteller.addFollowedCategories = function(categories, successCallback, errorCallback) {
    if (!Array.isArray(categories) || categories.length === 0) {
        const err = 'Categories array is required';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }
    return execPromise('addFollowedCategories', [categories], successCallback, errorCallback);
};

Storyteller.removeFollowedCategory = function(categoryId, successCallback, errorCallback) {
    if (typeof categoryId !== 'string' || categoryId.length === 0) {
        const err = 'Category id is required';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }
    return execPromise('removeFollowedCategory', [categoryId], successCallback, errorCallback);
};

module.exports = Storyteller;