class WineSizeSeeder
  WINE_SIZES = [
    { name: 'Bottle (750ml)',      size: :xl, sequence: 1 },
    { name: 'Half Bottle (375ml)', size: :lg, sequence: 2 },
    { name: 'Carafe (500ml)',      size: :lg, sequence: 3 },
    { name: 'Large Glass (250ml)', size: :md, sequence: 4 },
    { name: 'Glass (175ml)',       size: :md, sequence: 5 },
  ].freeze

  # Ensure canonical wine Size records exist for the given restaurant.
  # Idempotent — skips sizes that already exist by name.
  def self.seed!(restaurant)
    return unless restaurant

    WINE_SIZES.each do |attrs|
      restaurant.sizes.find_or_create_by!(name: attrs[:name], category: 'wine') do |s|
        s.size     = attrs[:size]
        s.status   = :active
        s.sequence = attrs[:sequence]
      end
    end
  end

  # Map from GPT size key to canonical wine size name
  SIZE_KEY_TO_NAME = {
    'bottle' => 'Bottle (750ml)',
    'half_bottle' => 'Half Bottle (375ml)',
    'carafe' => 'Carafe (500ml)',
    'large_glass' => 'Large Glass (250ml)',
    'glass' => 'Glass (175ml)',
  }.freeze

  def self.size_name_for_key(key)
    SIZE_KEY_TO_NAME[key.to_s]
  end
end
