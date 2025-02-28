# frozen_string_literal: true

class CreateSection < ActiveRecord::Migration[7.2]
  def change
    create_table :sections, primary_key: :section_number do |t|
      t.integer :start_time
      t.integer :end_time
      t.integer :course_id, null: false  # FK to courses.id

      t.timestamps
    end

    add_index :sections, %i[section_number course_id], unique: true
    add_foreign_key :sections, :courses, column: :course_id
  end
end
