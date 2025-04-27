# README 

## Introduction to our Project

Our team is creating a degree planner application for Texas A&M University students called Cleo. Students can create a user profile based on their interests and will be recommended courses to take in their upcoming semesters. 

## Requirements

What is needed to run and code our test:

- Ruby ~ 3.3.4
- Rails ~ 7.2.1
- PostgreSQL ~ 14.13
- Ruby Gems ~ Listed in ‘Gemfile’

## External dependencies

- Docker - Download latest version at https://www.docker.com/products/docker-desktop
- Git - Download latest version at https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

## Documentation
Our [product and sprint backlog](https://501-cleo.atlassian.net/jira/software/projects/CLEO/boards/1/backlog) can be found in Jira, with project name CLEO

Document
...

## Installation

### Setting up the repository

```
git clone git@github.com:teamup-org/cleo-asp-501.git
```

If you have already cloned and would like to update locally

```
git stash (if you have any changes)
git pull origin main
```

### Running Docker

Navigate to the app directory and create a docker container.
```
docker run -it --volume "${PWD}:/directory" -e DATABASE_USER=cleo_app -e DATABASE_PASSWORD=cleo_password -p 3000:3000 paulinewade/csce431:latest
```

*Note: replace directory with where the app code is located

If you want to re-enter an existing container 

run `docker ps` to find your docker
then...
```
docker start <docker_id>
docker exec -it <docker_id> bash
```

Once your finished call
```
docker stop <docker_id>
```

### Installing Dependencies
```
bundle install && rails webpacker:install
```

### Configuring PostgreSQL
If no has been created database yet, run the following
```
rails db:create && rails db:migrate
```

Navigate to the ```lib``` folder, and run the following to scrape the course catalog
```
./run_spiders.sh
```

With the generated csv files, run the following to seed the database
```
rails db:seed
```

## Testing

We used RSpec and the RSpec test suite can be ran using:
```rspec spec/```

You can run all the tests by using the following command. This runs all tests, including integration and unit tests:
```rspec .```

## Code Execution

Run the following code in Powershell or regular terminal if using Windows or Linux/Mac OS respectively:

Navigate to project directory
```
cd cleo-course-scheduler
```

Run the app
```
rails s --binding:0.0.0.0
```

This application can be viewed by writing the following in your browser
```http://localhost:3000/```

## Environmental Variables/Files

Follow this Google Oauth [configuration guide](​​https://medium.com/@tony.infisical/guide-to-using-oauth-2-0-to-access-google-apis-dead94d6866d) to generate a ```GOOGLE_OAUTH_CLIENT_ID``` and ```GOOGLE_OAUTH_CLIENT_SECRET```, which will be used for authentication.

To enable it locally, create a ```.env``` file in the root project directory. The file should look like the following:
```
GOOGLE_CLIENT_ID="..."
GOOGLE_CLIENT_SECRET="..."
```
Replace the ellipses with your own secrets/

The instructions for setting the environment variables on Render can be found below.

You will want your .env file to look something like this:
```
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
ADMIN_EMAILS=example1@example.edu,example2@example.edu
CLEO_COURSE_SCHEDULER_DATABASE_PASSWORD=... (You will get this when deploying your db or you can set it but it must be the same when deploying your db)
DATABASE_HOST=localhost (Will change to the database host name when deploying)
```
## Deployment

The following steps will result in the deployment of a Render Postgres Database (required for web service).
1. Setup a [Render](https://render.com/) account
2. From the Render dashboard select `Add New` -> `Postgres`
3. Enter a name
4. Select a github repository (You may have to link your github account) and then select the enviroment (production).
5. Set the database name to `cleo_course_scheduler_production`
6. Set the database user to `cleo_course_scheduler`
7. Select your desired plan the select `Create Database`
8. Copy the `Host Name`

The following steps will result in the deployment of a Render Postgres Web service.
1. From the Render dashboard select `Add New` -> `Web Service`
2. Select a github repository
3. Enter a name
4. Select a project (Your github repo) and an enviroment (production)
5. Set the `Language` to `Ruby`
6. Select the Desired payment
7. At the `Environment Variables` section, click `Add from .env` then copy and paste the .env file. After that you will copy the key from your `master.key` file.
(If you do not have this key you can generate it with `rails credentials:edit`) copy and paste that key into Render's `RAILS_MASTER_KEY`. After that change DATABASE_HOST from `localhost` to your copied `Host Name`.
8. replace `Build Command` with `bundle install; yarn install; bundle exec rake assets:precompile; bundle exec rake assets:clean; bundle exec rails db:create db:migrate db:seed;`
9. Select `Create Web Service`

### Deployment Environment Variables
To enable Google Oauth2, head over to the settings tab on the pipeline dashboard. 

1. Scroll down until `Reveal config vars`
2. Add your client id and secret id
```
GOOGLE_OAUTH_CLIENT_ID=...
GOOGLE_OAUTH_CLIENT_SECRET=...
```

Now once your pipeline has built the apps, select `Open app` to open the app.

## CI/CD

Continuous integration was employed through the use of Github actions. Our workflow includes:
- RSpec integration and feature tests
- Rubocop linting
- Brakeman tests

## How to test
### Creating a new account
To create an account click on the `Login with Google` button on the landing page, then click an account, if it has never been used before a new account will be created with that email. PLEASE MAKE SURE YOU CLICK COMPUTER SCIENCE FOR YOUR MAJOR -- As of right now we were only given the .csv files for computer science and if you try another major, clicking generate plan / generate reccomended semester may not do anything because their is no information for other majors!

### How to check for a missing prereq
After login, click `Build Your Degree Planner` and then remove MATH 151 from Spring 2025, you should see a red banner at the top of the screen. Note: If you are doing this after you have uploaded the file.pdf transcript, In my tests Computer Organization is a class that you should be able to remove to check for any prereq issues with Programming Studio but it may be a bit difficult to find a prereq that I have not already completed so I recommend doing this step first before uploading file.pdf.

### How to upload your unofficial transcript
After login, click `Profile` -> `Choose File` (choose a your saved transcript.pdf) -> click `Upload New Transcript`.
You should then be able to change class names and unselect classes to fix any errors with the gathered classes.

### How to test recommended semester
After Uploading your transcript, navigate back to `Home` -> `Build Your Degree Planner`, I recommend to better see the "recommended semester" you clear the degree planner that way their is not still a bunch of random classes on your degree planner that you may/may not need. Once you clear, go to the Spring 2025 and click the  `Generate Recommended Semester` next to "Sprint 2025", after that (assuming you are using the provided file.pdf example), you should see something similiar to the following: 

<img width="637" alt="ExampleRecImage" src="https://github.com/user-attachments/assets/ed94c155-b209-4565-948b-83d20bcff3af" />

### How to test grade distributions
After login, click `View Grade Distribution` then type in `CSCE` then `431` and click `submit` (Or any other valid class)

### How to see a generic degree planner
After login, click `View Default Degree Plan`

### How to update user information
After login, click `Profile` -> `Edit Profile` then the user should be able to change any of the drop down items as well as give FERPA consent. Once clicking, the user can change any of the fields then click `Save Changes`. 
The user should see a green banner at the top saying changes are saved and the current user preferences should be shown on the left of the student profile.

### How to access Academic Progress
After login, click `Profile` and a progress bar is displayed at the bottom of the screen. This displays the user's current progress towards their degree in years and a percentage.
From there, click `Home` to go back to the dashboard and then click `Current Academic Progress`. The user can now see which courses they have completed, are in-progress, and remaining.

### How to access help
After login, click on the 3 bars in the top left corner -> `Support/Help` -> `Help Page`. Here you show find some frequently asked questions as well as a link the the `CLEO Github` which contains our README.

### How to Install System in Render Account
As of right now, due to having the free version of Render we can not share the system. Please message us in the Teamup discord when you are ready for us to transfer ownership to you.

## Support
The support of the application will close on May 6th.

## Future Development
To all developers looking to build upon this project, here are several features that could be extended for greater usability:
- Inclusion of ```Science Elective```, ```General Elective``` in the data design
- Extension of scope to include students from other faculties, departments and colleges
- Ability for users to express their interests more (outside of ```tracks``` and ```emphasis```) allowing for a more involved reccomendation algorithm

## Acknowledgement
We would like to thank Professor Wade for her continued support in this project. We would also like to thank our customer Dr. Kebo for his insights, feedback and creation of a positive environment for learning.

Prevoius Cleo group members:
- Maria Viteri
- Uzma Hamid
- Vincent Tran
- Tatiana Fern
- Neale Tham

Current Cleo group members:
- Kyle Moore
- Joe Depolo
- Danny Garmendez
- Alyan Tharani
- Cameron Cao  


## References
- [Stack Overflow](https://stackoverflow.com)
- [OpenAI](https://chat.openai.com)
- [Ruby on Rails](https://guides.rubyonrails.org/index.html)
