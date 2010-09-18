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

class CliInvoker
  public
  def initialize(klass)
    @klass = klass
    @methods = klass.public_methods - Class.public_methods
  end

  def run(args)
    name = []
    
    methods = @methods

    x = 0
    while (methods.size > 1)
      methods = collect_start(methods, ARGV[x])
      methods = trunc(methods, ARGV[x].to_s)
      name.push ARGV[x]
      
      if (methods.size == 1)
        funcname = name.join("_")
        arguments = ARGV[x+1..9999].join(" ")

        if arguments.size == 0
          evalstr = "@klass.#{funcname}"
      
        else
          evalstr = "@klass.#{funcname}(#{arguments.inspect})"
        end
        # puts evalstr
        # puts
        eval(evalstr)
        return
      end
      x += 1
    end
    puts "gelendra: did not understand you, maybe you want need some help? gelendra help"
  end

  private 
  def trunc(methods, arg)
    methods.collect { |name| name.split("_")[1...9999].join("_") }
  end

  def starts_with(fullname, startstr)
    fullname.split("_").first == startstr
  end
  
  def collect_start(methods, startstr)
    methods.reject { |func| !starts_with(func, startstr) }
  end
end


class Cli
  public
  def initialize(baseinfo, localinfo)
    @baseinfo = baseinfo
    @localinfo = localinfo
    @pm = PackageManager.new(localinfo)
    # @localinfo = localinfo
    #@manager = manager
  end

  def zip_rebase
    @pm.rebase
  end

  def zip_check
    @pm.check
  end

  def package_install(name = "*")
    @baseinfo.get_packages(name).each do |name| 
      begin
        puts
        puts "Installing #{name}"
        @pm.install(name)
      rescue => msg
        puts "\tError during installation: #{msg}"
      end
    end
  end

  def package_remove(name = "*")
    @localinfo.get_packages(name).each do |package|
      begin
        puts
        puts "Removing #{package}"
        @pm.remove(package)
      rescue => msg
        puts "Error during removing: #{msg}"
      end
    end
  end

  def package_check(name = "*")
    @baseinfo.get_packages(name).each do |package|
    begin
      puts
      puts "Checking #{package}"
      @pm.package_check(package)
    rescue => msg
      puts "Error during checking: #{msg}"
    end
    end
  end

  def package_available(name = "*")
    puts @baseinfo.get_packages(name)
  end

  def package_list(name = "*")
    puts @localinfo.get_packages(name)
  end

  def basedir_add(dir)
    if File.directory?(dir)
      dir = File.expand_path(dir)
      if !@baseinfo.base_dir.include?(dir)
        @baseinfo.base_dir.push File.expand_path(dir)
        @baseinfo.save
      else
        puts "Directory already in basedir path: #{dir}"
      end
    else
      puts "No such directory: #{dir}"
    end
  end

  def basedir_rem(dir)
    dir = File.expand_path(dir)
    
    if @baseinfo.base_dir.include?(dir)
      @baseinfo.base_dir.delete(dir)
      @baseinfo.save
      puts "basedir removed: #{dir}"
    else
      puts "No such directory in database: #{dir}"
    end
  end

  def basedir_list
    puts "Base directories remembered:\n"
    puts
    puts @baseinfo.base_dir
    puts
  end

  alias :list_packages :package_list

  def list_files
    puts @localinfo.all_files
  end

  def list_installedpackages(pattern = "*")
    puts @baseinfo.get_packages(pattern)
    puts @localinfo.get_packages(pattern)
  end
  
  def list_availablepackages(pattern = "*")
    puts @baseinfo.get_packages(pattern)
  end

  # TODO: Add game arch engine?
  def list_allmaps
    puts mapify(allmaps)
  end

  def list_installedmaps
    puts mapify(allmaps.reject { |m| !@localinfo.all_files.include?(m)})
  end

  def list_basemaps    
    puts mapify(allmaps.reject { |m| @localinfo.all_files.include?(m)})
  end

  # TODO: add zip checking 

  def database_fix
    @localinfo.archives.each do |archive|
      @localinfo.files(archive).each do |file|
        if !File.exists?(file)
          puts "#{file} does not exist though it occures in database, deleting"
          @localinfo.delete(archive, file)
        end

        if File.directory?(file)
          puts "#{file} is actually a directory, removing from database"
          @localinfo.delete(archive, file)
        end
      end
    end
    @localinfo.save
  end

  def database_check
    @localinfo.archives.each do |archive|
      @localinfo.files(archive).each do |file|
        puts "#{file} does not exist though it occures in database" if !File.exists?(file)
        puts "#{file} is a actually a directory" if File.directory?(file)
      end
    end
  end

  def softlink_base(basedir, pattern = "*")
    # TODO: rewrite localinfo
    puts pattern
    @localinfo.get_packages(pattern).each do |package|
      puts @localinfo.files(package)
    end
  end

  def softlink_rebase

  end

  def help
    puts <<HELPSTRING
Copyright (C) 2010 Andrius Bentkus
This program comes with ABSOLUTELY NO WARRANTY; 
This is free software, and you are welcome to redistribute it
under certain conditions; read the file 'LICENSE' for further details

  basedir add <directory>
    remembers a directory, where it will look for packages

  basedir rem <directory>
    removes a basedir directory

  basedir list
    lists all added basedirs

  package install <package>
    extracts package in the current directory and puts all the data to the local database

  package remove <package>
    removes the extracted package files

  package list <pattern>
    lists all locally installed packages using the pattern, if not pattern provided, all are listed

  package available <pattern>
    lists all available packages using the pattern, if no pattern provided, all are listed

  zip check
    checks if all installed files are in the zip file specified in database

  zip rebase
    adds missing files to the zip file specified in database

  list availablepackages
    lists all available packages in basedirectories

  list installedpackages
    lists locally installed packages
  
  list allmaps
    lists all installed maps

  list installedmaps
    lists all maps that were installed using gelendra

  list basemaps
    lists maps that were installed without gelendra

  database check
    checks the local database for any errors (occuring directories, missing files)

  database fix
    removes occuring directories from database
    removes files which are missing in database
    removes database entries of files which are not present

  help
    prints this help
  
HELPSTRING
  end

  private
   
  def mapify(maps)
    maps.collect do |i|
      f = File.basename(i) 
      f = f.split(".")
      f.pop
      f = f.join(".")
      f
    end
  end

  def allmaps
    Dir["cstrike/maps/*.bsp"].sort
  end

end

