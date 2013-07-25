
class InputFiles < Struct.new(:base_dir, :file_system, :file_list)
  def find(glob)
    glob = "**/#{glob}" if glob =~ /^\*/
    glob = base_dir_path.join(glob).cleanpath.to_s
    result = file_system.file_list(glob)
    file_list.each do |f| 
      result.add(f) if File.fnmatch(glob, f, File::FNM_PATHNAME | File::FNM_DOTMATCH)
    end
    return result
  end

  def base_dir_path
    @base_dir_path ||= Pathname.new(base_dir)
  end
end

if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
class InputFilesTest < Minitest::Test
  def test_input_files
    file_system = Minitest::Mock.new
    file_list = []
    input_files = InputFiles.new('', file_system, file_list)

    file_system.expect(:file_list, FileList['file1'], ['file*'])
    assert_equal(%w(file1), input_files.find('file*'))

    file_list << 'file2'
    file_system.expect(:file_list, FileList['file1'], ['file*'])
    assert_equal(%w(file1 file2), input_files.find('file*'))

    file_system.expect(:file_list, FileList[], ['file*'])
    assert_equal(%w(file2), input_files.find('file*'))
  end

  def test_recursive_glob
    file_system = Minitest::Mock.new
    file_list = []
    input_files = InputFiles.new('', file_system, file_list)
    
    file_system.expect(:file_list, FileList[], ['**/*'])
    assert_equal([], input_files.find('*'))
    
    file_list << 'anything'
    file_system.expect(:file_list, FileList[], ['**/*'])
    assert_equal(%w(anything), input_files.find('*'))
  end

end
end
