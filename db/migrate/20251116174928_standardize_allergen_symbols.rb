class StandardizeAllergenSymbols < ActiveRecord::Migration[7.2]
  # Mapping of common allergen names to standardized 1-2 character codes
  # Based on EU 14 major allergens and common variations
  SYMBOL_MAP = {
    # Gluten/Cereals
    'gluten' => 'G',
    'wheat' => 'G',
    'cereals containing gluten' => 'G',
    'cereals' => 'G',
    'barley' => 'G',
    'rye' => 'G',
    'oats' => 'G',
    
    # Crustaceans
    'crustaceans' => 'CR',
    'crustacean' => 'CR',
    'shellfish' => 'CR',
    'crab' => 'CR',
    'lobster' => 'CR',
    'prawns' => 'CR',
    'shrimp' => 'CR',
    
    # Eggs
    'eggs' => 'E',
    'egg' => 'E',
    
    # Fish
    'fish' => 'F',
    
    # Peanuts
    'peanuts' => 'P',
    'peanut' => 'P',
    'groundnuts' => 'P',
    'groundnut' => 'P',
    
    # Soy
    'soy' => 'SO',
    'soya' => 'SO',
    'soybeans' => 'SO',
    'soybean' => 'SO',
    
    # Milk/Dairy
    'milk' => 'M',
    'dairy' => 'M',
    'lactose' => 'M',
    'cream' => 'M',
    'butter' => 'M',
    'cheese' => 'M',
    
    # Tree Nuts
    'tree nuts' => 'N',
    'nuts' => 'N',
    'almonds' => 'N',
    'almond' => 'N',
    'hazelnuts' => 'N',
    'hazelnut' => 'N',
    'walnuts' => 'N',
    'walnut' => 'N',
    'cashews' => 'N',
    'cashew' => 'N',
    'pecans' => 'N',
    'pecan' => 'N',
    'pistachios' => 'N',
    'pistachio' => 'N',
    'macadamia' => 'N',
    
    # Celery
    'celery' => 'CL',
    'celeriac' => 'CL',
    
    # Mustard
    'mustard' => 'MU',
    
    # Sesame
    'sesame' => 'SE',
    'sesame seeds' => 'SE',
    
    # Sulphites/Sulfites
    'sulphites' => 'SU',
    'sulphite' => 'SU',
    'sulfites' => 'SU',
    'sulfite' => 'SU',
    'sulphur dioxide' => 'SU',
    'sulfur dioxide' => 'SU',
    
    # Lupin
    'lupin' => 'LU',
    'lupine' => 'LU',
    
    # Molluscs
    'molluscs' => 'MO',
    'mollusc' => 'MO',
    'mollusks' => 'MO',
    'mollusk' => 'MO',
    'oyster' => 'MO',
    'oysters' => 'MO',
    'mussels' => 'MO',
    'mussel' => 'MO',
    'clams' => 'MO',
    'clam' => 'MO',
    'squid' => 'MO',
    'octopus' => 'MO',
  }.freeze

  def up
    say "Standardizing allergen symbols to 1-2 character codes..."
    
    updated_count = 0
    generated_count = 0
    
    Allergyn.find_each do |allergyn|
      # Normalize the name for matching
      normalized_name = allergyn.name.to_s.downcase.strip
      
      # Try to find a match in our symbol map
      new_symbol = SYMBOL_MAP[normalized_name]
      
      if new_symbol
        # Found a standard mapping
        if allergyn.symbol != new_symbol
          say "  Updating '#{allergyn.name}' from '#{allergyn.symbol}' to '#{new_symbol}'", :subitem
          allergyn.update_column(:symbol, new_symbol)
          updated_count += 1
        end
      else
        # No standard mapping found - generate from first 1-2 letters
        # Try to keep existing symbol if it's already short (1-2 chars)
        if allergyn.symbol.present? && allergyn.symbol.length <= 2
          say "  Keeping existing short symbol '#{allergyn.symbol}' for '#{allergyn.name}'", :subitem
        else
          # Generate new symbol from name
          generated_symbol = generate_symbol(allergyn.name)
          say "  Generating symbol '#{generated_symbol}' for '#{allergyn.name}'", :subitem
          allergyn.update_column(:symbol, generated_symbol)
          generated_count += 1
        end
      end
    end
    
    say "✓ Updated #{updated_count} allergens to standard codes", :green
    say "✓ Generated #{generated_count} custom codes", :green
  end

  def down
    say "Note: This migration is not reversible as original symbols were not preserved."
    say "You would need to manually restore previous symbol values if needed."
  end
  
  private
  
  def generate_symbol(name)
    # Generate a 1-2 character symbol from the name
    return 'X' if name.blank?
    
    # Remove common words and take initials
    cleaned = name.gsub(/\b(and|or|the|with)\b/i, '').strip
    words = cleaned.split(/\s+/)
    
    if words.length > 1
      # Multi-word: take first letter of first two words
      words[0..1].map { |w| w[0] }.join.upcase
    else
      # Single word: take first 1-2 letters
      name.strip[0..1].upcase
    end
  end
end
