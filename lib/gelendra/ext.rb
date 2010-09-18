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

class String

  def shift(char)
    tmp = self.split(char)
    tmp.shift
    return tmp.join(char)
  end

  def basename
    return File.basename(self)
  end

  def base
    return File.basename(self, self.extname)
  end

  def extname
    return File.extname(self)
  end

end

class Dir
  def self.find_all_files(directory)
    files = Dir[directory + "*"]
    files.each do |fname|
      files += find_all_files(fname + "/") if (File.directory?(fname))
    end
    return files.reject { |f| File.directory?(f) }
  end
end

class Array
  def create_filemap
    map = {}
    self.each do |file|
      name = file.basename

      if map.has_key?(name)
        map[name].push file
      else
        map[name] = [file]
      end

    end
    return map
  end

  def basename
    self.collect { |f| f.basename }
  end
end

class Hash
  def initialize(filelist)
    filelist.each do |file| 
      name = file.basename
      if self.has_key?(name)
        self[file.basename].push file
      else
        self[file.basename] = [file]
      end
    end
  end

  def clashes
    self.each do |file, files|
      yield(files) if files.size > 1
    end
  end

  def find_missing_files(files)
    files.basename.reject { |file| self.has_key?(file) }
  end

end
