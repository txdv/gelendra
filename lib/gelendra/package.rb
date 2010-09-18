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

class Package
  def initialize(fullfilename)
    @fullfilename = fullfilename
  end

  def open
    @zip = Zip::ZipFile.open(@fullfilename, "r")
  end

  def close
    @zip.close
  end

  def get_info_from_bsp
    
    return BSP.get_info(get_bsp.get_input_stream) if is_map?
    return nil
  end

  def get_files_from_zip
    @zip.entries.reject { |e| e.is_directory }.collect { |e| e.name.shift("/") }.sort
  end

  def is_map?
    !get_bsp.nil?
  end


  def get_bsp
    bsp = nil
    @zip.entries.each do |entry|
      if File.extname(entry.name) == ".bsp"
        return entry
      end
    end
    return nil
  end
  
  def get_wad_entries
    return @zip.entries.reject { |e| File.extname(e.name) != ".wad" }
  end
end

class PackageManager
  def initialize(localinfo)
    @localinfo = localinfo
  end

  def package_check(package)
    pack = Package.new(package)
    pack.open
    
    if (!pack.is_map?)
      pack.close
      return
    end

    bsp_wads, files, textures = pack.get_info_from_bsp

    #p pack.get_files_from_zip
    files.each do |file|
      file = file.downcase
      if BaseInfo.instance.include?(file)
        #puts "Found in base directory"
      elsif pack.get_files_from_zip.include?(file)
        #puts "Found in zip archive" 
      else
        #p pack.get_files_from_zip
        puts "File missing: #{file}"
      end

    end
    
    all_wads = BaseInfo.instance.wads
    
    maybe = bsp_wads.clone

    bsp_wads.each do |wad|
      if all_wads.include?(wad)
        maybe.delete(wad)
        textures -= all_wads[wad] if all_wads.include?(wad)
      end
    end

    pack.get_wad_entries.each do |entry|
      textures -= WAD.get_entries(entry.get_input_stream)
      maybe.delete(entry.name)
    end

    if textures.size > 0
      puts "Critical error: Missing textures #{textures.join(", ")}"
      puts "                The bsp map suggestes that these files are in #{maybe.join(", ")}"
    end
  end

  def remove(package)
    filelist =  @localinfo.files(package)
    filelist.each do |file| 
      if (!File.directory?(file))
        if File.exists?(file)
          puts "\tremoving #{file}"
          FileUtils.rm file
        else
          puts "\tWarning: #{file} does not exist, can't remove"
        end
        get_directories(file).sort.reverse.each do |dir|
          puts "\tdeleting directory #{dir} since empty"
          FileUtils.rmdir dir if File.exists?(dir) and dir_empty(dir)
        end
      end
    end
    @localinfo.delete(package)
    @localinfo.save
    
    if !@localinfo.zipfile.nil?
    Zip::ZipFile.open(@localinfo.zipfile, "wb") do |outputfile|
      filelist.each do |file| 
        puts "\tremoving #{file} from #{@localinfo.zipfile}"
        if !outputfile.find_entry(file).nil?
          outputfile.remove(file)
        else
          puts "\tWARNING: #{@localinfo.zipfile} file does not exist in archive"
        end
      end
    end
    end
  end

  def install(filefullpath)
    filename = File.basename(filefullpath)
    raise "Package #{filename} already installed!" if @localinfo.exists?(filename)

    filelist = nil
    Zip::ZipFile.open(filefullpath) { |package| 
      # filelist = package.entries.collect { |x| x.name }
      filelist = package.entries.reject { |e| e.directory? }.collect { |x| x.name }.sort
      @localinfo.add(filename, filelist)

      # create all directories if not existend
      filelist.each { |entry| get_directories(entry).each { |dir| install_dir dir } }
      
      # TODO: sort entry names
      package.entries.each do |entry|
        if !entry.directory?
          puts "\textracting file #{entry.name}" 
          if !File.exists?(entry.name)
            entry.extract
          else
            puts "\tWARNING: file #{entry.name} already exists, omitting"
          end
        end
      end
    }
    @localinfo.save

    # modify the giant zip file
    if !@localinfo.zipfile.nil?
    Zip::ZipFile.open(@localinfo.zipfile, "wb") do |outputfile| 
      filelist.each do |name|
        if !@localinfo.public_file?(name)
          puts "\tomitting private file #{name}"
        else
          puts "\tadding #{name} to #{@localinfo.zipfile}"
          if outputfile.find_entry(name).nil?
            outputfile.add(name, name)
          else
            puts "\tWARNING: file #{name} in #{@localinfo.zipfile} already exists"
          end
        end
=begin
        puts "\tadding #{name} to #{@localinfo.zipfile}"
        if outputfile.find_entry(name).nil?
          outputfile.add(name, name)
        else
          puts "\tWARNING: file #{name} in #{@localinfo.zipfile} already exists"
        end
=end
      end
    end
    end
  end

  def one_less(file_or_dir)
    base = File.basename(file_or_dir)
    return file_or_dir[0..file_or_dir.size-base.size-2]
  end
  def one_less?(file_or_dir)
    base = File.basename(file_or_dir)
    return file_or_dir.size-base.size-2 > 0
  end

  def get_directories(file)
    filename = File.basename(file)
    dirname = one_less(file)

    dirs = [dirname]

    while (one_less?(dirname))
      dirname = one_less(dirname)
      dirs.push dirname
    end
    
    return dirs.sort
  end

  def install_dir(dir)
    FileUtils.mkdir(dir) if !File.directory?(dir)
  end
  
  def dir_empty(dir)
    Dir.entries(dir).join == "..."
  end


  def zipfile_iterate
    if !@localinfo.zipfile.nil?
    Zip::ZipFile.open(@localinfo.zipfile, "wb") do |outputfile|
      @localinfo.all_public_files.each do |file|
        yield(outputfile, file)
      end
    end
    end
  end

  def rebase
    zipfile_iterate do |outputfile, file|
        if outputfile.find_entry(file).nil?
          puts "#{@localinfo.zipfile}: missing and adding #{file}"
          outputfile.add(file, file)
          outputfile.commit # makes it more interactive
        end
    end
  end

  def zipfile
    @localinfo.zipfile
  end

  def check
    zipfile_iterate do |outputfile, file|
      if outputfile.find_entry(file).nil?
        puts "#{file} does not exist in #{zipfile}"
      end
    end
  end

end

