class Track < ApplicationRecord
  belongs_to :restaurant

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }

  def trackNameToCamelCase
    name.delete(' ').gsub(/[^\w\s]/, '')
  end

  def sequenceImage
      "https://fakeimg.pl/128x128/ffffff/000?text="+sequence.to_s
  end
end
