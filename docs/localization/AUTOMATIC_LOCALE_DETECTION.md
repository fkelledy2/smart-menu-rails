# Automatic Locale Detection

## Overview

The Smart Menu application automatically detects and uses the user's preferred language based on their browser settings. An optional URL parameter is available for testing and manual override.

## How It Works

### Browser Language Detection

The application uses the `Accept-Language` HTTP header sent by the browser to determine the user's preferred language:

```ruby
def switch_locale(&)
  # Automatic locale detection based on browser's Accept-Language header
  requested_locale = nil
  
  # Extract locale from Accept-Language header
  if request.env['HTTP_ACCEPT_LANGUAGE'].present?
    accept_language = request.env['HTTP_ACCEPT_LANGUAGE']
    # Extract the first two-letter language code
    requested_locale = accept_language.scan(/^[a-z]{2}/).first
  end

  # Validate locale is supported
  if requested_locale && I18n.available_locales.map(&:to_s).include?(requested_locale)
    @locale = requested_locale.to_sym
  else
    # Fall back to default locale for unsupported languages
    @locale = I18n.default_locale
  end
  
  I18n.with_locale(@locale, &)
end
```

## Supported Languages

- **English (en)** - Default language
- **Italian (it)** - Full localization support

## User Experience

### For Italian Users
- Browser set to Italian → Application displays in Italian ✅
- No configuration needed
- All text, dates, and numbers formatted for Italian locale

### For English Users  
- Browser set to English → Application displays in English ✅
- Default language for unsupported browser languages

### For Other Language Users
- Browser set to any other language → Falls back to English
- Graceful degradation ensures application remains usable

## Manual Override (Testing/Development)

You can manually override the locale using a URL parameter:

```
http://localhost:3000/restaurants/1/edit?section=staff&locale=it
```

This will:
- Display the page in Italian regardless of browser language
- Store the choice in session (persists across page refreshes)
- Apply to all subsequent pages until you explicitly change it

To switch back to English:
```
http://localhost:3000/restaurants/1/edit?section=staff&locale=en
```

To clear the override and return to automatic detection:
- Clear your browser session/cookies, or
- Close and reopen the browser

**Note**: This override is intended for testing and development. Regular users should rely on automatic browser language detection.

## Changing Language

Users can change the application language by updating their browser's language preferences:

### Chrome
1. Settings → Languages
2. Add or reorder languages
3. Refresh the application

### Firefox
1. Settings → General → Language
2. Choose or add preferred languages
3. Refresh the application

### Safari
1. System Preferences → Language & Region
2. Preferred Languages
3. Refresh the application

## Technical Details

### Accept-Language Header Format

The `Accept-Language` header typically looks like:
```
Accept-Language: it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7
```

The application extracts the first two-letter code (`it` in this example).

### Locale Resolution Order

1. **URL Parameter** - Explicit override via `?locale=it` (optional, for testing)
2. **Session Storage** - Remembers URL parameter choice across requests
3. **Browser Language** - Primary method from Accept-Language header
4. **Default Locale** - Falls back to English if browser language not supported

### Clean URLs by Default

For normal users:
- ✅ Clean URLs without language parameters
- ✅ Automatic language detection on every request
- ✅ No need for user configuration
- ✅ Respects browser's language settings
- ✅ Dynamic switching when browser language changes

For testing/development:
- ✅ Optional `?locale=` parameter to override browser language
- ✅ Session persistence remembers the override
- ✅ Easy to test different localizations

## Adding New Languages

To add support for a new language:

1. **Add locale files**:
   ```
   config/locales/restaurants_sections.[language_code].yml
   config/locales/restaurants.[language_code].yml
   ```

2. **Update application.rb**:
   ```ruby
   config.i18n.available_locales = [:en, :it, :new_language]
   ```

3. **Translate all keys** in the locale files

4. The application will automatically detect and use the new language based on browser settings

## Benefits

✅ **Zero Configuration** - Works automatically based on browser settings  
✅ **User Privacy** - No tracking or storage of language preferences  
✅ **Clean URLs** - No language parameters in URLs  
✅ **Dynamic** - Updates immediately when browser language changes  
✅ **Fallback Support** - Gracefully handles unsupported languages  
✅ **Standard Compliance** - Uses HTTP Accept-Language header standard  

## Testing

### Method 1: URL Parameter (Quick Testing)

**Test Italian Localization:**
1. Visit with locale parameter:
   ```
   http://localhost:3000/restaurants/1/edit?section=staff&locale=it
   ```
2. Verify Italian text throughout the page
3. Navigate to other sections - they remain in Italian
4. Hard refresh - still Italian (session persistence)

**Test English:**
```
http://localhost:3000/restaurants/1/edit?section=staff&locale=en
```

**Reset to automatic:**
- Clear session/cookies or close browser

### Method 2: Browser Language (Production Behavior)

**Test Italian Localization:**

1. **Change browser language to Italian**:
   - Chrome: chrome://settings/languages
   - Firefox: about:preferences#general
   - Safari: System Preferences → Language & Region

2. **Visit application** (without locale parameter):
   ```
   http://localhost:3000/restaurants/1/edit
   ```

3. **Verify Italian text**:
   - Navigation labels in Italian
   - Form fields in Italian
   - Buttons and messages in Italian

**Test English Fallback:**

1. **Change browser language to English**
2. **Visit application**
3. **Verify English text throughout**

**Test Unsupported Language:**

1. **Change browser language to unsupported language** (e.g., French, German)
2. **Visit application**
3. **Verify it falls back to English**

## Implementation Files

- **Locale Detection**: `app/controllers/application_controller.rb` (switch_locale method)
- **English Translations**: `config/locales/restaurants_sections.en.yml`
- **Italian Translations**: `config/locales/restaurants_sections.it.yml`
- **Configuration**: `config/application.rb`

## Future Enhancements

If you need more advanced locale management in the future, you could add:

1. **User Profile Language Setting** - Override browser language for logged-in users
2. **Manual Language Switcher** - UI dropdown for language selection
3. **Persistent Preference** - Store language choice in database or cookie
4. **URL-Based Locales** - Support `/en/restaurants` or `/it/restaurants` style URLs

For now, the automatic browser-based detection provides the simplest and most user-friendly experience.
