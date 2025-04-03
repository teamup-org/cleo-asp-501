# frozen_string_literal: true

class Student < ApplicationRecord
  self.primary_key = :google_id

  enum :enrol_semester, %i[fall spring], prefix: :enrol
  enum :grad_semester, %i[fall spring], prefix: :grad

  # Validations
  validates :google_id, presence: true, uniqueness: true, numericality: { only_integer: true }

  # Validations for name
  validates :first_name, :last_name, presence: true, length: { maximum: 255 }
  validates :first_name, :last_name,
            format: { with: /\A[a-zA-Z]+\z/, message: 'only characters are allowed. No whitespaces or punctuations.' }

  # Validations for email
  validates :email, presence: true, length: { maximum: 255 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Validations for enrolment, graduation semester and year
  validates :enrol_year, :grad_year, presence: true, numericality: { only_integer: true }
  validates :grad_year, comparison: { greater_than: :enrol_year }
  validates :enrol_semester, :grad_semester, presence: true

  # Student courses association
  # has_and_belongs_to_many :courses
  has_one :student_info, foreign_key: 'uin', primary_key: 'google_id', dependent: :destroy #NEW
  accepts_nested_attributes_for :student_info #NEW

  has_many :student_courses, dependent: :destroy
  has_many :courses, through: :student_courses
  has_many :user_transcripts, primary_key: "google_id", foreign_key: :uin
  has_many :rec_courses, primary_key: "google_id", foreign_key: :uin
  #has_one :student_info, primary_key: "google_id", foreign_key: :uin

  belongs_to :major

  belongs_to :track, optional: true

  belongs_to :emphasis, optional: true
  # belongs_to :emphasis, foreign_key: :emphases_id, optional: true

  after_create :assign_default_courses

  def total_credits_completed
    courses.sum(:credit_hours)
  end

  private

  def assign_default_courses

    # Define common courses for all students
    common_courses = [
      { code: "CSCE", number: 181, semester: "FALL", offset: 2 },
      { code: "CSCE", number: 120, semester: "FALL", offset: 2 },
      { code: "CSCE", number: 222, semester: "FALL", offset: 2 },
      { code: "CSCE", number: 221, semester: "SPRING", offset: 3 },
      { code: "CSCE", number: 312, semester: "SPRING", offset: 3 },
      { code: "CSCE", number: 314, semester: "SPRING", offset: 3 },
      { code: "CSCE", number: 313, semester: "FALL", offset: 4 },
      { code: "CSCE", number: 331, semester: "FALL", offset: 4 },
      { code: "CSCE", number: 411, semester: "SPRING", offset: 5 },
      { code: "CSCE", number: 481, semester: "SPRING", offset: 5 },
      { code: "CSCE", number: 399, semester: "SPRING", offset: 5 },
      { code: "CSCE", number: 482, semester: "SPRING", offset: 7 },
      { code: "ENGR", number: 102, semester: "FALL", offset: 0 },
      { code: "MATH", number: 151, semester: "FALL", offset: 0 },
      { code: "CHEM", number: 107, semester: "FALL", offset: 0 },
      { code: "ENGL", number: 104, semester: "FALL", offset: 0 },
      { code: "ENGR", number: 216, semester: "SPRING", offset: 1 },
      { code: "PHYS", number: 206, semester: "SPRING", offset: 1 },
      { code: "MATH", number: 152, semester: "SPRING", offset: 1 },
      { code: "ENGL", number: 210, semester: "SPRING", offset: 1 },
      { code: "MATH", number: 304, semester: "FALL", offset: 2 },
      { code: "STAT", number: 211, semester: "FALL", offset: 4 },
      { code: "MATH", number: 251, semester: "SPRING", offset: 5 },
      { code: "CSCE", number: 410, semester: "SPRING", offset: 5 },
      { code: "CSCE", number: 421, semester: "SPRING", offset: 5 },
      { code: "CSCE", number: 412, semester: "FALL", offset: 4 },
      { code: "CSCE", number: 431, semester: "FALL", offset: 6 },
      { code: "CSCE", number: 420, semester: "FALL", offset: 6 },
      { code: "CSCE", number: 430, semester: "SPRING", offset: 7 }
    ]

    # Define emphasis-specific courses
    emphasis_courses = {
      "Mathematics" => [
        { code: "MATH", number: 308, semester: "SPRING", offset: 3 },
        { code: "MATH", number: 439, semester: "FALL", offset: 4 },
        { code: "MATH", number: 467, semester: "FALL", offset: 6 },
        { code: "MATH", number: 425, semester: "SPRING", offset: 7 }
      ],
      "Business" => [
        { code: "ACCT", number: 209, semester: "SPRING", offset: 3 },
        { code: "FINC", number: 409, semester: "FALL", offset: 4 },
        { code: "ISTM", number: 209, semester: "FALL", offset: 6 },
        { code: "MGMT", number: 209, semester: "SPRING", offset: 7 }
      ],
      "Art" => [
        { code: "ARTS", number: 104, semester: "SPRING", offset: 1 },
        { code: "ARTS", number: 303, semester: "FALL", offset: 2 },
        { code: "ARTS", number: 356, semester: "SPRING", offset: 3 },
        { code: "ARTS", number: 403, semester: "FALL", offset: 4 },
        { code: "ARTS", number: 485, semester: "FALL", offset: 6 },
        { code: "ARTS", number: 489, semester: "SPRING", offset: 7 }
      ],
      "Cyber Security" => [
        { code: "CYBR", number: 402, semester: "SPRING", offset: 3 },
        { code: "CYBR", number: 403, semester: "FALL", offset: 4 },
        { code: "CYBR", number: 405, semester: "FALL", offset: 6 },
        { code: "CYBR", number: 491, semester: "SPRING", offset: 7 }
      ]
    }

    # Assign common courses
    assign_courses(common_courses)

    # Assign emphasis-specific courses
    if emphasis.present? && emphasis_courses.key?(emphasis.ename)
      assign_courses(emphasis_courses[emphasis.ename])
    end
  end

  def assign_courses(course_list)
    course_list.each do |course_data|
      course = Course.find_by(ccode: course_data[:code], cnumber: course_data[:number])
      semester = calculate_semester(enrol_year, enrol_semester, course_data[:offset])

      RecCourse.create!(course_id: course.id, student: self, semester: semester) if course
    end
  end

  def calculate_semester(start_year, start_semester, offset)
    year = start_year
    semester = start_semester

    offset.times do
      if semester == "SPRING"
        semester = "FALL"
      else
        semester = "SPRING"
        year += 1
      end
    end

    "#{semester}#{year}"
  end

end
