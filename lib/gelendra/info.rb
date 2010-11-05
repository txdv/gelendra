=begin
    gelendra is a package(archive) manager for managing counterstrike 1.6 maps, addons, etc.
    Copyright (C) 2010  Andrius Bentkus

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

class BaseInfo
  include Singleton

  BASEINFOFILE = "#{Etc.getpwuid.dir}/.gelendra.yaml"
  BASEFILES = "#{Etc.getpwuid.dir}/.basefiles.yaml"

  def initialize
    File.open(BASEINFOFILE, "a+") do |f|
      @data = YAML::load(f.read)
      @data = {"base_dir"=>[]} if @data == false
    end

    File.open(BASEFILES, "r") do |f|
      @basefiles = YAML::load(f.read)
    end

    @basefiles[:files].each do |archive, files|
      PackageFile.add_basefiles(archive, files)
    end

    @basefiles[:wads].each do |bla|
    end
  end

  def base_dir
    @data["base_dir"]
  end

  def save
    File.open(BASEINFOFILE, "w") { |f| f.puts @data.to_yaml }
  end

  def get_packages(pattern = "*")
    pkg = []
    base_dir.each do |dir|
      pkg.concat Dir["#{dir}/#{pattern}"]
    end
    return pkg.sort
  end

  def include?(file)
    @basefiles[:files].each do |key,arr|
      return true if arr.include?(file)
    end
    return false
  end

  def wads
    @basefiles[:wads]
  end

  def all_textures
    wads.collect { |w| w }.flatten
  end

  def default_wads
    @basefiles[:wads].collect { |key,val| key }
  end

end

class LocalInfo
  # TODO: Rewrite so it will open the file only if really needed (when data invoked)
  def initialize(baseinfo, file = 'database.yaml')
    @baseinfo = baseinfo
    begin
      File.open(file,"r") { |f| @data = YAML::load(f.read) }
    rescue
      @data = { :zipfile=> nil, :installed => { } } 
    end
    @data = { :zipfile=> nil, :installed => { } } if @data == false
  end

  def zipfile
    @data[:zipfile]
  end

  def add(archivename, list)
    @data[:installed][archivename] = list
  end

  def delete(archive, file = nil)
    if file.nil?
      @data[:installed].delete(archive)
    else
      @data[:installed][archive].delete(file)
    end
  end

  def exists?(archive)
    !@data[:installed][archive].nil?
  end

  def save(file = 'database.yaml')
     File.open(file,"w") { |f| f.puts @data.to_yaml }
  end

  def occurs(file)
    @data[:installed].each do |key,val| 
      return true if val.include?(file) 
    end
    return false
  end

  def archives
    archs = []
    @data[:installed].each { |key,val| archs.push(key) }
    return archs.sort
  end

  def files(archive)
    @data[:installed][archive].sort
  end

  def all_files
    all = []
    archives.each { |arch| all.concat(files(arch)) }
    return all
  end

  def all_public_files
    return self.all_files.reject { |f| !public_file?(f) }.sort
  end

  def get_packages(pattern = "*")
    # TODO: THIS IS A BAD HACK, PLEASE REMAKE WITH HIDDEN DIR AND EMPTY FILES
    # Which obviously is a hack too, but better then writing own parser ...
    list = @baseinfo.get_packages(pattern).reject { |e| !self.exists?(File.basename(e)) }
    list.collect! { |fullname| File.basename(fullname) }
    return list.sort
  end

  # TODO: Add game arch engine?
  def public_file?(filename)
    return !filename.split("/").include?("addons")
  end
end

