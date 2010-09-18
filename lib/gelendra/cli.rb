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

# Functionality:
# TODO: Check if the files in the archives are all in small letters
# TODO: Add a function to downcase all files in a archive file
# TODO: Support different archives, create OOP archive control
# TODO: Add function which copies all files logged in database to another directory
# TODO: Add database file softlinking
# TODO: Add package checking (read entities!) (check if this feature is complete)
# TODO: Add a package creator: you select a dir with files, it finds all bspmaps and
#       creates a lot of packages into a destination dir (only complete ofcourse)
#       REMARK: this is done, but we need to check now for double occurences of files
#       and a lot of bsp's rise exceptions, I have to check this out
# TODO: Add clver clash resolver

# CliInvoker:
# TODO: Adjust CliInvoker to better work (let single command lines work)
# TODO: Add command line function help definition support in CliInvoker

# Misc:
# TODO: Add independent game architecture (list maps of other games, pick only public files)
# TODO: Manage occurences in different archives (ALLOW THEM! if files are equal)


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
        arguments = ARGV[x+1..ARGV.size].join('", "')

        if arguments.size == 0
          evalstr = "@klass.#{funcname}"
        elsif arguments.size == 1
          evalstr = "@klass.#{funcname}(#{arguments.inspect})"
        else
          evalstr = "@klass.#{funcname}(\"#{arguments}\")"
        end
        #puts arguments
        #puts evalstr
        #puts
        eval(evalstr)
        return
      end
      x += 1
    end
    puts "gelendra: did not understand you, maybe you need some help? type gelendra help"
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

=begin
  def softlink_base(basedir, pattern = "*")
    # TODO: rewrite localinfo
    puts pattern
    @localinfo.get_packages(pattern).each do |package|
      puts @localinfo.files(package)
    end
  end

  def softlink_rebase

  end
