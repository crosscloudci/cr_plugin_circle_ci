# TODO: Write documentation for `CrPluginCircleCi`
require "admiral"
require "halite"
require "./commands/*"

# TODO: Put your code here
class CrPluginCircleCi::CLI::Main < Admiral::Command
  define_version "1.0.0"
  define_help description: "A CI tools that checks project statuses on Github using Github Actions"

  register_sub_command "status", Commands::CircleCi

end

def CrPluginCircleCi::CLI.run(*args, **named_args)
  CrPluginCircleCi::CLI::Main.run(*args, **named_args)
end
