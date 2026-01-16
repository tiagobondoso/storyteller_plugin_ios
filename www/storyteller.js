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

function coerceNumber(value) {
    var num = Number(value);
    return Number.isFinite(num) ? num : undefined;
}

function resolveElement(target) {
    if (!target || typeof document === 'undefined') return null;

    if (typeof Element !== 'undefined' && target instanceof Element) {
        return target;
    }

    if (typeof target === 'string') {
        var trimmed = target.trim();
        var fromQuery = document.querySelector(trimmed);
        if (fromQuery) return fromQuery;

        if (trimmed.charAt(0) === '#') {
            return document.getElementById(trimmed.slice(1));
        }

        return document.getElementById(trimmed);
    }

    return null;
}

function getViewportWidth() {
    if (typeof window === 'undefined' || typeof document === 'undefined') {
        return 0;
    }
    return window.innerWidth || document.documentElement.clientWidth || (document.body ? document.body.clientWidth : 0);
}

function enrichLayoutWithDocumentMetrics(layout) {
    if (!layout || typeof layout !== 'object') return layout;

    if (typeof window === 'undefined') {
        return Object.assign({}, layout);
    }

    var normalized = Object.assign({}, layout);
    var scrollX = window.scrollX || window.pageXOffset || 0;
    var scrollY = window.scrollY || window.pageYOffset || 0;

    if (normalized.documentLeft === undefined && normalized.left !== undefined) {
        var left = coerceNumber(normalized.left);
        if (left !== undefined) normalized.documentLeft = left + scrollX;
    }

    if (normalized.documentTop === undefined && normalized.top !== undefined) {
        var top = coerceNumber(normalized.top);
        if (top !== undefined) normalized.documentTop = top + scrollY;
    }

    if (normalized.documentWidth === undefined && normalized.width !== undefined) {
        var width = coerceNumber(normalized.width);
        if (width !== undefined) normalized.documentWidth = width;
    }

    if (normalized.documentHeight === undefined && normalized.height !== undefined) {
        var height = coerceNumber(normalized.height);
        if (height !== undefined) normalized.documentHeight = height;
    }

    return normalized;
}

function buildInlineLayoutFromElement(target, overrides) {
    if (typeof document === 'undefined') {
        throw new Error('Document is not available to compute inline layout.');
    }

    var element = resolveElement(target);
    if (!element) {
        throw new Error('Unable to find element for inline layout.');
    }

    var rect = element.getBoundingClientRect();
    var scrollX = window.scrollX || window.pageXOffset || 0;
    var scrollY = window.scrollY || window.pageYOffset || 0;
    var viewportWidth = getViewportWidth();

    var layout = Object.assign({}, overrides || {});

    if (layout.top === undefined) layout.top = rect.top;
    if (layout.left === undefined) layout.left = rect.left;
    if (layout.leading === undefined) layout.leading = rect.left;
    if (layout.trailing === undefined) {
        layout.trailing = Math.max(0, viewportWidth - (rect.left + rect.width));
    }
    if (layout.width === undefined) layout.width = rect.width;
    if (layout.height === undefined) layout.height = rect.height;
    if (layout.attachToScrollView === undefined && layout.scrollAttachment === undefined) {
        layout.attachToScrollView = true;
    }

    if (layout.documentLeft === undefined) layout.documentLeft = rect.left + scrollX;
    if (layout.documentTop === undefined) layout.documentTop = rect.top + scrollY;
    if (layout.documentWidth === undefined) layout.documentWidth = rect.width;
    if (layout.documentHeight === undefined) layout.documentHeight = rect.height;

    delete layout.element;
    delete layout.elementId;
    delete layout.targetElement;
    delete layout.selector;

    return layout;
}

