var exec = require('cordova/exec');

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

var Storyteller = {};

// Inicializar o SDK
Storyteller.initialize = function(apiKey, userId, successCallback, errorCallback) {
    if (typeof apiKey !== 'string' || apiKey.length === 0) {
        const err = 'API key is required';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }
    if (typeof userId !== 'string' || userId.length === 0) {
        const err = 'User ID is required';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }

    return execPromise('initializeSDK', [apiKey, userId], successCallback, errorCallback);
};

// Exibir a View nativa do Storyteller
Storyteller.showStorytellerView = function(successCallback, errorCallback) {
    return execPromise('showStorytellerView', [], successCallback, errorCallback);
};

// Abre um story pelo id ou externalId.
Storyteller.openStoryById = function(id, successCallback, errorCallback) {
    if (typeof id !== 'string' || id.length === 0) {
        const err = 'Story ID is required';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }

    return execPromise('openStoryById', [id], successCallback, errorCallback);
};

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

Storyteller.removeFollowedCategories = function(categories, successCallback, errorCallback) {
    if (!Array.isArray(categories) || categories.length === 0) {
        const err = 'Categories array is required';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }
    return execPromise('removeFollowedCategories', [categories], successCallback, errorCallback);
};

// Get followed categories (returns array of category ids)
Storyteller.getFollowedCategories = function(successCallback, errorCallback) {
    return execPromise('getFollowedCategories', [], successCallback, errorCallback);
};

// Check if a category is followed
Storyteller.isCategoryFollowed = function(categoryId, successCallback, errorCallback) {
    if (typeof categoryId !== 'string' || categoryId.length === 0) {
        const err = 'Category id is required';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }
    return execPromise('isCategoryFollowed', [categoryId], successCallback, errorCallback);
};


module.exports = Storyteller;