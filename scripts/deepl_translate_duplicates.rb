#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'json'
require 'net/http'
require 'uri'
require 'optparse'

ROOT = File.expand_path('..', __dir__)
LOCALES_ROOT = File.join(ROOT, 'config', 'locales')

def fetch_deepl_api_key
  key = ENV.fetch('DEEPL_API_KEY', nil)
  return key unless key.nil? || key.strip.empty?

  begin
    require File.join(ROOT, 'config', 'environment')
  rescue StandardError => e
    abort("DEEPL_API_KEY env var is required (or configure Rails credentials at deepl.api_key). Failed to load Rails environment: #{e.class}: #{e.message}")
  end

  creds = Rails.application.credentials
  key = creds.dig(:deepl, :api_key) ||
        creds.dig(:deepl, :auth_key) ||
        creds[:deepl_api_key] ||
        creds[:DEEPL_API_KEY]

  if key.nil? || key.to_s.strip.empty?
    abort('DeepL API key not found. Add it to Rails credentials (e.g. deepl: { api_key: ... }) or set DEEPL_API_KEY in the environment.')
  end

  key.to_s
end

HARD_OVERRIDES = {
  # User requested that even common tokens like Menu/Menus be translated.
  # These overrides force locale-appropriate UI terms when DeepL would keep the English word.
  'cs' => {
    'Menu' => 'Jídelní lístek',
    'Menus' => 'Jídelní lístky',
    'Menu:' => 'Menu:',
    'Restaurants' => 'Restaurace',
    'Restaurant' => 'Restaurace',
    'Actions' => 'Akce',
    'Name' => 'Název',
    'Status' => 'Stav',
    'ID' => 'ID',
    'WiFi' => 'Wi‑Fi',
    'Section' => 'Sekce',
    'Sections' => 'Sekce',
    'Total' => 'Celkem',
    'Password' => 'Heslo',
    'Role' => 'Role',
    'Reset' => 'Resetovat',
    'Admin' => 'Administrace',
    'Tag' => 'Štítek',
    'Tags' => 'Štítky',
    'Plan' => 'Plán',
    'Pro' => 'Pro',
  },
  'de' => {
    'Menu' => 'Speisekarte',
    'Menus' => 'Speisekarten',
    'Menu:' => 'Speisekarte:',
    'Restaurants' => 'Gastronomiebetriebe',
    'Restaurant' => 'Gastronomiebetrieb',
    'Actions' => 'Aktionen',
    'Name' => 'Bezeichnung',
    'Status' => 'Zustand',
    'ID' => 'Kennung',
    'WiFi' => 'WLAN',
    'Section' => 'Abschnitt',
    'Sections' => 'Abschnitte',
    'Total' => 'Gesamt',
    'Password' => 'Passwort',
    'Role' => 'Rolle',
    'Reset' => 'Zurücksetzen',
    'Admin' => 'Administration',
    'Tag' => 'Schlagwort',
    'Tags' => 'Schlagwörter',
    'Plan' => 'Tarif',
    'Pro' => 'Pro',
    'Tracks' => 'Titel',
    'Business' => 'Geschäft',
    'Starter' => 'Einsteiger',
    'Start' => 'Starten',
  },
  'es' => {
    'Menu' => 'Menú',
    'Menus' => 'Menús',
    'Menu:' => 'Menú:',
    'Restaurants' => 'Restaurantes',
    'Restaurant' => 'Restaurante',
    'Actions' => 'Acciones',
    'Name' => 'Nombre',
    'Status' => 'Estado',
    'ID' => 'ID',
    'WiFi' => 'Wi‑Fi',
    'Section' => 'Sección',
    'Sections' => 'Secciones',
    'Total' => 'Total',
    'Password' => 'Contraseña',
    'Role' => 'Rol',
    'Reset' => 'Restablecer',
    'Admin' => 'Administración',
    'Tag' => 'Etiqueta',
    'Tags' => 'Etiquetas',
    'Plan' => 'Plan',
    'Pro' => 'Pro',
  },
  'fr' => {
    'Menu' => 'Carte',
    'Menus' => 'Cartes',
    'Menu:' => 'Carte :',
    'Restaurants' => 'Établissements',
    'Restaurant' => 'Établissement',
    'Actions' => 'Actions',
    'Name' => 'Nom',
    'Status' => 'Statut',
    'ID' => 'ID',
    'WiFi' => 'Wi‑Fi',
    'Section' => 'Section',
    'Sections' => 'Sections',
    'Total' => 'Total',
    'Password' => 'Mot de passe',
    'Role' => 'Rôle',
    'Reset' => 'Réinitialiser',
    'Admin' => 'Administration',
    'Tag' => 'Étiquette',
    'Tags' => 'Étiquettes',
    'Plan' => 'Forfait',
    'Pro' => 'Pro',
  },
  'hu' => {
    'Menu' => 'Étlap',
    'Menus' => 'Étlapok',
    'Menu:' => 'Étlap:',
    'Restaurants' => 'Éttermek',
    'Restaurant' => 'Étterem',
    'Actions' => 'Műveletek',
    'Name' => 'Név',
    'Status' => 'Állapot',
    'ID' => 'Azonosító',
    'WiFi' => 'Wi‑Fi',
    'Section' => 'Szekció',
    'Sections' => 'Szekciók',
    'Total' => 'Összesen',
    'Password' => 'Jelszó',
    'Role' => 'Szerep',
    'Reset' => 'Visszaállítás',
    'Admin' => 'Adminisztráció',
    'Tag' => 'Címke',
    'Tags' => 'Címkék',
    'Plan' => 'Csomag',
    'Pro' => 'Pro',
  },
  'it' => {
    'Menu' => 'Menù',
    'Menus' => 'Menù',
    'Menu:' => 'Menù:',
    'Restaurants' => 'Ristoranti',
    'Restaurant' => 'Ristorante',
    'Actions' => 'Azioni',
    'Name' => 'Nome',
    'Status' => 'Stato',
    'ID' => 'ID',
    'WiFi' => 'Wi‑Fi',
    'Section' => 'Sezione',
    'Sections' => 'Sezioni',
    'Total' => 'Totale',
    'Password' => 'Password',
    'Role' => 'Ruolo',
    'Reset' => 'Reimposta',
    'Admin' => 'Amministrazione',
    'Tag' => 'Etichetta',
    'Tags' => 'Etichette',
    'Plan' => 'Piano',
    'Pro' => 'Pro',
    'Locale' => 'Lingua',
    'Gen Id' => 'ID Gen',
  },
  'pt' => {
    'Menu' => 'Menu',
    'Menus' => 'Menus',
    'Menu:' => 'Menu:',
    'Restaurants' => 'Restaurantes',
    'Restaurant' => 'Restaurante',
    'Actions' => 'Ações',
    'Name' => 'Nome',
    'Status' => 'Estado',
    'ID' => 'ID',
    'WiFi' => 'Wi‑Fi',
    'Section' => 'Secção',
    'Sections' => 'Secções',
    'Total' => 'Total',
    'Password' => 'Palavra-passe',
    'Role' => 'Função',
    'Reset' => 'Repor',
    'Admin' => 'Administração',
    'Tag' => 'Etiqueta',
    'Tags' => 'Etiquetas',
    'Plan' => 'Plano',
    'Pro' => 'Pro',
  },
  'pl' => {
    'Menu' => 'Menu',
    'Menus' => 'Menu',
    'Menu:' => 'Menu:',
    'Restaurants' => 'Restauracje',
    'Restaurant' => 'Restauracja',
    'Actions' => 'Działania',
    'Name' => 'Nazwa',
    'Status' => 'Status',
    'ID' => 'ID',
    'WiFi' => 'Wi‑Fi',
    'Section' => 'Sekcja',
    'Sections' => 'Sekcje',
    'Total' => 'Łącznie',
    'Password' => 'Hasło',
    'Role' => 'Rola',
    'Reset' => 'Resetuj',
    'Admin' => 'Administracja',
    'Tag' => 'Tag',
    'Tags' => 'Tagi',
    'Plan' => 'Plan',
    'Pro' => 'Pro',
  },
}.freeze

