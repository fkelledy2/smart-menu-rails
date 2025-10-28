# Hero Images Seed Data
# These are the same images used as fallback in hero_carousel.js
# All images are from Pexels and are pre-approved for display

puts "Seeding hero images..."

hero_images_data = [
  {
    image_url: 'https://images.pexels.com/photos/1581384/pexels-photo-1581384.jpeg?auto=compress&cs=tinysrgb&w=1920',
    alt_text: 'Busy restaurant interior with diners enjoying meals',
    sequence: 1,
    status: :approved,
    source_url: 'https://www.pexels.com/photo/people-sitting-inside-well-lit-room-1581384/'
  },
  {
    image_url: 'https://images.pexels.com/photos/696218/pexels-photo-696218.jpeg?auto=compress&cs=tinysrgb&w=1920',
    alt_text: 'Group of friends dining together at restaurant',
    sequence: 2,
    status: :approved,
    source_url: 'https://www.pexels.com/photo/people-having-a-toast-696218/'
  },
  {
    image_url: 'https://images.pexels.com/photos/941861/pexels-photo-941861.jpeg?auto=compress&cs=tinysrgb&w=1920',
    alt_text: 'Restaurant patrons enjoying dinner in warm atmosphere',
    sequence: 3,
    status: :approved,
    source_url: 'https://www.pexels.com/photo/people-having-dinner-together-941861/'
  },
  {
    image_url: 'https://images.pexels.com/photos/67468/pexels-photo-67468.jpeg?auto=compress&cs=tinysrgb&w=1920',
    alt_text: 'Elegant restaurant interior with diners',
    sequence: 4,
    status: :approved,
    source_url: 'https://www.pexels.com/photo/restaurant-people-eating-meals-67468/'
  },
  {
    image_url: 'https://images.pexels.com/photos/3201921/pexels-photo-3201921.jpeg?auto=compress&cs=tinysrgb&w=1920',
    alt_text: 'Modern restaurant with customers dining',
    sequence: 5,
    status: :approved,
    source_url: 'https://www.pexels.com/photo/people-inside-a-restaurant-3201921/'
  },
  {
    image_url: 'https://images.pexels.com/photos/262978/pexels-photo-262978.jpeg?auto=compress&cs=tinysrgb&w=1920',
    alt_text: 'Restaurant scene with people enjoying food',
    sequence: 6,
    status: :approved,
    source_url: 'https://www.pexels.com/photo/people-at-the-restaurant-262978/'
  },
  {
    image_url: 'https://images.pexels.com/photos/1307698/pexels-photo-1307698.jpeg?auto=compress&cs=tinysrgb&w=1920',
    alt_text: 'Lively restaurant atmosphere with multiple diners',
    sequence: 7,
    status: :approved,
    source_url: 'https://www.pexels.com/photo/people-inside-restaurant-1307698/'
  },
  {
    image_url: 'https://images.pexels.com/photos/2788792/pexels-photo-2788792.jpeg?auto=compress&cs=tinysrgb&w=1920',
    alt_text: 'Restaurant patrons in casual dining setting',
    sequence: 8,
    status: :approved,
    source_url: 'https://www.pexels.com/photo/people-sitting-on-chair-inside-building-2788792/'
  },
  {
    image_url: 'https://images.pexels.com/photos/1126728/pexels-photo-1126728.jpeg?auto=compress&cs=tinysrgb&w=1920',
    alt_text: 'Group dining experience in restaurant',
    sequence: 9,
    status: :approved,
    source_url: 'https://www.pexels.com/photo/people-eating-inside-of-cafeteria-during-daytime-1126728/'
  },
  {
    image_url: 'https://images.pexels.com/photos/2788799/pexels-photo-2788799.jpeg?auto=compress&cs=tinysrgb&w=1920',
    alt_text: 'Restaurant interior with customers at tables',
    sequence: 10,
    status: :approved,
    source_url: 'https://www.pexels.com/photo/people-sitting-on-chair-inside-building-2788799/'
  }
]

hero_images_data.each do |image_data|
  hero_image = HeroImage.find_or_initialize_by(image_url: image_data[:image_url])
  
  if hero_image.new_record?
    hero_image.assign_attributes(image_data)
    if hero_image.save
      puts "  ✓ Created hero image: #{image_data[:alt_text]} (sequence: #{image_data[:sequence]})"
    else
      puts "  ✗ Failed to create hero image: #{hero_image.errors.full_messages.join(', ')}"
    end
  else
    puts "  - Hero image already exists: #{image_data[:alt_text]}"
  end
end

puts "Hero images seeding complete!"
puts "Total hero images: #{HeroImage.count}"
puts "Approved hero images: #{HeroImage.approved.count}"
