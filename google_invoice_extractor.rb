#!/usr/bin/env ruby

require 'tesseract'
require 'csv'
require 'docsplit'
require 'pdf-reader'

input_pdf_name = ARGV[0]
pdf_type = ARGV[1] || "auto"
file_base_path = '/home/syed-dev/google_invoice_tool/'

pdf_text_lines = []
csv_file_name = File.basename(input_pdf_name, ".pdf")

if pdf_type == "auto"
	reader = PDF::Reader.new(file_base_path + 'test/' + input_pdf_name)

	pdf_type = reader.pages[0].text.empty? ? "image" : "text"
end

if pdf_type == "image"

	Docsplit.extract_images(file_base_path + 'test/'+ input_pdf_name, :format => [:png], :output => file_base_path + 'images/', :density => 500)

	e = Tesseract::Engine.new {|e|
	  e.language  = :eng
	  e.blacklist = '|'
	}

	l = 0

	image_dir = file_base_path + 'images'
	images_count = Dir[File.join(image_dir, '**', '*')].count { |file| File.file?(file) }
	image_num = 0

	images_count.times {

		image_num += 1
	
		e.each_line_for(file_base_path + 'images/' + csv_file_name + '_' + image_num.to_s + '.png') do |line|
			pdf_text_lines << line.text.to_s
		end
	}



elsif pdf_type == "text"
	reader = PDF::Reader.new(file_base_path + 'test/' + input_pdf_name)

	reader.pages.each do |page|
		page_text_lines = page.text.split("\n")
		page_text_lines.each do |text_line|
		    unless text_line.empty?
				pdf_text_lines << "#{text_line.squeeze(" ").strip}\n"
			end
		end
	end
else
	#do nothing
end


CSV.open("#{file_base_path}csv/#{csv_file_name}.csv", "wb") do |csv|
	image_num = 1
	z = 0
	p = 0
	o = []
	q = []
	headers_included = 0
	amount_due_done = 0
	
	pdf_text_lines.each do |l|

		if l.include? "Description Quantity Units Amount"
			p = 1		
		else
			if l.include? "Invoice number:"
				if z == 0 and image_num == 1
					z = 1	
					r = l.split(':')
					csv << ["Invoice Number:", r[r.size - 1].strip]
				end
			end
			if l.include? "Issue date:" and p == 0
				r = l.split(':')
				csv << ["Invoice Date:", r[r.size - 1].strip]
				month = r[r.size - 1].strip.split(' ')
				csv << ["Description", "Google Ad X Bill for " + month[0]]
				
			end

			if l.include? "Bill to:" or l.include? "Subtotal:"  or l.include? "For questions about this invoice please email"
				p = 0			
			end
			
			

			#if l.include? "Amount due in" and  p == 1
			if l.include? "Amount due in" and amount_due_done == 0
				r = l.split(':')
				csv << ["Amount Due:", r[r.size - 1].strip]
				csv << []
				p = 0
				amount_due_done = 1
			end
		end			
		if p == 1
			if l.include? "Description Quantity Units Amount" and headers_included == 0
				o << l
				headers_included = 1
			else
				o << l
			end
		end
	end
	
	if image_num == 1
		csv << ["IO", "Description", "Impression", "Price"]
		image_num += 1
	end
	
	
	o.each_with_index do |k, index_outer|
		
			#csv << ["row", "of", "CSV", "data"]
		if index_outer > 0
		

			m = []
			a = []
			b = []
			k.split(' ').reverse.each do |j|
				m << j
			end
			
			m.each_with_index do |i, index|
				if (index == 0 or index == 1 or index == 2) and ( /\A[-+]?\d+\z/ === m[0].split('.')[1])
					if m.size != 3 or index == 0
						a << i
					else
						b << i
					end
				else
					if !( /\A[-+]?\d+\z/ === m[0].split('.')[1]) and index == 0
						a << i					 				
					else
						b << i
					end
				end
				
			end
			
			d = b.size - 1
			c = ''
			(b.size).times {
				c = c + b[d] + ' '
				d -= 1			
			}	
			g = []
			
			if c.include? "IO"
				g = c.split('IO', 2)
				g[1] = 'IO' + g[1]
			elsif c.include? "SW_"
				g = c.split('SW', 2)
				g[1] = 'SW' + g[1]
			else
				g << c
			end

			c = ['', '']
			
			g.each_with_index do |h, index_inner|
				if index_inner == 0
					c[0] = h.chomp(" - ")
				else
					c[1] += h
					unless index_inner == (g.size - 1)
						c[1] += ''
					end
				end
				
			end
		
			unless index_outer == 0
				if a.size > 1
					
					a << c[0]
					a << c[1].strip
					q << [a[4], a[3], a[2], a[0]]
				else
					a << c[0]
					a << c[1]		
		
					if a[1].include? "Invalid activity"			
						q << ['', a[1], '', a[0]]
					else
						unless  ( /\A[-+]?\d+\z/ === a[0].split('.')[1])
							
						
							# puts "a[non-numeric]: " + a.to_s
							unless q[q.size - 1].nil?
								if (a[2].include? "IO" or a[2].include? "SW_")
									q[q.size - 1][0] = q[q.size - 1][0] + a[2] + a[0]
									q[q.size - 1][1] = q[q.size - 1][1] + a[1]
									
								elsif (a[0].include? "IO" or a[0].include? "SW_")
									q[q.size - 1][0] = q[q.size - 1][0] + a[0]
									q[q.size - 1][1] = q[q.size - 1][1] + a[1]
								else 		
									if ( /([A-Z])\w+(_|-)[0-9]+_*[0-9]*/ == a[1])
										q[q.size - 1][0] = q[q.size - 1][0] + a[1] + a[0]
										# q[q.size - 1][1] = q[q.size - 1][1] + a[]
									end
								end

							end

						else
							q << ['', a[1], '', a[0]]	
						end
					end
				end
			end
		end
		
		
	end

	q.each do |r|
		csv << r
	end
end
dir_path = file_base_path + 'images/'
Dir.foreach(dir_path) {|f| fn = File.join(dir_path, f); File.delete(fn) if f != '.' && f != '..'}

FileUtils.copy("#{file_base_path}csv/#{csv_file_name}.csv", "#{file_base_path}web/public/#{csv_file_name}.csv")
FileUtils.remove("#{file_base_path}test/#{csv_file_name}.pdf")
FileUtils.remove("#{file_base_path}csv/#{csv_file_name}.csv")
#remove any files in public directory that are mode than 3 days old
Dir.glob("/home/syed-dev/google_invoice_tool/web/public/*.csv").select {|f| FileUtils.remove(f) if File.new(f).mtime < (Time.now - (3 * 24 * 60 * 60)) }