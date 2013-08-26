require 'fileutils'

module Webrake
class FileSystem
  include FileUtils

  def initialize(root_dir=nil)
    @root_dir = File.expand_path(root_dir)
  end

  def read(path)
    in_root_dir{ return File.read(path) }
  end

  def mtime(path)
    in_root_dir { return File.mtime(path) }
  end

  def write(path, contents, mod_time=nil)
    in_root_dir {
      mkdir_p(File.dirname(path))
      File.open(path, 'w+'){|f| f << contents}
      File.utime(mod_time, mod_time, path) if mod_time
    }
  end

  def copy(src, target)
    in_root_dir { cp(src, target) }
  end

  def mkdir(dir)
    in_root_dir { mkdir_p(dir) }
  end

  def remove_all(paths)
    in_root_dir { paths.each { |f| rm_r f rescue nil } }
  end

  def file_list(glob)
    in_root_dir { return FileList[glob] }
  end

  def in_root_dir
    if @root_dir.nil?
      yield
    else
      dir = Dir.pwd
      Dir.chdir(@root_dir) 
      yield
      Dir.chdir(dir)
    end
  end
end
end
