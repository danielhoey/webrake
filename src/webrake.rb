
def layout(source, layout)
  layout = "layout/#{layout}"
  output = "output/#{source}"
  source = "source/#{source}"
  file output => [layout, source, 'output'] do |t|
    @content = File.read(source)
    @modify_time = File.mtime(source)
    layout = ERB.new(File.read(layout))
    write_file(output, layout.result(binding))
  end
end

def markdown(source)
  output = "source/#{File.basename(source, '.*')}.html"
  source = "source/#{source}"
  CLOBBER.include(output)
  file output => source do |t|
    content = Kramdown::Document.new(File.read(source)).to_html
    write_file(output, content, File.mtime(source))
  end
end

def write_file(filename, content, mtime=nil)
  File.open(filename, 'w+') {|f| f << content}
  File.utime(mtime, mtime, filename) if mtime
end
