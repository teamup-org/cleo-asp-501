class CreateTemporaryTranscriptCourses < ActiveRecord::Migration[7.2]
  def change
    create_table :temporary_transcript_courses do |t|
      t.string :session_id, null: false
      t.string :semester
      t.string :ccode
      t.string :cnumber
      t.string :cname
      t.float :credit_hours
      t.string :grade
      t.timestamps
    end

    add_index :temporary_transcript_courses, :session_id
  end
end 