def deepl_base_url(auth_key)
  # DeepL free API keys typically end in ":fx".
  auth_key&.end_with?(':fx') ? 'https://api-free.deepl.com' : 'https://api.deepl.com'
end

DEEPL_TARGET = {
  'cs' => 'CS',
  'de' => 'DE',
  'es' => 'ES',
  'fr' => 'FR',
  'hu' => 'HU',
  'it' => 'IT',
  'pt' => 'PT-PT',
  'pl' => 'PL',
  'en_GB' => 'EN-GB',
  'en_US' => 'EN-US',
}.freeze

def load_locale_tree(path)
  data = YAML.load_file(path) || {}
  if data.is_a?(Hash) && data.size == 1
    data.values.first
  else
    data
  end
end

def get_path(obj, parts)
  cur = obj
  parts.each do |p|
    return nil if cur.nil?

    if p.match?(/\A\d+\z/)
      return nil unless cur.is_a?(Array)

      cur = cur[p.to_i]
    else
      return nil unless cur.is_a?(Hash)

      cur = cur[p]
    end
  end
  cur
end

def dump_locale_file(locale, tree)
  YAML.dump({ locale => tree })
end

def flatten(obj, prefix = [])
  out = {}
  case obj
  when Hash
    obj.each { |k, v| out.merge!(flatten(v, prefix + [k.to_s])) }
  when Array
    obj.each_with_index { |v, i| out.merge!(flatten(v, prefix + [i.to_s])) }
  else
    out[prefix.join('.')] = obj
  end
  out
