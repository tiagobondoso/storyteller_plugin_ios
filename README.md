# Storyteller Cordova Plugin (iOS)

This Cordova plugin exposes the Storyteller iOS SDK functionality to JavaScript.

## Installation

Install the plugin into your Cordova project (example):

```bash
cordova plugin add path/to/storyteller_plugin_ios
```

## API (JavaScript)
All methods return a Promise and also accept optional success and error callbacks for backwards compatibility.
The plugin is exposed at `cordova.plugins.storyteller` (see `plugin.xml`).

Important: all functions support both callback-style and Promise/async-await style. Prefer `await`/Promises in new code.

## Quick reference
| Method | Purpose |
| --- | --- |
| `initialize(apiKey, userId)` | Bootstraps the Storyteller SDK for the current Cordova session. |
| `showStorytellerView()` | Presents the fully native Storyteller experience fullscreen. |
| `showStoriesRowView(options)` | Shows a modal Stories Row filtered by categories/attributes. |
| `showStoriesRowInline(options)` | Renders the Stories Row inline on top of the WebView with custom layout. |
| `updateStoriesRowInlineLayout(layoutOptions)` | Moves/resizes/toggles the inline Stories Row without reloading content. |
| `removeStoriesRowInline()` | Tears down the inline Stories Row and releases native resources. |
| `openStoryById(id)` | Opens a specific Story by internal ID or external ID. |
| `setLocale(locale)` | Sets/clears the locale for Storyteller content. |
| `setUserCustomAttribute(key, value)` / `removeUserCustomAttribute(key)` | Manage custom profile attributes. |
| `addFollowedCategory(id)` / `addFollowedCategories(ids)` / `removeFollowedCategory(id)` | Manage followed categories (arrays accepted). |

### initialize(apiKey, userId)
Initialize the SDK for a user.

Usage:
```javascript
cordova.plugins.storyteller.initialize('API_KEY', 'external-user-id')
  .then(res => console.log('initialized', res))
  .catch(err => console.error('init error', err));
```
Or with callbacks:
```javascript
cordova.plugins.storyteller.initialize('API_KEY', 'user-id', function(res) { console.log(res); }, function(err) { console.error(err); });
```

### showStorytellerView()
Present the full native storyteller view.

```javascript
cordova.plugins.storyteller.showStorytellerView();
```

### showStoriesRowView(options)
Presents a native Stories Row filtered by the content attributes/categories you pass in `options`.

