module YKYmlModule

  require 'yaml'
  require 'fileutils'

  def self.load_yml_yk(path)
    if File.exist?(path) == false
      dir = File.dirname(path)
      if File.exist?(dir) == false
        FileUtils.mkdir(dir)
      end
      f = File.open(path, "w+")
      f.close
    end

    f = File.open(path, 'r')
    yml = YAML.load(f, symbolize_names: false)
    f.close
    if yml == false
      yml = {}
    end

    yml
  end

  def self.load_yml_value_yk(path, key)
    yml = self.load_yml_yk(path)
    yml[key]
  end

  def self.update_yml_yk(path, key, value)
    yml = self.load_yml_yk(path)
    yml[key] = value

    f = File.open(path, "w+")
    YAML.dump(yml, f, symbolize_names: false)
    f.close

  end

  def self.update_yml_dict_value_yk(path, key, value)
    dict = self.load_yml_value_yk(path, key)
    dict = {} if dict == nil
    dict.update(value)

    self.update_yml_yk(path, key, dict)
  end

end