end

def set_path!(obj, parts, value)
  head = parts.first
  if parts.length == 1
    if head.match?(/\A\d+\z/) && obj.is_a?(Array)
      obj[head.to_i] = value
    else
      obj[head] = value
    end
    return
  end

  nxt = parts[1]
  if head.match?(/\A\d+\z/)
    idx = head.to_i
    obj[idx] ||= (nxt.match?(/\A\d+\z/) ? [] : {})
    set_path!(obj[idx], parts[1..], value)
  else
    obj[head] ||= (nxt.match?(/\A\d+\z/) ? [] : {})
    set_path!(obj[head], parts[1..], value)
  end
end

def resource_key(file, locale)
  base = File.basename(file, '.yml')
  return 'root' if base == locale

  suffix = ".#{locale}"
  return base[0...-suffix.length] if base.end_with?(suffix)

  parts = base.split('.')
  parts.length > 1 ? parts[0...-1].join('.') : base
end

def path_for_resource(locales_root, locale, rk)
  dir = File.join(locales_root, locale)
  rk == 'root' ? File.join(dir, "#{locale}.yml") : File.join(dir, "#{rk}.#{locale}.yml")
end

def should_translate?(value)
  return false unless value.is_a?(String)

  s = value.strip
  return false if s.empty?
  return false if s.match?(%r{\Ahttps?://}i)

  true
end

def placeholder?(value)
  value.is_a?(String) && value.strip == 'replace_me'
end

def blank_placeholder?(value)
  value.is_a?(String) && value.strip.empty?
end

def deepl_translate_batch!(auth_key:, target_lang:, texts:)
  uri = URI.join(deepl_base_url(auth_key), '/v2/translate')
  req = Net::HTTP::Post.new(uri)
  req['Authorization'] = "DeepL-Auth-Key #{auth_key}"
  req.set_form_data({
    'target_lang' => target_lang,
    'source_lang' => 'EN',
    **texts.each_with_index.to_h { |t, i| ["text#{i}", t] },
  })

  # DeepL expects repeated text= params. Ruby's set_form_data doesn't support duplicates directly,
  # so we build it ourselves.
  body = "source_lang=EN&target_lang=#{URI.encode_www_form_component(target_lang)}"
  texts.each do |t|
    body << "&text=#{URI.encode_www_form_component(t)}"
  end
  req.body = body
  req['Content-Type'] = 'application/x-www-form-urlencoded'

  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
  unless res.is_a?(Net::HTTPSuccess)
    raise "DeepL error (#{res.code}): #{res.body}"
  end

  json = JSON.parse(res.body)
  translations = json.fetch('translations')
  translations.map { |t| t.fetch('text') }
end

options = {
  locales_root: LOCALES_ROOT,
  dry_run: false,
  limit: nil,
  locale: nil,
  show: false,
}

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby scripts/deepl_translate_duplicates.rb [options]'
  opts.on('--dry-run', 'Do not write files') { options[:dry_run] = true }
  opts.on('--limit N', Integer, 'Limit number of replacements per locale (debug)') { |n| options[:limit] = n }
  opts.on('--locale LOCALE', 'Only translate a single locale (e.g. cs, fr, it)') { |v| options[:locale] = v }
  opts.on('--show', 'Print each replacement as from(old) to(new)') { options[:show] = true }
end.parse!

auth_key = fetch_deepl_api_key

# Locales
locales = Dir.children(options[:locales_root]).select { |d| File.directory?(File.join(options[:locales_root], d)) }.sort
abort('Missing en locale folder') unless locales.include?('en')

if options[:locale]
  wanted = options[:locale].to_s
  abort("Locale '#{wanted}' does not exist under #{options[:locales_root]}") unless locales.include?(wanted)
  locales = [wanted]

  if wanted != 'en' && wanted != 'en_US' && wanted != 'en_GB' && !DEEPL_TARGET.key?(wanted)
    abort("Locale '#{wanted}' is not configured in DEEPL_TARGET. Add a mapping (e.g. 'pl' => 'PL') to scripts/deepl_translate_duplicates.rb")
  end
end

# Canonical resources from en
resources = Dir.glob(File.join(options[:locales_root], 'en', '*.yml')).to_set { |p| resource_key(p, 'en') }

# Load en flattened per resource
flat_en = {}
resources.each do |rk|
  flat_en[rk] = flatten(load_locale_tree(path_for_resource(options[:locales_root], 'en', rk)))
end

# Collect duplicates
# duplicates[locale][resource] = [ [key_path, english_string], ... ]
duplicates = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } }

locales.each do |loc|
  next if loc == 'en'

  resources.each do |rk|
    path = path_for_resource(options[:locales_root], loc, rk)
    tree = load_locale_tree(path)
    flat = flatten(tree)

    flat.each do |k, v|
      ev = flat_en[rk][k]
      next unless ev.is_a?(String)
      next unless v.is_a?(String)

      eligible = false
      eligible ||= should_translate?(v) && v == ev
      eligible ||= placeholder?(v)
      eligible ||= blank_placeholder?(v) && !ev.strip.empty?
      next unless eligible

      duplicates[loc][rk] << [k, ev]
    end
  end

  # Translate and apply
  next if loc == 'en'
  next if %w[en_US en_GB].include?(loc)

  target = DEEPL_TARGET[loc]
  next unless target

  entries = duplicates[loc].values.flatten(1)
  next if entries.empty?

  # Unique by english string for batching
  unique_texts = entries.map { |(_k, en_text)| en_text }.uniq
  replacements = {}

  # Apply hard overrides first.
  (HARD_OVERRIDES[loc] || {}).each do |src, dst|
    replacements[src] = dst
  end

  # DeepL batch in chunks
  unique_texts
    .reject { |t| replacements.key?(t) }
    .each_slice(50) do |slice|
      translated = deepl_translate_batch!(auth_key: auth_key, target_lang: target, texts: slice)
      slice.zip(translated).each do |src, dst|
        replacements[src] = dst
      end
  end

  applied = 0

  duplicates[loc].each do |rk, pairs|
    path = path_for_resource(options[:locales_root], loc, rk)
    tree = load_locale_tree(path)

    pairs.each do |key_path, en_text|
      next if options[:limit] && applied >= options[:limit]

      new_val = replacements[en_text]
      next if new_val.nil? || new_val.strip.empty?

      parts = key_path.split('.')
      old_val = get_path(tree, parts)

      if old_val.is_a?(String) && old_val == new_val
        puts "#{loc}.#{rk}.#{key_path}: from(#{old_val.inspect}) to(#{new_val.inspect}) (unchanged; skipped)" if options[:show]
        next
      end

      puts "#{loc}.#{rk}.#{key_path}: from(#{old_val.inspect}) to(#{new_val.inspect})" if options[:show]
      set_path!(tree, parts, new_val)
      applied += 1
    end

    next if options[:dry_run]

    File.write(path, dump_locale_file(loc, tree))
  end

  puts "#{loc}: replaced #{applied} strings via DeepL (target=#{target})"
end

puts(options[:dry_run] ? 'Done (dry-run).' : 'Done.')