function prepareInlineLayout(layoutOptions) {
    if (!layoutOptions || typeof layoutOptions !== 'object') {
        return layoutOptions;
    }

    var base = Object.assign({}, layoutOptions);
    var target = base.targetElement || base.element || base.elementId || base.selector;
    if (target) {
        return buildInlineLayoutFromElement(target, base);
    }

    if (typeof window === 'undefined') {
        return base;
    }

    return enrichLayoutWithDocumentMetrics(base);
}

function prepareInlineOptions(options) {
    if (!options || typeof options !== 'object') {
        return options;
    }

    var normalized = Object.assign({}, options);
    if (options.layout) {
        normalized.layout = prepareInlineLayout(options.layout);
    } else {
        var inlineKeys = ['top', 'left', 'leading', 'trailing', 'height', 'width', 'documentTop', 'documentLeft', 'documentWidth', 'documentHeight', 'attachToScrollView', 'scrollAttachment'];
        var hasInlineKeys = inlineKeys.some(function(key) {
            return Object.prototype.hasOwnProperty.call(options, key);
        });

        if (hasInlineKeys) {
            var slice = {};
            inlineKeys.forEach(function(key) {
                if (options[key] !== undefined) {
                    slice[key] = options[key];
                }
            });

            var enriched = prepareInlineLayout(slice);
            Object.keys(enriched).forEach(function(key) {
                normalized[key] = enriched[key];
            });
        }
    }

    return normalized;
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

Storyteller.showStoriesRowView = function(options, successCallback, errorCallback) {
    if (typeof options === 'function') {
        errorCallback = successCallback;
        successCallback = options;
        options = null;
    }

    if (options && typeof options !== 'object') {
        const err = 'Options must be an object when provided.';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }

    const args = options ? [options] : [];
    return execPromise('showStoriesRowView', args, successCallback, errorCallback);
};

Storyteller.showStoriesRowInline = function(options, successCallback, errorCallback) {
    if (!options || typeof options !== 'object') {
        const err = 'Options object with at least one category is required.';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }

    var preparedOptions = prepareInlineOptions(options);
    return execPromise('showStoriesRowInline', [preparedOptions], successCallback, errorCallback);
};

Storyteller.updateStoriesRowInlineLayout = function(layoutOptions, successCallback, errorCallback) {
    if (!layoutOptions || typeof layoutOptions !== 'object') {
        const err = 'Layout options object is required.';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }

    var preparedLayout = prepareInlineLayout(layoutOptions);
    return execPromise('updateStoriesRowInlineLayout', [preparedLayout], successCallback, errorCallback);
};

Storyteller.removeStoriesRowInline = function(successCallback, errorCallback) {
    return execPromise('removeStoriesRowInline', [], successCallback, errorCallback);
};

// Trivia quiz events (client-side only, no server)
// Usage:
//   Storyteller.setTriviaEventListener(function (event) { ... });
// "event" is an object like:
//   {
//     eventType: 'TriviaQuizQuestionAnswered' | 'TriviaQuizCompleted',
//     userId: string,
//     quizId: string,
//     quizTitle: string,
//     questionId?: string,
//     answerId?: string,
//     score?: number,
//     storyId?: string,
//     pageId?: string
//   }

var _triviaEventListener = null;

Storyteller.setTriviaEventListener = function(callback, errorCallback) {
    if (typeof callback !== 'function') {
        var err = 'Callback function is required';
        if (typeof errorCallback === 'function') errorCallback(err);
        return Promise.reject(err);
    }

    _triviaEventListener = callback;

    // Register with native side. The success callback will be invoked
    // every time the native plugin pushes an event using keepCallback.
    return execPromise('setTriviaEventListener', [], function(event) {
        if (typeof _triviaEventListener === 'function') {
            try {
                _triviaEventListener(event);
            } catch (e) {
                console.error('Error in trivia event listener', e);
            }
        }
    }, errorCallback);
};


// COM ESTE CÓDIGO DÁ ERROS A GERAR A BUILD
/*
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
*/

module.exports = Storyteller;

Storyteller.buildInlineLayoutFromElement = buildInlineLayoutFromElement;