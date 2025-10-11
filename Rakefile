# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

# Load rswag rake tasks in development and test environments
if Rails.env.local?
  begin
    require 'rswag/specs/rake_task'
    RSwag::Specs::RakeTask.new
  rescue LoadError
    # rswag not available
  end
end
