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

class BSP

  QUAKE_VALVE_GOLDSRC = 30
  BSP_HEADER_ENTITIES = 0
  BSP_HEADER_MIPTEX = 2

  def self.read_dentry
    @stream.read(8).unpack("II")
  end

  def self.read_uint
    # read an unsigned integer
    @stream.read(4).unpack("I")[0]
  end

  def self.read_string(size)
    @stream.read(size).unpack("Z*")[0]
  end
  
  def self.read_header
    @stream.seek(0)
    raise "This file is not a valve bsp map" if read_uint != QUAKE_VALVE_GOLDSRC
    @header = []
    15.times { @header.push read_dentry }
  end

  def self.read_mipheader
    @stream.seek(@header[BSP_HEADER_MIPTEX][0])
    @mip_offset = []
    read_uint.times { @mip_offset.push read_uint + @header[BSP_HEADER_MIPTEX][0] }
  end

  def self.read_mips
    textures = []
    @mip_offset.each do |startpos|
      @stream.seek(startpos)
      name = @stream.read(16).unpack("Z*")[0].downcase

      height, width, offset1, offset2, offset3, offset4 = @stream.read(6*4).unpack("L"*6)
      #p [height, width]
      #p [offset1, offset2, offset3, offset4]
      textures.push name if (offset1 == 0)
      #puts name

    end
    return textures
  end

  def self.read_entity_entries
    @stream.seek(@header[BSP_HEADER_ENTITIES][0])
    entities = read_string(@header[BSP_HEADER_ENTITIES][1])
    return EntityParser.get_files(EntityParser.parse(entities))
  end

  def self.get_info(stream)
    @stream = stream

    read_header
    wads, files = read_entity_entries
    read_mipheader
    textures = read_mips

    return wads, files, textures
  end

end

class WAD
  def self.read_magic
    @stream.read(4).unpack("Z4")[0]
  end

  def self.read_integer
    # read an unsigned integer
    @stream.read(4).unpack("I")[0]
  end

  def self.get_entries(stream)
    @stream = stream
    @stream.seek(0)
    raise "The file supplied has no wad" if read_magic != "WAD3"
    numentries = read_integer
    offset = read_integer

    @stream.seek(offset)
    names = []
    numentries.times do
      names.push @stream.read(4 + 4 + 4 + 1 + 1 + 2 + 16).unpack("IIIccsZ*").last
    end
    return names
  end
end

class EntityParser
  SKY_END = [ "bk", "ft", "dn", "up" , "rt", "lf" ]
  def self.parse(text)
    entities = []
    entity = nil
    text.each_line do |line|
      case line.chop
      when "{"
        entity = {}
      when "}"
        entities.push(entity)
      when /"(.+|)" "(.+|)"/
        entity[$1] = $2
      else
      end
    end
    return entities
  end
  
  def self.get_files(entities)
    # TODO: find gibmodels

    # get the mdl's and sprites
    tmp = entities.collect { |entity| entity["model"] if entity.has_key?("model") }.uniq
    tmp.delete(nil)
    files = tmp.collect { |file| file if !(file =~ /\*\d+/) }.uniq
    files.delete(nil)

    if entities[0].has_key?("skyname")
      files += SKY_END.collect { |ending| "gfx/env/" + entities[0]["skyname"] + ending + ".tga" }
    end

    wads = []
    if entities[0].has_key?("wad")
      wads = entities[0]["wad"].split(";").collect { |i| i.split("\\").last }
    end

    entities.shift
    entities.each do |entity| 
      if entity.has_key?("message")
        sound = "sound/" + entity["message"]
        files.push sound
      end

    end
    
    return [wads, files.sort!]
  end
end

class Overview
  KEYWORDS = ["global", "ZOOM", "ORIGIN", "ROTATED", "layer", "IMAGE", "HEIGHT"]
  def self.check(file)
    File.open(file) do |text|
      text = text.read
      arr = KEYWORDS.collect { |keyword| text.include?(keyword) }.uniq
      return arr.first && arr.size == 1
    end
  end
end
