
class FileSystem
  def read(path); File.read(path); end
  def mtime(path); File.mtime(path); end
  def write(path, contents, mod_time=nil)
    File.open(path, 'w+'){|f| f << contents}
    File.utime(mod_time, mod_time, path) if mod_time
  end
end
