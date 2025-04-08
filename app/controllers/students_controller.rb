# frozen_string_literal: true

class StudentsController < ApplicationController
  before_action :set_student, only: %i[edit update show destroy]
  before_action :authenticate_admin!, only: [:index] # Ensure only admin can access index
  skip_before_action :authenticate_student_login! if Rails.env.test?

  def index
    @students = Student.all
  end

  def show
    @student = Student.find(params[:id])
    @tracks = Track.all.pluck(:tname) # Fetch track names
    @emphases = Emphasis.all.pluck(:ename) # Fetch emphasis names
  end

  def new
    @student = Student.new(
      first_name: params[:first_name],
      last_name: params[:last_name],
      email: params[:email],
      google_id: params[:google_id],
      enrol_year: params[:enrol_year] || current_year, # Set enrol_year or fallback to current year
      grad_year: params[:grad_year] || (current_year + 4),
      enrol_semester: params[:enrol_semester] || current_semester,
      grad_semester: params[:grad_semester] || (current_semester == 'fall' ? 'spring' : 'fall'),
      track_id: params[:track_id],
      emphasis_id: params[:emphasis_id]
    )

    #@student.build_student_info if @student.student_info.nil? #NEW
  end

  def create
    @student = Student.new(student_params)

    if @student.save
      if @student.student_info.nil?
        @student.build_student_info(uin: @student.google_id) # Skips validations on creation
      end
      # Query the DegreeRequirements table based on the student's major_id
      degree_requirements = DegreeRequirement.where(major_id: @student.major_id)

      # Map the degree requirements to StudentCourse records
      degree_requirements.map do |requirement|
        StudentCourse.create(student: @student, course_id: requirement.course_id, sem: requirement.sem)
      end

      if @student.is_admin?
        redirect_to students_path, notice: 'Student added successfully.'
      else
        redirect_to student_dashboard_path(@student.google_id), notice: 'Student added successfully.'
      end
    else
      render :new
    end
  end

  def edit 
    @student = Student.find_by(google_id: params[:google_id])
    @student.build_student_info if @student.student_info.nil? #NEW
  end

  def update
    if @student.update(student_params)
      if current_student_login.is_admin?
        redirect_to edit_student_path(@student.google_id), notice: 'Student information updated successfully.'
      else
        redirect_to profile_student_path(current_student_login),
                    notice: 'Your information has been updated successfully.'
      end
    else
      render :edit
    end
  end

  def destroy
    @student.destroy
    redirect_to students_path, notice: 'Student deleted successfully.'
  end

  def confirm_destroy
    Rails.logger.debug "Params: #{params.inspect}"
    @student = Student.find_by(google_id: params[:google_id])
    return unless @student.nil?

    redirect_to students_path, alert: 'Student not found.'
  end

  def profile
    # @student = current_student_login
    # @uid = @student.uid
    @student = Student.find_by(google_id: current_student_login.uid)

    return unless @student.nil?

    redirect_to root_path, alert: 'Student not found.'
  end

  def degree_planner
    redirect_to student_degree_planner_path(current_student_login.uid)
  end

  def upload_transcript
    # Set student at the beginning of the method
    @student = Student.find_by(google_id: current_student_login.uid)
    
    if request.get?
      @parsed_data = []
      @grouped_courses = {}
      render :show_parsed_transcript
      return
    end

    transcript = params[:transcript]
    if transcript
      unless transcript.content_type == 'application/pdf'
        @parse_error = "Invalid file type: #{transcript.content_type}"
        @parsed_data = []
        @grouped_courses = {}
        render :show_parsed_transcript, status: :ok
        return
      end

      # Create a temporary file for parsing
      temp_file = Tempfile.new(['transcript', '.pdf'])
      begin
        temp_file.binmode
        temp_file.write(transcript.read)
        temp_file.rewind

        # Call Python script to parse the PDF
        python_script = Rails.root.join('python', 'parse.py')
        output = `python3 #{python_script} #{temp_file.path} 2> #{Rails.root.join('log', 'transcript_parser.log')}`
        
        if $?.exitstatus != 0
          log_content = File.read(Rails.root.join('log', 'transcript_parser.log'))
          @parse_error = "Python script failed. Check logs for details. Error: #{log_content}"
          Rails.logger.error("Python script failed. Log: #{log_content}")
          @parsed_data = []
          @grouped_courses = {}
          render :show_parsed_transcript, status: :ok
          return
        end
        
        begin
          # Parse the JSON data
          @parsed_data = JSON.parse(output)
          
          if @parsed_data.empty?
            @parse_error = "Parser returned empty result. Check logs for details."
            log_content = File.read(Rails.root.join('log', 'transcript_parser.log'))
            Rails.logger.info("Parsed data preview: #{@parsed_data.first(3).inspect}")
            Rails.logger.error("Parser log: #{log_content}")
            @grouped_courses = {}
            render :show_parsed_transcript, status: :ok
            return
          end
          
          # Clear existing courses for this student
          PrevStudentCourse.where(uin: current_student_login.uid).destroy_all
          
          # Save parsed courses directly to PrevStudentCourse
          @parsed_data.each do |course_data|
            # Find or create the course
            course = Course.find_or_initialize_by(
              ccode: course_data['ccode'].upcase,
              cnumber: course_data['cnumber']
            )
            
            # Set course attributes if it's a new course
            if course.new_record?
              course.cname = course_data['cname'] || "#{course_data['ccode']} #{course_data['cnumber']}"
              course.credit_hours = course_data['credit_hours'].to_i
              course.save!
            end
            
            # Normalize grade to fit within 3 characters
            grade = course_data['grade'].to_s.upcase
            grade = case grade
                   when /^A[+-]?$/ then 'A'
                   when /^B[+-]?$/ then 'B'
                   when /^C[+-]?$/ then 'C'
                   when /^D[+-]?$/ then 'D'
                   when /^F$/ then 'F'
                   when /^W$/ then 'W'
                   when /^I$/ then 'I'
                   when /^IP$/ then 'IP'
                   when /^S$/ then 'S'
                   when /^U$/ then 'U'
                   when /^CR$/ then 'CR'
                   when /^P$/ then 'P'
                   when /^NP$/ then 'NP'
                   when /^TCR$/ then 'TCR'
                   else 'NR' # Not Reported
                   end
            
            # Create the student course record
            PrevStudentCourse.create!(
              uin: current_student_login.uid,
              course_id: course.id,
              semester: course_data['semester'],
              grade: grade
            )
          end
          
          # Group courses by semester for the view
          @grouped_courses = @parsed_data.group_by { |course| course['semester'] }
          
          if @grouped_courses.empty?
            @parse_error = "No courses could be grouped by semester"
            render :show_parsed_transcript, status: :ok
          else
            # Log the parsed data for debugging
            Rails.logger.info("Parsed data: #{@parsed_data.inspect}")
            @success_message = "Transcript parsed successfully! Found #{@parsed_data.size} courses."
            @show_success_modal = true
            render :show_parsed_transcript, status: :ok
          end
        rescue JSON::ParserError => e
          Rails.logger.error("Transcript parsing error: #{e.message}")
          Rails.logger.error("Python output: #{output}")
          @parse_error = "JSON parsing error. Parser output: #{output}. Log: #{log_content}"
          @parsed_data = []
          @grouped_courses = {}
          render :show_parsed_transcript, status: :ok
        end
      rescue StandardError => e
        Rails.logger.error("File handling error: #{e.message}")
        @parse_error = "File processing error: #{e.message}"
        @parsed_data = []
        @grouped_courses = {}
        render :show_parsed_transcript, status: :ok
      ensure
        # Clean up the temporary file
        temp_file.unlink
      end
    else
      @parse_error = "No file uploaded"
      @parsed_data = []
      @grouped_courses = {}
      render :show_parsed_transcript, status: :ok
    end
  end

  def save_transcript_courses
    begin
      # Get all temporary courses for this session
      courses = TemporaryTranscriptCourse.where(session_id: session.id.to_s)
      
      if courses.empty?
        flash[:alert] = "No courses were found to save."
        redirect_to view_transcript_courses_student_path(current_student_login)
        return
      end
      
      saved_count = 0
      failed_courses = []
      error_details = []
      
      ActiveRecord::Base.transaction do
        # First, remove all existing courses for this student
        PrevStudentCourse.where(uin: current_student_login.uid).destroy_all
        Rails.logger.info("Cleared existing courses for student #{current_student_login.uid}")
        
        courses.each do |course|
          begin
            # Create or find the course
            db_course = Course.find_or_initialize_by(
              ccode: course.ccode.upcase,
              cnumber: course.cnumber.to_s.gsub(/[^0-9]/, '')  # Ensure cnumber is numeric
            )

            # Set default values if the course is new
            if db_course.new_record?
              db_course.cname = course.cname || "#{course.ccode} #{course.cnumber}"
              db_course.credit_hours = course.credit_hours.to_f  # Ensure credit_hours is a float
              db_course.save!
            end
            
            # Create the student course record with grade
            prev_course = PrevStudentCourse.new(
              uin: current_student_login.uid,
              course_id: db_course.id,
              semester: course.semester.upcase.delete(' '),
              grade: course.grade

            )
            
            if prev_course.save
              saved_count += 1
              Rails.logger.info("Saved course #{db_course.ccode} #{db_course.cnumber} for semester #{course.semester} with grade #{course.grade}")
            else
              error_msg = prev_course.errors.full_messages.join(', ')
              Rails.logger.error("Failed to save student course: #{error_msg}")
              failed_courses << "#{course.ccode} #{course.cnumber}"
              error_details << "#{course.ccode} #{course.cnumber}: #{error_msg}"
            end
          rescue StandardError => e
            Rails.logger.error("Error processing course #{course.ccode} #{course.cnumber}: #{e.message}")
            failed_courses << "#{course.ccode} #{course.cnumber}"
            error_details << "#{course.ccode} #{course.cnumber}: #{e.message}"
          end
        end

        if saved_count == 0
          raise ActiveRecord::Rollback, "No courses were saved successfully"
        end
      end
      
      if saved_count > 0
        flash[:success] = "Successfully saved #{saved_count} courses!"
        if failed_courses.any?
          flash[:alert] = "Failed to save: #{failed_courses.join(', ')}"
          flash[:error_details] = error_details.join('<br>')
        end
      else
        flash[:alert] = "Failed to save any courses. Please try again."
        flash[:error_details] = error_details.join('<br>')
      end
      
      # Clear temporary courses after saving
      TemporaryTranscriptCourse.clear_session(session.id.to_s)
      
      redirect_to view_transcript_courses_student_path(current_student_login)
      
    rescue StandardError => e
      Rails.logger.error "Error saving courses: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      flash[:alert] = "An error occurred while saving the courses. Please try again."
      flash[:error_details] = e.message
      redirect_to view_transcript_courses_student_path(current_student_login)
    end
  end

  def view_transcript_courses
    @student = Student.find_by(google_id: current_student_login.uid)
    @prev_courses = PrevStudentCourse.includes(:course).where(uin: current_student_login.uid)
    @grouped_courses = @prev_courses.group_by(&:semester).transform_values do |courses|
      courses.map do |psc|
        {
          'semester' => psc.semester,
          'ccode' => psc.course.ccode,
          'cnumber' => psc.course.cnumber,
          'cname' => psc.course.cname,
          'credit_hours' => psc.course.credit_hours,
          'grade' => psc.grade,
          'course_id' => psc.course.id  # Add the course_id to the mapped data
        }
      end
    end
    render :show_parsed_transcript
  end

  def remove_transcript_course
    course = PrevStudentCourse.find_by(
      uin: current_student_login.uid,
      course_id: params[:course_id],
      semester: params[:semester]
    )
    
    if course.nil?
      flash[:alert] = "Course not found"
    elsif course.destroy
      flash[:notice] = "Course removed successfully"
    else
      flash[:alert] = "Failed to remove course: #{course.errors.full_messages.join(', ')}"
    end
    
    redirect_to view_transcript_courses_student_path(current_student_login)
  end

  def add_transcript_course
    begin
      Rails.logger.info("Adding/Editing course with params: #{params.inspect}")
      
      # Validate input
      unless params[:ccode].present? && params[:cnumber].present?
        flash[:alert] = "Course code and number are required."
        return redirect_to view_transcript_courses_student_path(current_student_login)
      end

      # Create or find the course
      course = Course.find_or_initialize_by(
        ccode: params[:ccode].upcase,  # Automatically capitalize course code
        cnumber: params[:cnumber]
      )
      Rails.logger.info("Found/created course: #{course.inspect}")

      # Set course attributes
      course.cname = params[:cname].present? ? params[:cname].titleize.gsub(/\b(?:and|for|in|of|the|to)\b/i) { |word| word.downcase } : nil  # Automatically titleize course name and handle special words
      course.credit_hours = params[:credit_hours] if params[:credit_hours].present?

      # Save the course
      unless course.save
        Rails.logger.error("Failed to save course: #{course.errors.full_messages.join(', ')}")
        flash[:alert] = "Failed to save course: #{course.errors.full_messages.join(', ')}"
        return redirect_to view_transcript_courses_student_path(current_student_login)
      end

      # If editing, remove the old course first
      if params[:edit_mode] == 'true'
        Rails.logger.info("Editing mode - removing old course")
        old_course = PrevStudentCourse.find_by(
          uin: current_student_login.uid,
          course_id: course.id,
          semester: params[:original_semester]
        )
        Rails.logger.info("Found old course: #{old_course.inspect}")
        old_course&.destroy
      end

      # Create the student course record with the new semester
      prev_course = PrevStudentCourse.new(
        uin: current_student_login.uid,
        course_id: course.id,
        semester: params[:semester_select], # Use the selected semester from dropdown
        grade: params[:grade]
      )
      Rails.logger.info("Creating new student course record: #{prev_course.inspect}")

      if prev_course.save
        flash[:notice] = "Course #{params[:edit_mode] == 'true' ? 'updated' : 'added'} successfully"
      else
        Rails.logger.error("Failed to save student course: #{prev_course.errors.full_messages.join(', ')}")
        flash[:alert] = "Failed to #{params[:edit_mode] == 'true' ? 'update' : 'add'} course: #{prev_course.errors.full_messages.join(', ')}"
      end

    rescue StandardError => e
      Rails.logger.error "Error adding/updating course: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      flash[:alert] = "An error occurred while #{params[:edit_mode] == 'true' ? 'updating' : 'adding'} the course. Please try again."
    end

    redirect_to view_transcript_courses_student_path(current_student_login)
  end

  def degree_requirements
    # Get the student's major
    student = Student.find(params[:id])
    major = student.major

    # Fetch required courses for the major
    required_courses = DegreeRequirement.where(major: major).includes(:course)
    
    # Format the response
    courses = required_courses.map do |req|
      course = req.course
      {
        ccode: course.ccode,
        cnumber: course.cnumber,
        cname: course.cname,
        credit_hours: course.credit_hours,
        requirement_type: req.requirement_type # e.g., 'core', 'elective', etc.
      }
    end

    render json: { courses: courses }
  rescue => e
    Rails.logger.error "Error fetching degree requirements: #{e.message}"
    render json: { error: 'Unable to fetch degree requirements' }, status: :internal_server_error
  end

  ##def academic_progress
    ##@student = Student.find_by(google_id: params[:google_id])

    ##if @student
      ##@prev_student_courses = PrevStudentCourse.where(uin: @student.uin)
  ##end

  def academic_progress
    @student = Student.find_by(google_id: params[:google_id])
  
    if @student
      # Query prev_student_courses for the student using their UIN
      prev_courses = @student.prev_student_courses
      remaining_courses = @student.student_courses
  
      # Completed Courses: where a grade is available
      @completed_courses = prev_courses.reject { |course| course.grade == "NR" }
  
      # In-Progress Courses: where no grade is assigned (you can adjust this based on your criteria)
      @in_progress_courses = prev_courses.select { |course| course.grade == "NR" }
  
      # Remaining Courses: this can be more complex depending on how you determine remaining courses
      @remaining_courses = remaining_courses.reject do |course|
        prev_courses.any? { |prev_course| prev_course.course_id == course.course_id}
      end

      # Fetch course details for remaining courses (using the course_id from student_courses)
      @remaining_courses_details = @remaining_courses.map do |course|
        course_details = Course.find(course.course_id) # Assuming the course_id maps to a Course
        {
          course_code: course_details.ccode,
          course_number: course_details.cnumber,
          credit_hours: course_details.credit_hours
        }
      end      
    else
      flash[:alert] = "Student not found"
      redirect_to some_other_path # replace with a fallback route
    end
  end
  
  
  private

  def set_student
    @student = Student.find_by(google_id: params[:google_id])
    return unless @student.nil?

    raise ActiveRecord::RecordNotFound, "Couldn't find Student with google_id=#{params[:google_id]}."
  end

  def authenticate_admin!
    return if current_student_login.is_admin?

    redirect_to student_dashboard_path(current_student_login.google_id),
                alert: 'You are not authorized to access this page.'
  end

  def student_params
    params.require(:student).permit(:google_id, :first_name, :last_name, :email, :enrol_year, :grad_year, :enrol_semester,
                                    :grad_semester, :major_id, :emphasis_id, :track_id, student_info_attributes: [:preferred_time, :preferred_loc, :ferpa_consent]) #NEW
  end
end
