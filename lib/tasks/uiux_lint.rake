namespace :uiux do
  desc 'Fail if legacy -2025 UI classes appear in views or JS'
  task lint: :environment do
    legacy_re = /[a-z]+-2025(?:-[a-z]+)*/
    files = Rails.root.glob('app/views/**/*.html.erb') + Rails.root.glob('app/javascript/**/*.js')
    offenders = {}
    files.each do |path|
      raw = File.read(path)
      clean = raw.gsub(/<%#.*?%>/m, '').gsub(/<!--.*?-->/m, '').gsub(%r{//.*$}, '').gsub(/^\s*#.*$/, '')
      found = clean.scan(legacy_re).uniq
      offenders[path] = found if found.any?
    end
    if offenders.any?
      msg = +"uiux:lint FAILED — found legacy -2025 classes:\n\n"
      offenders.sort_by { |p, _| p.to_s }.each do |path, matches|
        msg << "  #{Pathname(path).relative_path_from(Rails.root)}: #{matches.join(', ')}\n"
      end
      msg << "\nMigrate to Bootstrap equivalents. See docs/features/todo/2026/design/ui-ux-unified-spec.md\n"
      abort(msg)
    end
    puts 'uiux:lint passed — no legacy -2025 classes found.'
  end
end
