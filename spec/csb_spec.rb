require "spec_helper.rb"
require "pathname"
require "fastimage"
require "shellwords"

describe CleanyStatus do
  it "has a version number" do
    expect(CleanyStatus::VERSION).not_to be nil
  end
end

RSpec.describe 'csb tool', :type => :aruba do
  
  include Aruba::Api
  
  let(:root) { Pathname.new(__FILE__).parent.parent }
  let(:resource_dir_path) { Pathname.new(__FILE__).parent.join('res') }
  
  context 'aruba must be available' do
    it { expect(aruba).to be }
  end
  
  context 'CLI' do

    let(:output_error_no_args) { "no arguments specified; use -? or --help arguments to see help" }
    let(:output_error_input_image_fail) { "failed to open the input file:" }
    let(:output_error_no_status_bar) { "no status bar image specified, use -s option" }
    let(:output_error_status_bar_image_fail) { "failed to open the status bar image file:" }
    let(:output_error_no_output) { "no output specfied, use -o option" }
    let(:output_error_input_image_invalid_height) { "input image height is less than status bar image height; aborting" }
    let(:output_error_input_image_invalid_width) { "input image width does not match status bar image width; aborting" }
    let(:output_error_output_already_exist) { "output file alread exists:" }
    
    context 'given no arguments' do
      it 'returns an error about missing arguments' do
        run("csb")
        expect(last_command_started).to have_output output_error_no_args
        expect(last_command_started).not_to have_exit_status(0)
      end
    end
    
    context 'given a single -? argument' do
      it 'prints out help' do
        run "csb -?"
        expect(last_command_started).to have_output an_output_string_matching("^Usage: csb")
        expect(last_command_started).to have_exit_status(0)
      end
    end
    
    context 'given an image as input' do
      let(:input_image_path) { resource_dir_path.join('input-screenshot.jpg').realpath }
      let(:input_image_path_escaped) { input_image_path.to_s.shellescape }
      
      it 'returns an error if input image name is empty' do
        run "csb -i"
        expect(last_command_started).to have_output an_output_string_matching(".*missing argument: -i.*")
        expect(last_command_started).not_to have_exit_status(0)
      end
      
      it 'returns an error if input image does not exist or cannot be opened' do
        run "csb -i=some"
        expect(last_command_started).to have_output an_output_string_matching("^#{output_error_input_image_fail}")
        expect(last_command_started).not_to have_exit_status(0)
      end
      
      it 'returns an error if no status bar image is specified' do
        run "csb --input=#{input_image_path_escaped}"
        expect(last_command_started).to have_output output_error_no_status_bar
        expect(last_command_started).not_to have_exit_status(0)
      end
      
      it 'returns an error if status bar image name is empty' do
        run "csb --input=#{input_image_path_escaped} -s"
        expect(last_command_started).to have_output an_output_string_matching(".*missing argument: -s.*")
        expect(last_command_started).not_to have_exit_status(0)
      end
      

      
      context 'give an image as status bar' do
        let(:input_invalid_height_image_path) { resource_dir_path.join('input-invalid_height-screenshot.jpg').realpath }
        let(:input_invalid_height_image_path_escaped) { input_invalid_height_image_path.to_s.shellescape }
        let(:input_invalid_width_image_path) { resource_dir_path.join('input-invalid_width-screenshot.jpg').realpath }
        let(:input_invalid_width_image_path_escaped) { input_invalid_width_image_path.to_s.shellescape }
        let(:status_bar_image_path) { resource_dir_path.join('input-status-bar.jpg').realpath }
        let(:status_bar_image_path_escaped) { status_bar_image_path.to_s.shellescape }
        let(:output_image_name) { "csb-output.jpg" }
        
        before(:each) {
          remove(output_image_name) if File.exist?(output_image_name)
        }
        
        after(:each) {
          remove(output_image_name) if File.exist?(output_image_name)
        }
        
        it 'returns an error if status bar image does not exist or cannot be opened' do
          run "csb --input=#{input_image_path_escaped} --status-bar=some"
          expect(last_command_started).to have_output an_output_string_matching("^#{output_error_status_bar_image_fail}")
          expect(last_command_started).not_to have_exit_status(0)
        end
        
        it 'returns an error if output path is not specified' do
          run "csb --input=#{input_image_path_escaped} --status-bar=#{status_bar_image_path_escaped}"
          expect(last_command_started).to have_output output_error_no_output
          expect(last_command_started).not_to have_exit_status(0)
        end
        
        it 'returns an error if output path point to already existing file' do
          run "csb --input=#{input_image_path_escaped} --status-bar=#{status_bar_image_path_escaped} --output=#{status_bar_image_path_escaped}"
          expect(last_command_started).to have_output an_output_string_matching("^#{output_error_output_already_exist}")
          expect(last_command_started).not_to have_exit_status(0)
        end
        
        it 'returns an error if input image height is less than status bar image height' do
          run "csb --input=#{input_invalid_height_image_path_escaped} --status-bar=#{status_bar_image_path_escaped} --output=#{output_image_name}"
          expect(last_command_started).to have_output output_error_input_image_invalid_height
          expect(last_command_started).not_to have_exit_status(0)
        end
        
        it 'returns an error if input image width does not match the status bar image width' do
          run "csb --input=#{input_invalid_width_image_path_escaped} --status-bar=#{status_bar_image_path_escaped} --output=#{output_image_name}"
          expect(last_command_started).to have_output output_error_input_image_invalid_width
          expect(last_command_started).not_to have_exit_status(0)
        end
        
        context 'given an ouput name and having all images as valid' do
          let(:run_csb_successful_command) {
            run "csb --input=#{input_image_path_escaped} --status-bar=#{status_bar_image_path_escaped} --output=#{output_image_name}"
            stop_all_commands
          }
          
          it 'returns no error and 0 as status code' do
            run_csb_successful_command
            expect(last_command_started).to have_exit_status(0)
          end
          
          it 'creates an output image file, which exists' do
            run_csb_successful_command
            expect(output_image_name).to be_an_existing_file
          end
          
          it 'created output image must have dimensions, matching input image' do
            run_csb_successful_command
            output_image_path = expand_path(output_image_name)
            src_size = FastImage.size(input_image_path)
            out_size = FastImage.size(output_image_path)
            expect(out_size.first).to be_equal(src_size.first)
            expect(out_size.last).to be_equal(src_size.last)
          end
        end
        
      end
      
    end
    
  end
  
end