require 'yaml'

module YKYmlModule
  module Tool
    def self.load_yml(path)
      if File.exist?(path) == false
        FileUtils.makedirs(File.dirname(path)) if File.exist?(File.dirname(path)) == false
        f = File.new(path, "w+")
        f.close
      end

      f = File.open(path, "r")
      yml = YAML.load(f, symbolize_names: false)
      f.close
      yml = {} if yml == false #空yml的时候， yml = false
      yml
    end

    def self.update_yml(path, key, value)
      yml = self.load_yml(path)
      yml[key] = value
      f = File.open(path, "w+")
      YAML.dump(yml, f, symbolize_names: false)
      f.close
    end

    def self.load_yml_value(path, key)
      yml = self.load_yml(path)
      puts("yml:#{yml}")
      yml[key]
    end

    def self.update_yml_key_value(path, key, value)
      YKYmlModule::Tool.update_yml(path, key, value)
    end
  end
end
