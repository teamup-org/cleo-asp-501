# frozen_string_literal: true

class CreateSectionAttributes < ActiveRecord::Migration[7.2]
  def change
    create_table :section_attributes do |t|
      t.text :attribute_name  # Renamed to avoid conflicts with Ruby
      t.integer :section_number, null: false  # FK to sections.section_number
      t.integer :course_id, null: false  # FK to sections.course_id
      t.integer :attribute_id, null: false  # Unique identifier per section

      t.timestamps
    end

    # Ensure uniqueness: Each section (section_number, course_id) can have multiple attributes
    add_index :section_attributes, %i[section_number course_id attribute_id], unique: true

    # Composite Foreign Key: Ensuring (section_number, course_id) in section_attributes exists in sections
    add_foreign_key :section_attributes, :sections, column: %i[section_number course_id], primary_key: %i[section_number course_id]
  end
end
