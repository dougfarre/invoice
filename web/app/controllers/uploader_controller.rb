class UploaderController < ApplicationController
	def index
		#simply render index view
	end

	def upload
		uploaded_io = params[:pdf_file]
		
		if uploaded_io.nil?
			flash[:error] = "Please upload a PDF file."
			redirect_to "/uploader" and return
		end
		
		path_base = "/home/syed-dev/google_invoice_tool/test/"
		file_type = params[:file_type]
		up_file_name = "#{Time.now.to_i}_#{uploaded_io.original_filename}"
		file_path = "#{path_base}#{up_file_name}"
		
		#unless uploaded_io.content_type == "application/pdf"
		#	flash[:error] = "Please upload a PDF file. Files other than PDF format are not supported."
		#	redirect_to "/uploader" and return
		#end

		File.open(file_path, 'wb') do |file|
		    file.write(uploaded_io.read)
		end
		
		@file_base_name = File.basename(up_file_name, ".pdf")
		@filtered_file_name = @file_base_name.gsub(/[^0-9A-Za-z_]/, '')
		filtered_file_path = "#{path_base}#{@filtered_file_name}.pdf"
		
		unless @file_base_name == @filtered_file_name
			FileUtils.copy(file_path, filtered_file_path)
		end
		
		
		@sent_through_email = params[:to_email].blank? ? false : params[:to_email]

		process_result = `ruby /home/syed-dev/google_invoice_tool/google_invoice_extractor.rb #{@filtered_file_name}.pdf #{file_type}`
		
		if process_result.include? "error"
			flash[:error] = "There was an error processing the file."
			redirect_to "/uploader" and return
		end
		
		unless params[:to_email].blank?
			to_email = params[:to_email]
			CsvMailer.csv_email(@filtered_file_name, to_email).deliver
		end
	end
end
