require "spec_helper.rb"
require "pathname"
require "fastimage"
require "shellwords"

RSpec.describe 'get_status_bar tool', :type => :aruba do
  
  include Aruba::Api
  
  let(:root) { Pathname.new(__FILE__).parent.parent }
  let(:resource_dir_path) { Pathname.new(__FILE__).parent.join('res') }
  
  context 'aruba must be available' do
    it { expect(aruba).to be }
  end
  
  context 'CLI' do
    before(:all) { 
      # root_path = Pathname.new(__FILE__).parent.parent
      # ENV['PATH'] = "#{root_path.join('exe').to_s}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
    }
    
    let(:output_error_no_args) { "no arguments specified; use -? or --help arguments to see help" }
    let(:output_error_no_input) { "no input file name is specified" }
    let(:output_error_no_height) { "no status bar height is specified or provided height value is invalid" }
    let(:output_error_invalid_height) { "status bar height value is invalid" }
    let(:output_error_no_output) { "no output file name is specified" }
    let(:output_error_input_file_not_exists) { "input file does not exist" }
    let(:output_error_output_file_already_exists) { "output file already exists" }
    let(:input_file_name) { "some" }
    let(:output_file_name) { "output" }
    
    context 'given no arguments' do
      it 'returns an error about missing --input parameter' do
        run("get_status_bar")
        expect(last_command_started).to have_output output_error_no_args
        expect(last_command_started).not_to have_exit_status(0)
      end
    end
    
    context 'given a single -? argument' do
      it 'prints out help' do
        run "get_status_bar -?"
        expect(last_command_started).to have_output an_output_string_matching("^Usage: get_status_bar")
        expect(last_command_started).to have_exit_status(0)
      end
    end
    
    context 'given a single --help argument' do
      it 'prints out help' do
        run "get_status_bar --help"
        expect(last_command_started).to have_output an_output_string_matching("^Usage: get_status_bar")
        expect(last_command_started).to have_exit_status(0)
      end
    end
    
    context 'given a multiple arguments including -?' do
      it 'prints out help' do
        run "get_status_bar --input=some -?"
        expect(last_command_started).to have_output an_output_string_matching("^Usage: get_status_bar")
        expect(last_command_started).to have_exit_status(0)
      end
    end
    
    context 'given only --input argument' do
      it 'returns an error about missing --height parameter' do
        run "get_status_bar --input=some"
        expect(last_command_started).to have_output output_error_no_height
        expect(last_command_started).not_to have_exit_status(0)
      end
    end
    
    context 'given --height argument value' do
      it 'returns an invalid height value error if height is 0' do
        run "get_status_bar --input=some --height=0"
        expect(last_command_started).to have_output output_error_invalid_height
        expect(last_command_started).not_to have_exit_status(0)
      end
      
      it 'returns an invalid height value error if height is < 0' do
        run "get_status_bar --input=some --height=-20 --output=another"
        expect(last_command_started).to have_output output_error_invalid_height
        expect(last_command_started).not_to have_exit_status(0)
      end
    end
    
    context 'given only --input and valid --height argument' do
      it 'returns an error about missing --output parameter' do
        run "get_status_bar --input=some --height=20"
        expect(last_command_started).to have_output output_error_no_output
        expect(last_command_started).not_to have_exit_status(0)
      end
    end
    
    context 'given non-existing file as --input argument' do      
      it 'returns an error about non-existing input file' do
        run "get_status_bar --input=#{input_file_name} --height=20 --output=output"
        expect(last_command_started).to have_output output_error_input_file_not_exists
        expect(last_command_started).not_to have_exit_status(0)
      end
    end
    
    context 'given already existing file as --output argument' do
      
      before(:each) { 
        touch(input_file_name) 
        touch(output_file_name)
      }
      
      after(:each) {
        remove(input_file_name) if exist?(input_file_name)
        remove(output_file_name) if exist?(output_file_name)
      }
      
      it 'returns an error about output file does exist already' do
        run "get_status_bar --input=#{input_file_name} --height=20 --output=output"
        expect(last_command_started).not_to have_exit_status(0)
        expect(last_command_started).to have_output output_error_output_file_already_exists
      end
    end
    
    
    context 'given an image as input and specified height' do
      let(:input_image_path) { resource_dir_path.join('test-screenshot.jpg').realpath }
      let(:input_image_path_escaped) { input_image_path.to_s.shellescape }
      let(:test_height) { 60 }
      let(:output_image_name) { "output.jpg" }
      let(:src_width) { FastImage.size(input_image_path).first }
      
      before(:each) {
        remove(output_image_name) if exist?(output_image_name)
      }
      
      after(:each) {
        remove(output_image_name) if exist?(output_image_name)
      }
      
      context 'creates a new image' do
        it 'which must exist' do
          run "get_status_bar --input=#{input_image_path_escaped} --height=#{test_height} --output=#{output_image_name}"
          stop_all_commands
          
          expect(last_command_started).to have_exit_status(0)
          expect(output_image_name).to be_an_existing_file
        end
      
        it 'which is the crop all width of the input + has specified height' do
          run "get_status_bar --input=#{input_image_path_escaped} --height=#{test_height} --output=#{output_image_name}"
          
          stop_all_commands
        
          output_image_path = expand_path(output_image_name)
          output_size = FastImage.size(output_image_path)
          expect(output_size.first).to be_equal(src_width)
          expect(output_size.last).to be_equal(test_height)
        end
      end 
    end
    
  end
  
end
