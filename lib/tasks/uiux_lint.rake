namespace :uiux do
  desc 'Fail if legacy 2025-only UI classes are present in *_2025.html.erb views'
  task lint: :environment do
    patterns = [
      /\bbtn-2025\b/,
      /\bbadge-2025\b/
    ]

    files = Dir.glob(Rails.root.join('app/views/**/*_2025.html.erb'))
    offenders = {}

    files.each do |path|
      content = File.read(path)

      # Ignore ERB and HTML comments so usage examples don't trip the lint.
      content = content.gsub(/<%#.*?%>/m, '')
      content = content.gsub(/<!--.*?-->/m, '')

      # Ignore Ruby comment lines (e.g. usage examples inside `<% %>` blocks).
      content = content.gsub(/^\s*#.*$/, '')
      matches = patterns.filter { |re| content.match?(re) }.map(&:source)
      next if matches.empty?

      offenders[path] = matches
    end

    if offenders.any?
      message = +"uiux:lint failed. Found legacy 2025-only UI classes in *_2025 views:\n\n"
      offenders.sort.each do |path, matches|
        message << "- #{Pathname(path).relative_path_from(Rails.root)}: #{matches.join(', ')}\n"
      end
      message << "\nPlease migrate these to Bootstrap classes (btn btn-*, badge text-bg-*, etc.).\n"
      abort(message)
    end

    puts 'uiux:lint passed.'
  end
end