`options` is optional (defaults to the SDK's standard feed), but you can provide:

- `categories` / `categoryIds` / `attributeIds`: array of category or attribute identifiers used by your Storyteller CMS filters.
- `category` / `attribute`: single identifier (string) – shorthand if you only need one filter.
- `cellType`: `'round'` or `'square'` to control the tile shape.
- `displayLimit`: maximum number of tiles to request.
- `visibleTiles`: fractional number of tiles that should stay visible (e.g., `2.5`).

Example:

```javascript
await cordova.plugins.storyteller.showStoriesRowView({
  categories: ['benfica-top-row'],
  cellType: 'round',
  displayLimit: 10
});
```

The method still accepts callbacks if you prefer:

```javascript
cordova.plugins.storyteller.showStoriesRowView(
  { attribute: 'sponsored' },
  () => console.log('row shown'),
  err => console.error(err)
);
```

### showStoriesRowInline(options)
Renders the same Stories Row component directly on top of your Cordova WebView so it occupies only a slice of the screen. You **must** provide at least one category/attribute plus the layout coordinates that describe where the row should sit.

Supported filter keys are the same as `showStoriesRowView`. Layout keys (top-level or inside `options.layout`) include:

- `top` / `y`: distance in points from the top anchor (default `0`).
- `left` / `leading` / `x`: distance from the leading edge (default `0`).
- `right` / `trailing`: distance from the trailing edge (default `0`).
- `horizontalPadding`: shorthand applied to both `left` and `right` when the explicit values are missing.
- `height`: container height (default `220`).
- `useSafeArea`: `true` (default) anchors to the safe-area top; set `false` to allow the row to sit under the status bar.
- `backgroundColor`: optional hex color (`#RRGGBB` or `#RRGGBBAA`).
- `cornerRadius`: round the container corners.
- `hidden`: boolean to temporarily hide the inline row without removing it.

Example that reserves a placeholder `<div>` in HTML and positions the native row over it:

```javascript
const host = document.getElementById('stories-host');
const rect = host.getBoundingClientRect();

await cordova.plugins.storyteller.showStoriesRowInline({
  categories: ['benfica-top-row', 'benfica-singleton'],
  cellType: 'round',
  layout: {
    top: rect.top,           // relative to viewport
    left: rect.left,
    right: window.innerWidth - rect.right,
    height: rect.height,
    cornerRadius: 16,
    backgroundColor: '#0A0A0A'
  }
});

// Later (orientation change / scroll) you can tweak only the layout:
window.addEventListener('resize', async () => {
  const next = host.getBoundingClientRect();
  await cordova.plugins.storyteller.updateStoriesRowInlineLayout({
    top: next.top,
    left: next.left,
    right: window.innerWidth - next.right,
    height: next.height
  });
});
```

When you no longer need the inline row:

```javascript
await cordova.plugins.storyteller.removeStoriesRowInline();
```

## Inline Stories Row workflow
1. **Reserve space in HTML** – add an empty `div` where you want the Stories Row to appear and give it a fixed height via CSS.
2. **Initialize Storyteller** – call `initialize` (and optionally `setLocale` / custom attributes) before attempting to render.
3. **Render inline** – measure your host `div` with `getBoundingClientRect()` and pass the metrics to `showStoriesRowInline` together with the categories you want to load.
4. **Keep it aligned** – on `resize` / orientation changes, call `updateStoriesRowInlineLayout` with the new rect; you can also toggle `hidden: true` temporarily if the user scrolls past the section.
5. **Respond to taps** – the native delegate (wired inside the plugin) will automatically open stories when a tile is tapped.
6. **Clean up** – when navigating away from the page/section, call `removeStoriesRowInline` to destroy the native container.

Tip: the inline view sits on top of the WebView; ensure your HTML leaves enough vertical space (padding/margin) so underlying content doesn’t get covered.

### openStoryById(id)
Open a specific story by internal id or externalId.

```javascript
cordova.plugins.storyteller.openStoryById('story-123')
  .then(() => console.log('opened'))
  .catch(err => console.error(err));
```

### setLocale(locale)
Set the user's locale (e.g., 'pt-PT', or null to clear).

```javascript
cordova.plugins.storyteller.setLocale('pt-PT');
```

Example using async/await:

```javascript
await cordova.plugins.storyteller.setLocale('pt-PT');
```

### User customization
- setUserCustomAttribute(key, value)
- removeUserCustomAttribute(key)

```javascript
cordova.plugins.storyteller.setUserCustomAttribute('tier', 'premium');
cordova.plugins.storyteller.removeUserCustomAttribute('tier');
```

### Followed categories
- addFollowedCategory(categoryId)
- addFollowedCategories(arrayOfCategoryIds)
- removeFollowedCategory(categoryId)

```javascript
cordova.plugins.storyteller.addFollowedCategories(['cat-a', 'cat-b']);
```

## Notes
- This plugin uses the Storyteller iOS SDK; ensure the SDK and its frameworks are included in the plugin's `plugin.xml` (already configured).
- To test these functions, build and run the Cordova app on an iOS device or simulator using Xcode / `cordova emulate ios`.

## Example: full flow (async/await)

```javascript
async function runExample() {
  try {
    await cordova.plugins.storyteller.initialize('API_KEY', 'user-123');
    await cordova.plugins.storyteller.setUserCustomAttribute('tier', 'premium');
    await cordova.plugins.storyteller.addFollowedCategories(['cat-a', 'cat-b']);
    await cordova.plugins.storyteller.openStoryById('story-123');
  } catch (err) {
    console.error('Storyteller error', err);
  }
}
```

## Troubleshooting
If you get runtime errors about missing symbols, make sure the Storyteller SDK framework is present and embedded in your iOS project.

---
Generated by automation to add JS wrappers for Storyteller SDK features.