module OcrMenuImportsTestHelper
  # Creates a sample PDF file for testing
  def create_sample_pdf(file_name = 'sample_menu.pdf')
    pdf = Tempfile.new([file_name, '.pdf'])
    pdf.write('Sample PDF content')
    pdf.rewind

    # Create an Active Storage blob
    blob = ActiveStorage::Blob.create_and_upload!(
      io: pdf,
      filename: file_name,
      content_type: 'application/pdf',
    )

    # Return the blob's signed_id for attaching to models
    blob.signed_id
  end

  # Sample menu data structure that would come from the OCR service
  def sample_menu_data
    {
      sections: [
        {
          name: 'Starters',
          description: 'Delicious starters to begin your meal',
          items: [
            {
              name: 'Bruschetta',
              description: 'Toasted bread with tomatoes, garlic and basil',
              price: 8.99,
              allergens: ['gluten'],
              is_vegetarian: true,
              is_vegan: false,
              is_gluten_free: false,
            },
            {
              name: 'Calamari',
              description: 'Fried squid with marinara sauce',
              price: 12.99,
              allergens: %w[shellfish gluten],
              is_vegetarian: false,
              is_vegan: false,
              is_gluten_free: false,
            },
          ],
        },
        {
          name: 'Mains',
          description: 'Hearty main courses',
          items: [
            {
              name: 'Spaghetti Carbonara',
              description: 'Classic pasta with eggs, cheese, and pancetta',
              price: 16.99,
              allergens: %w[gluten dairy eggs],
              dietary_restrictions: [],
            },
          ],
        },
      ],
    }.with_indifferent_access
  end
end
