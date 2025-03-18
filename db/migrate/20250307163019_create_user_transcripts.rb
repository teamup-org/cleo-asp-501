class CreateUserTranscripts < ActiveRecord::Migration[7.2]
  def change
    create_table :user_transcripts do |t|
      t.string :uin
      t.binary :transcript

      t.timestamps
    end

    add_foreign_key :user_transcripts, :students, column: :uin, primary_key: "google_id"
  end
end
