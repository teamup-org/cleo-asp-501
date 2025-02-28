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
Our [product and sprint backlog](https://asp500.atlassian.net/jira/software/projects/A5/boards/2) can be found in Jira, with project name asp-500

Document
- [asp-500_Sprint3DataDesignv1](https://tamucs.sharepoint.com/:b:/r/teams/Team-Fall24-CSCE431SoftwareEngineering-asp-500-Course/Shared%20Documents/asp-500-Course/Sprint%203/Documents/asp-500_Sprint3DataDesignv1.pdf?csf=1&web=1&e=ebxSOO)
- [asp-500_Sprint3Scope](https://tamucs.sharepoint.com/:b:/r/teams/Team-Fall24-CSCE431SoftwareEngineering-asp-500-Course/Shared%20Documents/asp-500-Course/Sprint%203/Documents/asp-500_Sprint3Scope.pdf?csf=1&web=1&e=fOKWUr)

## Installation

### Setting up the repository

```
git clone https://github.com/FA24-CSCE431-software-engineering/cleo-course-scheduler.git
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

```
docker start -ai determined_dubinsky
```

*Note: replace determined_dubinsky with the name of the docker container

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

## Support
The support of the application will close on May 6th.

## Future Development
To all developers looking to build upon this project, here are several features that could be extended for greater usability:
- Inclusion of ```Science Elective```, ```General Elective``` in the data design
- Extension of scope to include students from other faculties, departments and colleges
- Ability for users to express their interests more (outside of ```tracks``` and ```emphasis```) allowing for a more involved reccomendation algorithm

## Acknowledgement
We would like to thank Professor Wade, Pratik and Sundhanva for their continued support in this project. We would also like to thank our customer Dr. Kebo for his insights, feedback and creation of a positive environment for learning.

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
