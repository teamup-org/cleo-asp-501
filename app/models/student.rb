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
  has_many :prev_student_courses, primary_key: "google_id", foreign_key: :uin, dependent: :destroy
  has_many :rec_courses, primary_key: "google_id", foreign_key: :uin, dependent: :destroy
  #has_one :student_info, primary_key: "google_id", foreign_key: :uin

  belongs_to :major

  belongs_to :track, optional: true

  belongs_to :emphasis, optional: true
  # belongs_to :emphasis, foreign_key: :emphases_id, optional: true

  after_create :assign_default_courses

  def total_credits_completed
    prev_student_courses.reject { |course| course.grade == "NR" }.sum { |course| course.course.credit_hours }
  end

  private

  def assign_default_courses
    common_courses = [
      { code: "CSCE", number: 181, offset: 2 },
      { code: "CSCE", number: 120, offset: 2 },
      { code: "CSCE", number: 222, offset: 2 },
      { code: "CSCE", number: 221, offset: 3 },
      { code: "CSCE", number: 312, offset: 3 },
      { code: "CSCE", number: 314, offset: 3 },
      { code: "CSCE", number: 313, offset: 4 },
      { code: "CSCE", number: 331, offset: 4 },
      { code: "CSCE", number: 411, offset: 5 },
      { code: "CSCE", number: 481, offset: 5 },
      { code: "CSCE", number: 399, offset: 5 },
      { code: "CSCE", number: 482, offset: 7 }
      #{ code: "ENGR", number: 102, offset: 0 },
      #{ code: "MATH", number: 151, offset: 0 },
      #{ code: "CHEM", number: 107, offset: 0 },
      #{ code: "ENGL", number: 104, offset: 0 },
      #{ code: "ENGR", number: 216, offset: 1 },
      #{ code: "PHYS", number: 206, offset: 1 },
      #{ code: "MATH", number: 152, offset: 1 },
      #{ code: "ENGL", number: 210, offset: 1 },
      #{ code: "MATH", number: 304, offset: 2 },
      #{ code: "STAT", number: 211, offset: 4 },
      #{ code: "MATH", number: 251, offset: 5 },
      #{ code: "CSCE", number: 410, offset: 5 },
      #{ code: "CSCE", number: 421, offset: 5 },
      #{ code: "CSCE", number: 412, offset: 4 },
      #{ code: "CSCE", number: 431, offset: 6 },
      #{ code: "CSCE", number: 420, offset: 6 },
      #{ code: "CSCE", number: 430, offset: 7 }
    ]

    # Define emphasis-specific courses
    emphasis_courses = {
      "Mathematics" => [
        { code: "MATH", number: 308, offset: 3 },
        { code: "MATH", number: 439, offset: 4 },
        { code: "MATH", number: 467, offset: 6 },
        { code: "MATH", number: 425, offset: 7 }
      ],
      "Business" => [
        { code: "ACCT", number: 209, offset: 3 },
        { code: "FINC", number: 409, offset: 4 },
        { code: "ISTM", number: 209, offset: 6 },
        { code: "MGMT", number: 209, offset: 7 }
      ],
      "Art" => [
        { code: "ARTS", number: 104, offset: 1 },
        { code: "ARTS", number: 303, offset: 2 },
        { code: "ARTS", number: 356, offset: 3 },
        { code: "ARTS", number: 403, offset: 4 },
        { code: "ARTS", number: 485, offset: 6 },
        { code: "ARTS", number: 489, offset: 7 }
      ],
      "Cyber Security" => [
        { code: "CYBR", number: 402, offset: 3 },
        { code: "CYBR", number: 403, offset: 4 },
        { code: "CYBR", number: 405, offset: 6 },
        { code: "CYBR", number: 491, offset: 7 }
      ]
    }

    assign_courses(common_courses)
    #assign_courses(emphasis_courses[emphasis.ename]) if emphasis.present? && emphasis_courses.key?(emphasis.ename)
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
    semester = start_semester.upcase
    
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
