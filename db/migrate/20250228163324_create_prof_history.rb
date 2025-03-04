# frozen_string_literal: true

class CreateProfHistory < ActiveRecord::Migration[7.2]
  def change
    create_table :prof_histories do |t|
      t.integer :course_id, null: false  # FK to COURSE
      t.string :teacher_name
      t.decimal :average_gpa, precision: 4, scale: 3
      t.string :semester, null: false

      t.timestamps
    end

    add_index :prof_histories, %i[course_id teacher_name semester], unique: true
    add_foreign_key :prof_histories, :courses, column: :course_id
  end
end
