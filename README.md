In this post, I'll show you how to set up end-to-end capistrano testing using Cucumber.  I've extracted this from the cucumber features I wrote for a gem I'm building named [auto_tagger](http://github.com/zilkey/auto_tagger/tree/master).  To fully test capistrano recipes, your tests will have to:

 * Create a local git repository
 * Create a local app with a config/deploy.rb file
 * Push the app to the local repository
 * Run `cap deploy:setup` from the app (which will setup a directory inside your local test directory)
 * Run a `cap deploy` from the app (which will deploy to your test directory)
 * Assert against the content of the deployed app in the test directory

NOTE:  this only will not work on Windows

## Setup your keys

To make life easy, you'll want to be able to ssh to your own machine.  To do this, you'll need to create a key, then add that key to your authorized keys.  If you don't already have a key setup locally, check out the excellent [RailsMachine guide](https://support.railsmachine.com/index.php?pg=kb.page&id=33).  Once you have a key, you can copy it to authorized keys like so:

    cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys

Now you should be able to ssh to your own box without entering a password.  To log into your own box, you can use the IP address or the computer's name.  Depending on your `/etc/hosts` file entries, you may also be able to log in using `localhost`.

If you are a Mac user you'll have to enable "Remote Access" from System Preferences to be able to ssh in to your own box.  For security, only allow yourself to log in via ssh.  The system preferences pane will show you the IP address you can use to ssh into.

## Setup your cucumber file system

The file system I'll use for this demo will look like this:

    |-- features
    |   |-- capistrano.feature
    |   |-- step_definitions
    |   |   `-- capistrano_steps.rb
    |   |-- support
    |   |   `-- env.rb
    |   `-- templates
    |       `-- deploy.erb
    |-- recipes
    |   `-- my_recipe.rb
    `-- test_files

## Add the feature

Let's say you have a simple cap task that writes a file to shared after you deploy. The feature file might look something like this:

`features/capistrano.feature`

    Feature: Deployment
      In order to know feel better about myself
      As a person who needs lots of reinforcement
      I want leave files named PEOPLE_LIKE_YOU all around my remote machine

      Scenario: User deploys
        Given a an app
        When I deploy
        Then the PEOPLE_LIKE_YOU file should be written to shared

Now you can run `cucumber features/` and you'll see that you have several pending steps.

## Get your setup correct

For these features to work, we'll need a test directory (that's outside of the features directory), and we'll need to delete everything from it before running every scenario:

`features/support/env.rb`

    require 'spec'
    require 'erb'
    require 'etc'

    Before do
      @test_files_dir = File.join(Dir.pwd, "test_files")
      @app_dir  = File.join(@test_files_dir, "app")
      @repo_dir = File.join(@test_files_dir, "repo")
  
      FileUtils.rm_r(@test_files_dir) if File.exists?(@test_files_dir)
      FileUtils.mkdir_p(@test_files_dir)
    end

## Fill in the steps

`features/step_definitions/capistrano_steps.rb`

    Given /^a an app$/ do

      # Create the git repo
      FileUtils.mkdir_p @repo_dir
      Dir.chdir(@repo_dir) do
        system "git --bare init"
      end

      # Create and capify the dummy app, and push it to the local repo
      FileUtils.mkdir_p @app_dir
      Dir.chdir(@app_dir) do
        [
          %Q{git init},
          %Q{mkdir config},
          %Q{capify .},
          %Q{git add .},
          %Q{git commit -m "first commit"},
          %Q{git remote add origin file://#{@repo_dir}},
          %Q{git push origin master}
        ].each do |command|
          system command
        end
      end
  
      # Write a custom deploy file to the app, using an ERB template
      deploy_variables = {
        :deploy_to => File.join(@test_files_dir, "deployed"),
        :repository => @repo_dir,
        :git_executable => `which git`.strip,
        :logged_in_user => Etc.getlogin
      }

      template_path     = File.expand_path(File.join(__FILE__, "..", "..", "templates", "deploy.erb"))
      compiled_template = ERB.new(File.read(template_path)).result(binding)

      File.open(File.join(@app_dir, "config", "deploy.rb"), 'w') {|f| 
        f.write compiled_template
      }
    end

    When /^I deploy$/ do
      Dir.chdir(@app_dir) do
        system "cap deploy:setup"
        system "cap deploy"
      end

    end

    Then /^the PEOPLE_LIKE_YOU file should be written to shared$/ do
      File.exists?(File.join(@test_files_dir, "deployed", "shared", "PEOPLE_LIKE_YOU")).should be_true
    end

Now when you run `cucumber features/` and you'll see that you a failure because you don't have the correct cap file.

## Make it pass

To make this pass, add a recipe like this:

`recipes/my_recipe.rb`

    Capistrano::Configuration.instance(:must_exist).load do
      task "my_task" do
        run "echo PEOPLE_LIKE_YOU > #{shared_path}/PEOPLE_LIKE_YOU"
      end
    end

##  Debugging

You'll notice that when you run `cucumber features` you get all of the output from capistrano.  This makes your feature steps messy, but provides a lot of valuable debug information.  If you want to silence it, you can use any number of tools, including piping the output to logs, or using `silence_stream`.

You'll also notice that the setup described above leaves the files in the `test_files` directory intact after each feature.  This makes it easy to inspect the file system manually after each run - you can even `cd` into the `test_files/app` directory and re-run deployments, or tweak the `config/deploy.rb` file and re-deploy and then move your changes back to `templates/deploy.erb `.

## Next Steps

This is just a quick sample to show you what you can do.  You'll probably want to create a helper class of some sort to wrap up the file system calls, so your steps would look more like:

    Given /^a an app$/ do
      FileHelper.create_repo
      FileHelper.create_app
      FileHelper.capify_app
    end

## Testing against non-local environments

You could in theory use this to test against any environment you have access to - just change the host in `templates/deploy.erb`.  If you choose to test against a true remote machine, you'll have to figure out how to shell out commands to it.  If you are on a mac, one thing that might help is to [mount a remote machine over ssh](http://lifehacker.com/software/ssh/geek-to-live--mount-a-file-system-on-your-mac-over-ssh-246129.php).

## Grab the source

The full source code for this app can be found at:

[]()