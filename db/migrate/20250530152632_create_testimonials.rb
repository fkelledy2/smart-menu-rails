class CreateTestimonials < ActiveRecord::Migration[7.1]
  def change
    create_table :testimonials do |t|
      t.integer :sequence
      t.integer :status
      t.string :testimonial
      t.references :user, null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
