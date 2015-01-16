class CsvMailer < ActionMailer::Base
  default from: "webtool.thecowgoesmu@gmail.com"
  
  def csv_email(file_name, to_email)
	@file_name = file_name
	
	attachments["#{file_name}.csv"] = File.read("/home/syed-dev/google_invoice_tool/web/public/#{file_name}.csv")
	
	mail(to: to_email, subject: "CSV for #{file_name}.pdf")
  end
end