=end


  # TODO: manage double occurences of files
  def package_create(bspfile, src, dst)
    
    puts "Checking files for #{bspfile} ..."
    #mapping = basename_map(all_files_in_dir(src))
    mapping = Dir.find_all_files(src).create_filemap
    mapping_package_create(mapping, bspfile)
  end

  def mapping_package_create(mapping, bspfile)

    fd = File.open(bspfile)
    mapwads, mapfiles, maptextures = BSP.get_info(fd)
    # mapwads in maps can have prefixes
    mapwads = mapwads.collect { |mapwad| mapwad.basename }
    fd.close

    # get rid of files that are allaready packaged
    mapfiles.reject! { |file| @baseinfo.include?(file) }

    # if a file has a leading /, delete it, yeah I have a bsp file
    # which is compiled with shit like that
    mapfiles.collect! { |file| file.gsub(/^\//, "") }
    
    wad_texture_map = resolve_textures(resolve_wads(mapping, mapwads), maptextures)
    
    found_textures = wad_texture_map.values.flatten.uniq
    found_textures.delete nil

    missing_textures = maptextures - found_textures
    missing_files = mapping.find_missing_files(mapfiles)

    ret = { :wadfiles => {}, :files => {}, :errors => {}, :bspfile => bspfile }

    # get all files which EXIT and have some of the needed textures
    # leave the empty wad references alone
    (wad_texture_map.reject { |k,v| v.nil? or v.empty? }.keys - @baseinfo.default_wads).each do |f|
      ret[:wadfiles][f] = mapping[f]
    end

    mapfiles.each do |file|
      ret[:files][file] = mapping[file.basename]
    end

    if !missing_textures.empty?
      # some textures are missing, and we cant find them, suggest some
      ret[:errors][:missing_wads] = wad_texture_map.reject { |k,v| !v.nil? }.collect { |k,v| k }
      ret[:errors][:missing_textures] = missing_textures
    end

    if !missing_files.empty?
      ret[:errors][:missing_files] = missing_files
    end

    return ret
  end

  def unclash(files)
    i = 0
    while i < files.size
      j = i+1
      while j < files.size
        files.delete(files[j]) if File.compare(files[i], files[j])
        j += 1
      end
      i += 1
    end
  end

  # valid extensions for maps
  VALID_EXT = [".bmp", ".bsp", ".mdl", ".spr", ".tga", ".txt", ".wad", ".wav"]
  def create_packages(src, dst)

    mapping = Dir.find_all_files(src).reject { |file| !VALID_EXT.include?(file.extname) }.create_filemap
    
    @overviews = []

    mapping.each do |basename, files|
      if files.size == 1 then
        mapping[basename] = files.first
      else
        files = files.reject { |file| Overview.check(file) }
        if files.size == 1
          mapping[basename] = files.first
        else
          unclash(files)
          if files.size != 1
            puts "#{files.inspect} clash, remove some"
            mapping.delete(basename)
          end
        end
      end
    end

    rets = []
    file_count = 0
    error_count = 0
    mapping.each do |file, fullname|
      begin
      if file.extname == ".bsp"
        print "Checking #{file} ... "
        rets.push mapping_package_create(mapping, fullname)
        file_count += 1

        if !rets.last[:errors].empty?
          error_count += 1
          puts "invalid"
        else
          puts "valid"
        end

      end
      rescue => error
        puts "Some error occured: #{error}"
      end
    end
    puts "#{file_count - error_count} of #{file_count} bsp files can be packaged"
    rets.each do |package|
      if package[:errors].empty? then
        create_zip_package(package, dst)
      end
    end
  end
  
  # gets a hash with correct file entries and creates a zip file
  def create_zip_package(pkg, dst)
    begin
    name = pkg[:bspfile].base + ".zip"
    fullname = dst + name
    puts "Creating #{fullname}"
    Zip::ZipFile.open(fullname, Zip::ZipFile::CREATE) do |zip|
      src = pkg[:bspfile]
      dst = "maps/" + src.basename

      if zip.find_entry(dst).nil?
        zip.add(dst, src)
      end

      pkg[:files].each do |dst,src|
        if zip.find_entry(dst).nil?
          zip.add(dst, src)
        end
      end

      pkg[:wadfiles].each do |dst,src|
        if zip.find_entry(dst).nil?
          zip.add(dst, src)
        end
      end
    end

    rescue => error

    p error
    p pkg

    end
  end

  def create_package(bla)

  end

  private

  # gets a hash of (wads => [textures]) and returns all textures
  def found_textures(map_texture_mapping)
    #ret = map_texture_mapping.collect { |k, v| v }.flatten.uniq
    ret = map_texture_mapping.values.flatten.uniq
    ret.delete nil
    return ret
  end

  # a filemapping
  # a list of wads
  # returns a hash of wads => textures(wads)
  def resolve_wads(mapping, wads)
    wadmap = {}
    wads.each do |wad|
      if (@baseinfo.wads.has_key?(wad))
        wadmap[wad] = @baseinfo.wads[wad]
      elsif (mapping.has_key?(wad))
        File.open(mapping[wad]) { |fd| wadmap[wad] = WAD.get_entries(fd) }
      else
        wadmap[wad] = nil
      end
    end
    return wadmap
  end
  # wad => textures mapping
  def resolve_textures(wads, map_textures)
    resolved_textures = {}
    i = map_textures
    wads.each do |wad, wad_textures|
      if (wad_textures.nil?)
        resolved_textures[wad] = nil
      else
        found = map_textures - (map_textures - wad_textures)
        resolved_textures[wad] = found
      end
    end
    return resolved_textures
  end

  public

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

  package install <pattern|package>
    extracts a package in the current directory and puts all the data to the local database
    or all packages matching the pattern

  package remove <pattern|package>
    removes the extracted package files, or all packages matching the pattern

  package list <pattern>
    lists all locally installed packages using the pattern, if no pattern provided, all packages are listed

  package available <pattern>
    lists all available packages using the pattern, if no pattern provided, all are listed

  list allmaps
    lists all installed maps

  list availablepackages
    lists all available packages in basedirectories

  list basemaps
    lists maps that were installed without gelendra

  list installedmaps
    lists all maps that were installed using gelendra

  list installedpackages
    lists locally installed packages
  
  list packages <pattern>
    lists all locally installed packages using the pattern, if not pattern provided, all are listed

  database check
    checks the local database for any errors (occuring directories, missing files)

  database fix
    removes occuring directories from database
    removes files which are missing in database
    removes database entries of files which are not present

  zip check
    checks if all installed files are in the zip file specified in database

  zip rebase
    adds missing files to the zip file specified in database

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

